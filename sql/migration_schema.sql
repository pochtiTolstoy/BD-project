create schema if not exists map;

drop table if exists map.migration_unmapped_attribute cascade;
drop table if exists map.migration_person_link cascade;
drop table if exists map.migration_log cascade;

create table map.migration_log (
    log_id uuid primary key default gen_random_uuid(),
    migration_run_id uuid not null,
    source_system text not null,
    source_record_id text,
    target_person_id uuid,
    status text not null check (status in ('success', 'warning', 'error', 'skipped')),
    stage text not null,
    error_code text,
    error_message text,
    warning_messages text[],
    source_data jsonb,
    created_at timestamptz not null default now()
);

create table map.migration_person_link (
    link_id uuid primary key default gen_random_uuid(),
    migration_run_id uuid not null,
    source_system text not null,
    source_record_id text not null,
    target_person_id uuid not null references person_profile(person_id),
    created_at timestamptz not null default now(),
    unique (source_system, source_record_id)
);

create table map.migration_unmapped_attribute (
    unmapped_attribute_id uuid primary key default gen_random_uuid(),
    migration_run_id uuid not null,
    source_system text not null,
    source_record_id text not null,
    target_person_id uuid references person_profile(person_id),
    source_field_name text not null,
    source_field_value text,
    reason text not null,
    created_at timestamptz not null default now()
);

create or replace function map.map_gender_code(p_value text)
returns text
language plpgsql
immutable
as $$
declare
    v text := lower(trim(coalesce(p_value, '')));
begin
    if v in ('м', 'm', 'male', 'муж', 'мужской', 'мужчина', 'муж.') then
        return 'MALE';
    end if;

    if v in ('ж', 'f', 'female', 'женский', 'женщина') then
        return 'FEMALE';
    end if;

    return 'UNKNOWN';
end;
$$;

create or replace function map.map_account_status_code(p_value text)
returns text
language plpgsql
immutable
as $$
declare
    v text := lower(trim(coalesce(p_value, '')));
begin
    if v like '%заблок%' then
        return 'BLOCKED';
    end if;

    if v like '%удален%' or v like '%удалён%' then
        return 'DELETED';
    end if;

    return 'ACTIVE';
end;
$$;

create or replace function map.map_address_type_code(p_value text)
returns text
language plpgsql
immutable
as $$
declare
    v text := lower(trim(coalesce(p_value, '')));
begin
    if v like '%достав%' or v = 'delivery' then
        return 'DELIVERY';
    end if;

    if v in ('дом', 'home', 'адр') or v like '%регистрац%' then
        return 'HOME';
    end if;

    return 'DELIVERY';
end;
$$;

create or replace function map.map_document_type_code(p_value text)
returns text
language plpgsql
immutable
as $$
declare
    v text := lower(trim(coalesce(p_value, '')));
begin
    if v like '%вод%' then
        return 'DRIVER_LICENSE';
    end if;

    if v like '%загран%' then
        return 'FOREIGN_PASSPORT';
    end if;

    if v like '%воен%' then
        return 'MILITARY_ID';
    end if;

    return 'PASSPORT_RF';
end;
$$;

create or replace function map.map_consent_type_code(p_value text)
returns text
language plpgsql
immutable
as $$
declare
    v text := lower(trim(coalesce(p_value, '')));
begin
    if v like '%партн%' then
        return 'DATA_TRANSFER_TO_PARTNERS';
    end if;

    if v like '%маркет%' or v like '%реклам%' or v like '%реклама%' then
        return 'MARKETING_EMAIL';
    end if;

    return 'PERSONAL_DATA_PROCESSING';
end;
$$;

create or replace function map.parse_bool(p_value text)
returns boolean
language plpgsql
immutable
as $$
declare
    v text := lower(trim(coalesce(p_value, '')));
begin
    if v in ('да', '1', 'yes', 'true', '+', 'y') then
        return true;
    end if;

    if v in ('нет', '0', 'no', 'false', '-', 'n') then
        return false;
    end if;

    return null;
end;
$$;

create or replace function map.split_full_name(
    p_full_name text,
    out last_name text,
    out first_name text,
    out middle_name text
)
language plpgsql
immutable
as $$
declare
    parts text[];
begin
    parts := regexp_split_to_array(initcap(lower(trim(coalesce(p_full_name, '')))), '\s+');
    last_name := nullif(parts[1], '');
    first_name := nullif(parts[2], '');
    middle_name := nullif(array_to_string(parts[3:array_length(parts, 1)], ' '), '');

    if first_name is null then
        first_name := 'Неизвестно';
    end if;
end;
$$;

create or replace function map.email_array(p_value text)
returns jsonb
language sql
immutable
as $$
    select coalesce(
        jsonb_agg(jsonb_build_object(
            'type', 'EMAIL',
            'value', lower(trim(x)),
            'raw_value', p_value,
            'is_primary', rn = 1,
            'is_verified', false
        )),
        '[]'::jsonb
    )
    from (
        select x, row_number() over () rn
        from regexp_split_to_table(coalesce(p_value, ''), '[,;\s]+') x
        where trim(x) <> ''
    ) s
$$;

create or replace function map.phone_contacts(p_phone text, p_phone2 text)
returns jsonb
language sql
immutable
as $$
    select coalesce(
        jsonb_agg(jsonb_build_object(
            'type', 'PHONE',
            'value', regexp_replace(v, '\D', '', 'g'),
            'raw_value', v,
            'is_primary', rn = 1,
            'is_verified', false
        )),
        '[]'::jsonb
    )
    from (
        select v, row_number() over () rn
        from unnest(array[p_phone, p_phone2]) v
        where nullif(trim(coalesce(v, '')), '') is not null
    ) s
$$;

create or replace function map.city_normalized(p_city text)
returns text
language plpgsql
immutable
as $$
declare
    v text := lower(trim(coalesce(p_city, '')));
begin
    if v in ('спб', 'санкт-петербург') then
        return 'Санкт-Петербург';
    end if;

    if v in ('нвсб', 'новосибирск') then
        return 'Новосибирск';
    end if;

    if v in ('екб', 'екатеринбург') then
        return 'Екатеринбург';
    end if;

    return coalesce(nullif(initcap(v), ''), 'Не указан');
end;
$$;

create or replace function map.region_by_city(p_city text)
returns text
language plpgsql
immutable
as $$
declare
    v text := map.city_normalized(p_city);
begin
    return case v
        when 'Москва' then 'Москва'
        when 'Санкт-Петербург' then 'Санкт-Петербург'
        when 'Новосибирск' then 'Новосибирская область'
        when 'Екатеринбург' then 'Свердловская область'
        when 'Казань' then 'Татарстан'
        when 'Химки' then 'Московская область'
        when 'Ростов-На-Дону' then 'Ростовская область'
        when 'Краснодар' then 'Краснодарский край'
        else 'Не указан'
    end;
end;
$$;

create or replace function map.street_from_address(p_address text)
returns text
language plpgsql
immutable
as $$
declare
    v text := trim(coalesce(p_address, ''));
    m text[];
begin
    m := regexp_match(v, '(ул\.?|улица|пр\.?|пр-т|проспект|шоссе|пер\.?)\s*([[:alnum:]А-Яа-яЁё\-\s]+?)(,| д\.| дом| кв| к\.|$)', 'i');
    if m is not null then
        return trim(m[1] || ' ' || m[2]);
    end if;

    return coalesce(nullif(left(v, 80), ''), 'Не указана');
end;
$$;

create or replace function map.house_from_address(p_address text)
returns text
language plpgsql
immutable
as $$
declare
    m text[];
begin
    m := regexp_match(coalesce(p_address, ''), '(дом|д\.?)\s*([0-9]+[[:alnum:]А-Яа-яЁё\-/]*)', 'i');
    if m is not null then
        return m[2];
    end if;

    m := regexp_match(coalesce(p_address, ''), '\s([0-9]+[[:alnum:]А-Яа-яЁё\-/]*)');
    if m is not null then
        return m[1];
    end if;

    return null;
end;
$$;

create or replace function map.flat_from_address(p_address text)
returns text
language plpgsql
immutable
as $$
declare
    m text[];
begin
    m := regexp_match(coalesce(p_address, ''), '(кв\.?|квартира)\s*([0-9]+)', 'i');
    if m is not null then
        return m[2];
    end if;

    return null;
end;
$$;

create or replace function map.document_series(p_doc_data text)
returns text
language plpgsql
immutable
as $$
declare
    m text[];
begin
    m := regexp_match(coalesce(p_doc_data, ''), '([0-9]{2}\s?[0-9]{2}|[0-9]{4}|[A-ZА-Я]{2,4})');
    if m is not null then
        return regexp_replace(m[1], '\s+', '', 'g');
    end if;
    return null;
end;
$$;

create or replace function map.document_number(p_doc_data text)
returns text
language plpgsql
immutable
as $$
declare
    m text[];
begin
    m := regexp_match(coalesce(p_doc_data, ''), '([0-9]{6,7})');
    if m is not null then
        return m[1];
    end if;
    return null;
end;
$$;

create or replace function map.document_issue_date_raw(p_doc_data text)
returns text
language plpgsql
immutable
as $$
declare
    m text[];
begin
    m := regexp_match(coalesce(p_doc_data, ''), '([0-9]{4}-[0-9]{2}-[0-9]{2}|[0-9]{1,2}[./-][0-9]{1,2}[./-][0-9]{2,4}|[0-9]{1,2}\s+[А-Яа-яЁё]+\s+[0-9]{4})');
    if m is not null then
        return m[1];
    end if;
    return null;
end;
$$;

create or replace function map.attribute_code(p_name text, p_value text)
returns text
language plpgsql
immutable
as $$
declare
    v text := lower(trim(coalesce(p_name, '')));
begin
    if v in ('любимая_категория', 'любимая категория', 'fav_category', 'fav_cat', 'категория') then
        return 'FAVORITE_TECH_CATEGORY';
    end if;

    if v in ('preferred_brand', 'brand', 'любимый_бренд', 'бренд') then
        return 'PREFERRED_BRAND';
    end if;

    if v in ('рассрочка', 'interested_installment') then
        return 'INSTALLMENT_INTEREST';
    end if;

    if v in ('budget', 'бюджет', 'бюджет_руб', 'avg_budget_rub') then
        return 'AVG_ORDER_BUDGET';
    end if;

    if v = 'smart_home' then
        return 'HAS_SMART_HOME';
    end if;

    if v = 'ecosystem' then
        return 'DEVICE_ECOSYSTEM';
    end if;

    if lower(trim(coalesce(p_value, ''))) = 'iphone' then
        return 'PREFERRED_BRAND';
    end if;

    return null;
end;
$$;

create or replace function map.attribute_value(p_code text, p_value text)
returns jsonb
language plpgsql
immutable
as $$
declare
    v text := trim(coalesce(p_value, ''));
    n text;
begin
    if p_code in ('INSTALLMENT_INTEREST', 'HAS_SMART_HOME') then
        return to_jsonb(coalesce(map.parse_bool(v), false));
    end if;

    if p_code = 'AVG_ORDER_BUDGET' then
        n := regexp_replace(v, '\D', '', 'g');
        if n = '' then
            return 'null'::jsonb;
        end if;
        return to_jsonb(n::numeric);
    end if;

    return to_jsonb(v);
end;
$$;

create or replace function map.migrate_partner_customers(p_migration_run_id uuid default gen_random_uuid())
returns uuid
language plpgsql
as $$
declare
    r record;
    n record;
    v_person_id uuid;
    v_contacts jsonb;
    v_addresses jsonb;
    v_identifiers jsonb;
    v_documents jsonb;
    v_consents jsonb;
    v_attributes jsonb;
    v_warnings text[];
    v_email text;
    v_code text;
    v_value jsonb;
    v_attr record;
begin
    for r in select * from map.customers order by cust_id loop
        v_warnings := array[]::text[];

        begin
            select target_person_id into v_person_id
            from map.migration_person_link
            where source_system = 'partner_bd2'
              and source_record_id = r.cust_id::text
            limit 1;

            if v_person_id is not null then
                insert into map.migration_log (
                    migration_run_id,
                    source_system,
                    source_record_id,
                    target_person_id,
                    status,
                    stage,
                    source_data
                )
                values (
                    p_migration_run_id,
                    'partner_bd2',
                    r.cust_id::text,
                    v_person_id,
                    'skipped',
                    'deduplicate',
                    to_jsonb(r)
                );

                continue;
            end if;

            select * into n from map.split_full_name(r.fullname);

            if n.first_name ~ '\.' or length(n.first_name) <= 2 then
                v_warnings := array_append(v_warnings, 'ФИО содержит инициалы или неполное имя: ' || coalesce(r.fullname, ''));
            end if;

            if parse_birth_date(r.birth_dt) is null and nullif(trim(coalesce(r.birth_dt, '')), '') is not null then
                v_warnings := array_append(v_warnings, 'Дата рождения не распознана: ' || r.birth_dt);
            end if;

            v_contacts := map.email_array(r.email) || map.phone_contacts(r.phone, r.phone2);

            for v_email in select jsonb_array_elements(v_contacts) ->> 'value' loop
                if v_email like '%@%' = false and v_email !~ '^\d+$' then
                    v_warnings := array_append(v_warnings, 'Подозрительный контакт: ' || v_email);
                end if;
            end loop;

            select coalesce(jsonb_agg(jsonb_build_object(
                'type', map.map_address_type_code(a.addr_type),
                'country', 'Россия',
                'region', map.region_by_city(a.city),
                'city', map.city_normalized(a.city),
                'street', map.street_from_address(a.address),
                'house', map.house_from_address(a.address),
                'flat', map.flat_from_address(a.address),
                'postal_code', a.zip_code,
                'raw_address', a.address,
                'is_default', row_number = 1
            )), '[]'::jsonb)
            into v_addresses
            from (
                select a.*, row_number() over (order by a.addr_id) row_number
                from map.cust_addresses a
                where a.cust_id = r.cust_id
                  and nullif(trim(coalesce(a.address, '')), '') is not null
            ) a;

            if v_addresses = '[]'::jsonb then
                v_warnings := array_append(v_warnings, 'Адрес отсутствует или пустой');
            end if;

            select coalesce(jsonb_agg(x), '[]'::jsonb)
            into v_identifiers
            from (
                select jsonb_build_object('type', 'INN', 'value', r.inn, 'raw_value', r.inn, 'is_verified', false) x
                where nullif(trim(coalesce(r.inn, '')), '') is not null
                union all
                select jsonb_build_object('type', 'SNILS', 'value', r.snils, 'raw_value', r.snils, 'is_verified', false)
                where nullif(trim(coalesce(r.snils, '')), '') is not null
            ) s;

            select coalesce(jsonb_agg(jsonb_build_object(
                'type', map.map_document_type_code(d.doc_type),
                'series', map.document_series(d.doc_data),
                'number', map.document_number(d.doc_data),
                'issue_date_raw', map.document_issue_date_raw(d.doc_data),
                'issued_by', d.doc_data,
                'raw_document_text', d.doc_data,
                'verification_status', 'NOT_CHECKED'
            )), '[]'::jsonb)
            into v_documents
            from map.cust_docs d
            where d.cust_id = r.cust_id;

            select coalesce(jsonb_agg(jsonb_build_object(
                'type', map.map_consent_type_code(c.consent_for),
                'is_granted', coalesce(map.parse_bool(c.agreed), false),
                'granted_at', case when map.parse_bool(c.agreed) is true and parse_birth_date(c.dt) is not null then parse_birth_date(c.dt)::text end,
                'revoked_at', case when map.parse_bool(c.agreed) is false and parse_birth_date(c.dt) is not null then parse_birth_date(c.dt)::text end,
                'source', 'partner_source',
                'raw_value', c.consent_for || '=' || c.agreed
            )), '[]'::jsonb)
            into v_consents
            from map.cust_consents c
            where c.cust_id = r.cust_id;

            v_attributes := '{}'::jsonb;
            for v_attr in
                select
                    e.param_name,
                    e.param_val,
                    map.attribute_code(e.param_name, e.param_val) as attr_code,
                    map.attribute_value(map.attribute_code(e.param_name, e.param_val), e.param_val) as attr_value
                from map.cust_extra e
                where e.cust_id = r.cust_id
            loop
                if v_attr.attr_code is null or v_attr.attr_value = 'null'::jsonb then
                    insert into map.migration_unmapped_attribute (
                        migration_run_id,
                        source_system,
                        source_record_id,
                        source_field_name,
                        source_field_value,
                        reason
                    )
                    values (
                        p_migration_run_id,
                        'partner_bd2',
                        r.cust_id::text,
                        'cust_extra.' || coalesce(v_attr.param_name, 'UNKNOWN'),
                        v_attr.param_val,
                        'Attribute was not mapped to target business EAV'
                    );
                else
                    v_attributes := v_attributes || jsonb_build_object(v_attr.attr_code, v_attr.attr_value);
                end if;
            end loop;

            if nullif(trim(coalesce(r.marital, '')), '') is not null then
                insert into map.migration_unmapped_attribute (
                    migration_run_id,
                    source_system,
                    source_record_id,
                    source_field_name,
                    source_field_value,
                    reason
                )
                values (
                    p_migration_run_id,
                    'partner_bd2',
                    r.cust_id::text,
                    'customers.marital',
                    r.marital,
                    'Target tech marketplace customer model has no marital status field'
                );
            end if;

            v_person_id := create_marketplace_customer(
                p_last_name := n.last_name,
                p_first_name := n.first_name,
                p_middle_name := n.middle_name,
                p_login := r.login,
                p_birth_date_raw := r.birth_dt,
                p_gender_code := map.map_gender_code(r.sex),
                p_account_status_code := map.map_account_status_code(r.status),
                p_contacts := v_contacts,
                p_addresses := v_addresses,
                p_identifiers := v_identifiers,
                p_documents := v_documents,
                p_consents := v_consents,
                p_attributes := v_attributes
            );

            insert into map.migration_person_link (
                migration_run_id,
                source_system,
                source_record_id,
                target_person_id
            )
            values (
                p_migration_run_id,
                'partner_bd2',
                r.cust_id::text,
                v_person_id
            )
            on conflict (source_system, source_record_id)
            do update set target_person_id = excluded.target_person_id;

            update map.migration_unmapped_attribute
            set target_person_id = v_person_id
            where migration_run_id = p_migration_run_id
              and source_system = 'partner_bd2'
              and source_record_id = r.cust_id::text
              and target_person_id is null;

            insert into map.migration_log (
                migration_run_id,
                source_system,
                source_record_id,
                target_person_id,
                status,
                stage,
                warning_messages,
                source_data
            )
            values (
                p_migration_run_id,
                'partner_bd2',
                r.cust_id::text,
                v_person_id,
                case when cardinality(v_warnings) > 0 then 'warning' else 'success' end,
                'load',
                nullif(v_warnings, array[]::text[]),
                to_jsonb(r)
            );
        exception
            when others then
                insert into map.migration_log (
                    migration_run_id,
                    source_system,
                    source_record_id,
                    status,
                    stage,
                    error_code,
                    error_message,
                    source_data
                )
                values (
                    p_migration_run_id,
                    'partner_bd2',
                    r.cust_id::text,
                    'error',
                    'load',
                    sqlstate,
                    sqlerrm,
                    to_jsonb(r)
                );
        end;
    end loop;

    return p_migration_run_id;
end;
$$;
