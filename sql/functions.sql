create or replace function normalize_code(p_value text)
returns text
language sql
immutable
as $$
    select nullif(upper(trim(p_value)), '')
$$;

create or replace function normalize_digits(p_value text)
returns text
language sql
immutable
as $$
    select nullif(regexp_replace(coalesce(p_value, ''), '\D', '', 'g'), '')
$$;

create or replace function parse_birth_date(p_raw text)
returns date
language plpgsql
immutable
as $$
declare
    v text := lower(trim(coalesce(p_raw, '')));
    m text[];
    yy integer;
    mm integer;
begin
    if v = '' then
        return null;
    end if;

    if v ~ '^\d{4}-\d{2}-\d{2}$' then
        return v::date;
    end if;

    if v ~ '^\d{1,2}\.\d{1,2}\.\d{4}$' then
        return to_date(v, 'DD.MM.YYYY');
    end if;

    if v ~ '^\d{1,2}-\d{1,2}-\d{4}$' then
        return to_date(v, 'DD-MM-YYYY');
    end if;

    if v ~ '^\d{1,2}/\d{1,2}/\d{4}$' then
        return to_date(v, 'DD/MM/YYYY');
    end if;

    if v ~ '^\d{4}/\d{1,2}/\d{1,2}$' then
        return to_date(v, 'YYYY/MM/DD');
    end if;

    if v ~ '^\d{1,2}\.\d{1,2}\.\d{2}$' then
        m := regexp_match(v, '^(\d{1,2})\.(\d{1,2})\.(\d{2})$');
        yy := m[3]::integer;
        if yy > extract(year from current_date)::integer % 100 then
            yy := 1900 + yy;
        else
            yy := 2000 + yy;
        end if;
        return make_date(yy, m[2]::integer, m[1]::integer);
    end if;

    m := regexp_match(v, '^(\d{1,2})\s+([а-яё]+)\s+(\d{4})');
    if m is not null then
        mm := case m[2]
            when 'января' then 1
            when 'февраля' then 2
            when 'марта' then 3
            when 'апреля' then 4
            when 'мая' then 5
            when 'июня' then 6
            when 'июля' then 7
            when 'августа' then 8
            when 'сентября' then 9
            when 'октября' then 10
            when 'ноября' then 11
            when 'декабря' then 12
        end;
        if mm is not null then
            return make_date(m[3]::integer, mm, m[1]::integer);
        end if;
    end if;

    m := regexp_match(v, '^(january|february|march|april|may|june|july|august|september|october|november|december)\s+(\d{1,2}),\s*(\d{4})');
    if m is not null then
        mm := case m[1]
            when 'january' then 1
            when 'february' then 2
            when 'march' then 3
            when 'april' then 4
            when 'may' then 5
            when 'june' then 6
            when 'july' then 7
            when 'august' then 8
            when 'september' then 9
            when 'october' then 10
            when 'november' then 11
            when 'december' then 12
        end;
        return make_date(m[3]::integer, mm, m[2]::integer);
    end if;

    return null;
exception
    when others then
        return null;
end;
$$;

create or replace function get_gender_id(p_code text)
returns uuid
language sql
stable
as $$
    select gender_id
    from dict_gender
    where code = coalesce(normalize_code(p_code), 'UNKNOWN')
$$;

create or replace function get_account_status_id(p_code text)
returns uuid
language sql
stable
as $$
    select account_status_id
    from dict_account_status
    where code = coalesce(normalize_code(p_code), 'ACTIVE')
$$;

create or replace function add_customer_contact(
    p_person_id uuid,
    p_contact_type_code text,
    p_contact_value text,
    p_raw_value text default null,
    p_is_primary boolean default false,
    p_is_verified boolean default false
)
returns uuid
language plpgsql
as $$
declare
    v_contact_id uuid;
    v_contact_type_id uuid;
begin
    select contact_type_id into v_contact_type_id
    from dict_contact_type
    where code = normalize_code(p_contact_type_code);

    if v_contact_type_id is null then
        raise exception 'Unknown contact type: %', p_contact_type_code;
    end if;

    insert into user_contact (
        person_id,
        contact_type_id,
        contact_value,
        raw_value,
        is_primary,
        is_verified
    )
    values (
        p_person_id,
        v_contact_type_id,
        trim(p_contact_value),
        p_raw_value,
        coalesce(p_is_primary, false),
        coalesce(p_is_verified, false)
    )
    on conflict (person_id, contact_type_id, contact_value)
    do update set
        raw_value = coalesce(excluded.raw_value, user_contact.raw_value),
        is_primary = user_contact.is_primary or excluded.is_primary,
        is_verified = user_contact.is_verified or excluded.is_verified
    returning contact_id into v_contact_id;

    return v_contact_id;
end;
$$;

create or replace function add_customer_identifier(
    p_person_id uuid,
    p_identifier_type_code text,
    p_identifier_value text,
    p_raw_value text default null,
    p_is_verified boolean default false
)
returns uuid
language plpgsql
as $$
declare
    v_identifier_id uuid;
    v_identifier_type_id uuid;
    v_value text;
begin
    select identifier_type_id into v_identifier_type_id
    from dict_identifier_type
    where code = normalize_code(p_identifier_type_code);

    if v_identifier_type_id is null then
        raise exception 'Unknown identifier type: %', p_identifier_type_code;
    end if;

    v_value := coalesce(normalize_digits(p_identifier_value), trim(p_identifier_value));

    insert into person_identifier (
        person_id,
        identifier_type_id,
        identifier_value,
        raw_value,
        is_verified
    )
    values (
        p_person_id,
        v_identifier_type_id,
        v_value,
        p_raw_value,
        coalesce(p_is_verified, false)
    )
    on conflict (identifier_type_id, identifier_value)
    do update set
        raw_value = coalesce(excluded.raw_value, person_identifier.raw_value),
        is_verified = person_identifier.is_verified or excluded.is_verified
    returning identifier_id into v_identifier_id;

    return v_identifier_id;
end;
$$;

create or replace function add_customer_address(
    p_person_id uuid,
    p_address_type_code text,
    p_country_name text,
    p_region_name text,
    p_city_name text,
    p_street_name text,
    p_house text default null,
    p_building text default null,
    p_flat text default null,
    p_postal_code text default null,
    p_raw_address text default null,
    p_is_default boolean default false
)
returns uuid
language plpgsql
as $$
declare
    v_address_id uuid;
    v_address_type_id uuid;
    v_country_id uuid;
    v_region_id uuid;
    v_city_id uuid;
    v_street_id uuid;
begin
    select address_type_id into v_address_type_id
    from dict_address_type
    where code = normalize_code(p_address_type_code);

    if v_address_type_id is null then
        raise exception 'Unknown address type: %', p_address_type_code;
    end if;

    insert into dict_country (iso_code, name)
    values (null, trim(p_country_name))
    on conflict (name) do update set name = excluded.name
    returning country_id into v_country_id;

    insert into dict_region (country_id, name)
    values (v_country_id, trim(p_region_name))
    on conflict (country_id, name) do update set name = excluded.name
    returning region_id into v_region_id;

    insert into dict_city (region_id, name)
    values (v_region_id, trim(p_city_name))
    on conflict (region_id, name) do update set name = excluded.name
    returning city_id into v_city_id;

    insert into dict_street (city_id, name)
    values (v_city_id, trim(p_street_name))
    on conflict (city_id, name) do update set name = excluded.name
    returning street_id into v_street_id;

    insert into user_address (
        person_id,
        address_type_id,
        country_id,
        region_id,
        city_id,
        street_id,
        house,
        building,
        flat,
        postal_code,
        raw_address,
        is_default
    )
    values (
        p_person_id,
        v_address_type_id,
        v_country_id,
        v_region_id,
        v_city_id,
        v_street_id,
        p_house,
        p_building,
        p_flat,
        p_postal_code,
        p_raw_address,
        coalesce(p_is_default, false)
    )
    on conflict do nothing
    returning address_id into v_address_id;

    if v_address_id is null then
        select address_id into v_address_id
        from user_address
        where person_id = p_person_id
          and address_type_id = v_address_type_id
          and country_id is not distinct from v_country_id
          and region_id is not distinct from v_region_id
          and city_id is not distinct from v_city_id
          and street_id is not distinct from v_street_id
          and house is not distinct from p_house
          and building is not distinct from p_building
          and flat is not distinct from p_flat
          and postal_code is not distinct from p_postal_code
          and raw_address is not distinct from p_raw_address
        limit 1;

        update user_address
        set is_default = user_address.is_default or coalesce(p_is_default, false)
        where address_id = v_address_id;
    end if;

    return v_address_id;
end;
$$;

create or replace function add_customer_document(
    p_person_id uuid,
    p_document_type_code text,
    p_series text default null,
    p_number text default null,
    p_issue_date_raw text default null,
    p_issued_by text default null,
    p_raw_document_text text default null,
    p_verification_status_code text default 'NOT_CHECKED'
)
returns uuid
language plpgsql
as $$
declare
    v_document_id uuid;
    v_document_type_id uuid;
    v_verification_status_id uuid;
begin
    select document_type_id into v_document_type_id
    from dict_document_type
    where code = normalize_code(p_document_type_code);

    select verification_status_id into v_verification_status_id
    from dict_verification_status
    where code = coalesce(normalize_code(p_verification_status_code), 'NOT_CHECKED');

    if v_document_type_id is null then
        raise exception 'Unknown document type: %', p_document_type_code;
    end if;

    if v_verification_status_id is null then
        raise exception 'Unknown verification status: %', p_verification_status_code;
    end if;

    insert into user_verification_document (
        person_id,
        document_type_id,
        series,
        number,
        issue_date,
        issue_date_raw,
        issued_by,
        raw_document_text,
        verification_status_id
    )
    values (
        p_person_id,
        v_document_type_id,
        nullif(trim(p_series), ''),
        nullif(trim(p_number), ''),
        parse_birth_date(p_issue_date_raw),
        p_issue_date_raw,
        nullif(trim(p_issued_by), ''),
        p_raw_document_text,
        v_verification_status_id
    )
    on conflict do nothing
    returning document_id into v_document_id;

    if v_document_id is null then
        select document_id into v_document_id
        from user_verification_document
        where person_id = p_person_id
          and document_type_id = v_document_type_id
          and series is not distinct from nullif(trim(p_series), '')
          and number is not distinct from nullif(trim(p_number), '')
          and raw_document_text is not distinct from p_raw_document_text
        limit 1;

        update user_verification_document
        set verification_status_id = v_verification_status_id,
            issue_date = coalesce(parse_birth_date(p_issue_date_raw), user_verification_document.issue_date),
            issue_date_raw = coalesce(p_issue_date_raw, user_verification_document.issue_date_raw),
            issued_by = coalesce(nullif(trim(p_issued_by), ''), user_verification_document.issued_by)
        where document_id = v_document_id;
    end if;

    return v_document_id;
end;
$$;

create or replace function add_customer_consent(
    p_person_id uuid,
    p_consent_type_code text,
    p_is_granted boolean,
    p_granted_at timestamptz default null,
    p_revoked_at timestamptz default null,
    p_source text default null,
    p_raw_value text default null
)
returns uuid
language plpgsql
as $$
declare
    v_consent_id uuid;
    v_consent_type_id uuid;
begin
    select consent_type_id into v_consent_type_id
    from dict_consent_type
    where code = normalize_code(p_consent_type_code);

    if v_consent_type_id is null then
        raise exception 'Unknown consent type: %', p_consent_type_code;
    end if;

    insert into user_consent (
        person_id,
        consent_type_id,
        is_granted,
        granted_at,
        revoked_at,
        source,
        raw_value
    )
    values (
        p_person_id,
        v_consent_type_id,
        p_is_granted,
        p_granted_at,
        p_revoked_at,
        p_source,
        p_raw_value
    )
    on conflict (person_id, consent_type_id)
    do update set
        is_granted = excluded.is_granted,
        granted_at = excluded.granted_at,
        revoked_at = excluded.revoked_at,
        source = excluded.source,
        raw_value = excluded.raw_value
    returning consent_id into v_consent_id;

    return v_consent_id;
end;
$$;

create or replace function set_customer_attribute(
    p_person_id uuid,
    p_attribute_code text,
    p_value jsonb,
    p_raw_value text default null
)
returns uuid
language plpgsql
as $$
declare
    v_attribute_value_id uuid;
    v_attribute_type user_attribute_type%rowtype;
begin
    select * into v_attribute_type
    from user_attribute_type
    where code = normalize_code(p_attribute_code);

    if v_attribute_type.attribute_type_id is null then
        raise exception 'Unknown attribute type: %', p_attribute_code;
    end if;

    insert into user_attribute_value (
        person_id,
        attribute_type_id,
        value_text,
        value_number,
        value_date,
        value_bool,
        value_json,
        raw_value
    )
    values (
        p_person_id,
        v_attribute_type.attribute_type_id,
        case when v_attribute_type.value_type = 'text' then trim(both '"' from p_value::text) end,
        case when v_attribute_type.value_type = 'number' then (trim(both '"' from p_value::text))::numeric end,
        case when v_attribute_type.value_type = 'date' then (trim(both '"' from p_value::text))::date end,
        case when v_attribute_type.value_type = 'bool' then (trim(both '"' from p_value::text))::boolean end,
        case when v_attribute_type.value_type = 'json' then p_value end,
        p_raw_value
    )
    on conflict (person_id, attribute_type_id)
    do update set
        value_text = excluded.value_text,
        value_number = excluded.value_number,
        value_date = excluded.value_date,
        value_bool = excluded.value_bool,
        value_json = excluded.value_json,
        raw_value = excluded.raw_value
    returning attribute_value_id into v_attribute_value_id;

    return v_attribute_value_id;
end;
$$;

create or replace function find_marketplace_customer(
    p_last_name text,
    p_first_name text,
    p_middle_name text default null,
    p_birth_date_raw text default null,
    p_login text default null,
    p_contacts jsonb default '[]'::jsonb,
    p_identifiers jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
stable
as $$
declare
    v_person_id uuid;
    v_birth_date date := parse_birth_date(p_birth_date_raw);
begin
    select person_id into v_person_id
    from user_account
    where login = trim(p_login)
    limit 1;

    if v_person_id is not null then
        return v_person_id;
    end if;

    with source_identifiers as (
        select
            normalize_code(item ->> 'type') as type_code,
            coalesce(normalize_digits(item ->> 'value'), nullif(trim(item ->> 'value'), '')) as identifier_value
        from jsonb_array_elements(coalesce(p_identifiers, '[]'::jsonb)) item
        where nullif(trim(coalesce(item ->> 'value', '')), '') is not null
    )
    select pi.person_id into v_person_id
    from source_identifiers si
    join dict_identifier_type it on it.code = si.type_code
    join person_identifier pi
      on pi.identifier_type_id = it.identifier_type_id
     and pi.identifier_value = si.identifier_value
    limit 1;

    if v_person_id is not null then
        return v_person_id;
    end if;

    with source_contacts as (
        select
            normalize_code(item ->> 'type') as type_code,
            nullif(trim(item ->> 'value'), '') as contact_value,
            normalize_digits(item ->> 'value') as contact_digits
        from jsonb_array_elements(coalesce(p_contacts, '[]'::jsonb)) item
        where nullif(trim(coalesce(item ->> 'value', '')), '') is not null
    )
    select uc.person_id into v_person_id
    from source_contacts sc
    join dict_contact_type ct on ct.code = sc.type_code
    join user_contact uc on uc.contact_type_id = ct.contact_type_id
    where lower(uc.contact_value) = lower(sc.contact_value)
       or (
           sc.type_code = 'PHONE'
           and normalize_digits(uc.contact_value) = sc.contact_digits
       )
    limit 1;

    if v_person_id is not null then
        return v_person_id;
    end if;

    if v_birth_date is not null then
        select person_id into v_person_id
        from person_profile
        where lower(last_name) = lower(trim(p_last_name))
          and lower(first_name) = lower(trim(p_first_name))
          and coalesce(lower(middle_name), '') = coalesce(lower(nullif(trim(p_middle_name), '')), '')
          and birth_date = v_birth_date
        limit 1;
    end if;

    return v_person_id;
end;
$$;

create or replace function create_marketplace_customer(
    p_last_name text,
    p_first_name text,
    p_login text,
    p_middle_name text default null,
    p_birth_date_raw text default null,
    p_gender_code text default 'UNKNOWN',
    p_password_hash text default null,
    p_account_status_code text default 'ACTIVE',
    p_contacts jsonb default '[]'::jsonb,
    p_addresses jsonb default '[]'::jsonb,
    p_identifiers jsonb default '[]'::jsonb,
    p_documents jsonb default '[]'::jsonb,
    p_consents jsonb default '[]'::jsonb,
    p_attributes jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
as $$
declare
    v_person_id uuid;
    v_birth_date date;
    v_gender_id uuid;
    v_account_status_id uuid;
    v_item jsonb;
    v_key text;
    v_value jsonb;
begin
    if nullif(trim(p_last_name), '') is null
       or nullif(trim(p_first_name), '') is null then
        raise exception 'last_name and first_name are required';
    end if;

    if nullif(trim(p_login), '') is null then
        raise exception 'login is required';
    end if;

    v_gender_id := get_gender_id(p_gender_code);
    v_account_status_id := get_account_status_id(p_account_status_code);
    v_birth_date := parse_birth_date(p_birth_date_raw);

    if v_gender_id is null then
        raise exception 'Unknown gender code: %', p_gender_code;
    end if;

    if v_account_status_id is null then
        raise exception 'Unknown account status: %', p_account_status_code;
    end if;

    v_person_id := find_marketplace_customer(
        p_last_name := p_last_name,
        p_first_name := p_first_name,
        p_middle_name := p_middle_name,
        p_birth_date_raw := p_birth_date_raw,
        p_login := p_login,
        p_contacts := p_contacts,
        p_identifiers := p_identifiers
    );

    if v_person_id is null then
        insert into person_profile (
            last_name,
            first_name,
            middle_name,
            birth_date,
            birth_date_raw,
            gender_id
        )
        values (
            trim(p_last_name),
            trim(p_first_name),
            nullif(trim(p_middle_name), ''),
            v_birth_date,
            p_birth_date_raw,
            v_gender_id
        )
        on conflict (last_name, first_name, middle_name, birth_date)
        do update set
            birth_date_raw = coalesce(excluded.birth_date_raw, person_profile.birth_date_raw),
            gender_id = coalesce(excluded.gender_id, person_profile.gender_id)
        returning person_id into v_person_id;
    else
        update person_profile
        set last_name = trim(p_last_name),
            first_name = trim(p_first_name),
            middle_name = nullif(trim(p_middle_name), ''),
            birth_date = coalesce(v_birth_date, person_profile.birth_date),
            birth_date_raw = coalesce(p_birth_date_raw, person_profile.birth_date_raw),
            gender_id = coalesce(v_gender_id, person_profile.gender_id)
        where person_id = v_person_id;
    end if;

    insert into user_account (
        person_id,
        login,
        password_hash,
        account_status_id
    )
    values (
        v_person_id,
        trim(p_login),
        p_password_hash,
        v_account_status_id
    )
    on conflict (person_id)
    do update set
        login = excluded.login,
        password_hash = coalesce(excluded.password_hash, user_account.password_hash),
        account_status_id = excluded.account_status_id;

    for v_item in select * from jsonb_array_elements(coalesce(p_contacts, '[]'::jsonb)) loop
        perform add_customer_contact(
            v_person_id,
            v_item ->> 'type',
            v_item ->> 'value',
            v_item ->> 'raw_value',
            coalesce((v_item ->> 'is_primary')::boolean, false),
            coalesce((v_item ->> 'is_verified')::boolean, false)
        );
    end loop;

    for v_item in select * from jsonb_array_elements(coalesce(p_addresses, '[]'::jsonb)) loop
        perform add_customer_address(
            v_person_id,
            v_item ->> 'type',
            v_item ->> 'country',
            v_item ->> 'region',
            v_item ->> 'city',
            v_item ->> 'street',
            v_item ->> 'house',
            v_item ->> 'building',
            v_item ->> 'flat',
            v_item ->> 'postal_code',
            v_item ->> 'raw_address',
            coalesce((v_item ->> 'is_default')::boolean, false)
        );
    end loop;

    for v_item in select * from jsonb_array_elements(coalesce(p_identifiers, '[]'::jsonb)) loop
        perform add_customer_identifier(
            v_person_id,
            v_item ->> 'type',
            v_item ->> 'value',
            v_item ->> 'raw_value',
            coalesce((v_item ->> 'is_verified')::boolean, false)
        );
    end loop;

    for v_item in select * from jsonb_array_elements(coalesce(p_documents, '[]'::jsonb)) loop
        perform add_customer_document(
            v_person_id,
            v_item ->> 'type',
            v_item ->> 'series',
            v_item ->> 'number',
            v_item ->> 'issue_date_raw',
            v_item ->> 'issued_by',
            v_item ->> 'raw_document_text',
            coalesce(v_item ->> 'verification_status', 'NOT_CHECKED')
        );
    end loop;

    for v_item in select * from jsonb_array_elements(coalesce(p_consents, '[]'::jsonb)) loop
        perform add_customer_consent(
            v_person_id,
            v_item ->> 'type',
            (v_item ->> 'is_granted')::boolean,
            nullif(v_item ->> 'granted_at', '')::timestamptz,
            nullif(v_item ->> 'revoked_at', '')::timestamptz,
            v_item ->> 'source',
            v_item ->> 'raw_value'
        );
    end loop;

    for v_key, v_value in select key, value from jsonb_each(coalesce(p_attributes, '{}'::jsonb)) loop
        perform set_customer_attribute(v_person_id, v_key, v_value, v_value::text);
    end loop;

    return v_person_id;
end;
$$;
