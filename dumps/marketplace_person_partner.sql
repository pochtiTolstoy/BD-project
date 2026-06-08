--
-- PostgreSQL database dump
--

\restrict h3GICmJvipwU0wwgPhdG2918b6KZH6Pfg2paRV5g7nkDNlst7EjafX0qhTr5mPL

-- Dumped from database version 18.3 (Ubuntu 18.3-1.pgdg24.04+1)
-- Dumped by pg_dump version 18.3 (Ubuntu 18.3-1.pgdg24.04+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE IF EXISTS marketplace_person;
--
-- Name: marketplace_person; Type: DATABASE; Schema: -; Owner: -
--

CREATE DATABASE marketplace_person WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'C.UTF-8';


\unrestrict h3GICmJvipwU0wwgPhdG2918b6KZH6Pfg2paRV5g7nkDNlst7EjafX0qhTr5mPL
\connect marketplace_person
\restrict h3GICmJvipwU0wwgPhdG2918b6KZH6Pfg2paRV5g7nkDNlst7EjafX0qhTr5mPL

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: add_customer_address(uuid, text, text, text, text, text, text, text, text, text, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.add_customer_address(p_person_id uuid, p_address_type_code text, p_country_name text, p_region_name text, p_city_name text, p_street_name text, p_house text DEFAULT NULL::text, p_building text DEFAULT NULL::text, p_flat text DEFAULT NULL::text, p_postal_code text DEFAULT NULL::text, p_raw_address text DEFAULT NULL::text, p_is_default boolean DEFAULT false) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
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


--
-- Name: add_customer_consent(uuid, text, boolean, timestamp with time zone, timestamp with time zone, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.add_customer_consent(p_person_id uuid, p_consent_type_code text, p_is_granted boolean, p_granted_at timestamp with time zone DEFAULT NULL::timestamp with time zone, p_revoked_at timestamp with time zone DEFAULT NULL::timestamp with time zone, p_source text DEFAULT NULL::text, p_raw_value text DEFAULT NULL::text) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
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


--
-- Name: add_customer_contact(uuid, text, text, text, boolean, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.add_customer_contact(p_person_id uuid, p_contact_type_code text, p_contact_value text, p_raw_value text DEFAULT NULL::text, p_is_primary boolean DEFAULT false, p_is_verified boolean DEFAULT false) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
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


--
-- Name: add_customer_document(uuid, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.add_customer_document(p_person_id uuid, p_document_type_code text, p_series text DEFAULT NULL::text, p_number text DEFAULT NULL::text, p_issue_date_raw text DEFAULT NULL::text, p_issued_by text DEFAULT NULL::text, p_raw_document_text text DEFAULT NULL::text, p_verification_status_code text DEFAULT 'NOT_CHECKED'::text) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
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


--
-- Name: add_customer_identifier(uuid, text, text, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.add_customer_identifier(p_person_id uuid, p_identifier_type_code text, p_identifier_value text, p_raw_value text DEFAULT NULL::text, p_is_verified boolean DEFAULT false) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
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


--
-- Name: create_marketplace_customer(text, text, text, text, text, text, text, text, jsonb, jsonb, jsonb, jsonb, jsonb, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_marketplace_customer(p_last_name text, p_first_name text, p_login text, p_middle_name text DEFAULT NULL::text, p_birth_date_raw text DEFAULT NULL::text, p_gender_code text DEFAULT 'UNKNOWN'::text, p_password_hash text DEFAULT NULL::text, p_account_status_code text DEFAULT 'ACTIVE'::text, p_contacts jsonb DEFAULT '[]'::jsonb, p_addresses jsonb DEFAULT '[]'::jsonb, p_identifiers jsonb DEFAULT '[]'::jsonb, p_documents jsonb DEFAULT '[]'::jsonb, p_consents jsonb DEFAULT '[]'::jsonb, p_attributes jsonb DEFAULT '{}'::jsonb) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
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


--
-- Name: find_marketplace_customer(text, text, text, text, text, jsonb, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.find_marketplace_customer(p_last_name text, p_first_name text, p_middle_name text DEFAULT NULL::text, p_birth_date_raw text DEFAULT NULL::text, p_login text DEFAULT NULL::text, p_contacts jsonb DEFAULT '[]'::jsonb, p_identifiers jsonb DEFAULT '[]'::jsonb) RETURNS uuid
    LANGUAGE plpgsql STABLE
    AS $$
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


--
-- Name: get_account_status_id(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_account_status_id(p_code text) RETURNS uuid
    LANGUAGE sql STABLE
    AS $$
    select account_status_id
    from dict_account_status
    where code = coalesce(normalize_code(p_code), 'ACTIVE')
$$;


--
-- Name: get_gender_id(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_gender_id(p_code text) RETURNS uuid
    LANGUAGE sql STABLE
    AS $$
    select gender_id
    from dict_gender
    where code = coalesce(normalize_code(p_code), 'UNKNOWN')
$$;


--
-- Name: normalize_code(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.normalize_code(p_value text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
    select nullif(upper(trim(p_value)), '')
$$;


--
-- Name: normalize_digits(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.normalize_digits(p_value text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
    select nullif(regexp_replace(coalesce(p_value, ''), '\D', '', 'g'), '')
$$;


--
-- Name: parse_birth_date(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.parse_birth_date(p_raw text) RETURNS date
    LANGUAGE plpgsql IMMUTABLE
    AS $_$
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
$_$;


--
-- Name: set_customer_attribute(uuid, text, jsonb, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_customer_attribute(p_person_id uuid, p_attribute_code text, p_value jsonb, p_raw_value text DEFAULT NULL::text) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
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


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: dict_account_status; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dict_account_status (
    account_status_id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL
);


--
-- Name: dict_address_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dict_address_type (
    address_type_id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL
);


--
-- Name: dict_city; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dict_city (
    city_id uuid DEFAULT gen_random_uuid() NOT NULL,
    region_id uuid NOT NULL,
    name text NOT NULL
);


--
-- Name: dict_consent_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dict_consent_type (
    consent_type_id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    description text
);


--
-- Name: dict_contact_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dict_contact_type (
    contact_type_id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL
);


--
-- Name: dict_country; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dict_country (
    country_id uuid DEFAULT gen_random_uuid() NOT NULL,
    iso_code text,
    name text NOT NULL
);


--
-- Name: dict_document_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dict_document_type (
    document_type_id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL
);


--
-- Name: dict_gender; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dict_gender (
    gender_id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL
);


--
-- Name: dict_identifier_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dict_identifier_type (
    identifier_type_id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL
);


--
-- Name: dict_region; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dict_region (
    region_id uuid DEFAULT gen_random_uuid() NOT NULL,
    country_id uuid NOT NULL,
    name text NOT NULL
);


--
-- Name: dict_street; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dict_street (
    street_id uuid DEFAULT gen_random_uuid() NOT NULL,
    city_id uuid NOT NULL,
    name text NOT NULL
);


--
-- Name: dict_verification_status; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dict_verification_status (
    verification_status_id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL
);


--
-- Name: person_identifier; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.person_identifier (
    identifier_id uuid DEFAULT gen_random_uuid() NOT NULL,
    person_id uuid NOT NULL,
    identifier_type_id uuid NOT NULL,
    identifier_value text NOT NULL,
    raw_value text,
    is_verified boolean DEFAULT false NOT NULL
);


--
-- Name: person_profile; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.person_profile (
    person_id uuid DEFAULT gen_random_uuid() NOT NULL,
    last_name text NOT NULL,
    first_name text NOT NULL,
    middle_name text,
    birth_date date,
    birth_date_raw text,
    gender_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: user_account; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_account (
    account_id uuid DEFAULT gen_random_uuid() NOT NULL,
    person_id uuid NOT NULL,
    login text NOT NULL,
    password_hash text,
    account_status_id uuid NOT NULL,
    registered_at timestamp with time zone DEFAULT now() NOT NULL,
    last_login_at timestamp with time zone
);


--
-- Name: user_address; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_address (
    address_id uuid DEFAULT gen_random_uuid() NOT NULL,
    person_id uuid NOT NULL,
    address_type_id uuid NOT NULL,
    country_id uuid,
    region_id uuid,
    city_id uuid,
    street_id uuid,
    house text,
    building text,
    flat text,
    postal_code text,
    raw_address text,
    is_default boolean DEFAULT false NOT NULL
);


--
-- Name: user_attribute_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_attribute_type (
    attribute_type_id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    value_type text NOT NULL,
    description text,
    CONSTRAINT user_attribute_type_value_type_check CHECK ((value_type = ANY (ARRAY['text'::text, 'number'::text, 'date'::text, 'bool'::text, 'json'::text])))
);


--
-- Name: user_attribute_value; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_attribute_value (
    attribute_value_id uuid DEFAULT gen_random_uuid() NOT NULL,
    person_id uuid NOT NULL,
    attribute_type_id uuid NOT NULL,
    value_text text,
    value_number numeric,
    value_date date,
    value_bool boolean,
    value_json jsonb,
    raw_value text
);


--
-- Name: user_consent; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_consent (
    consent_id uuid DEFAULT gen_random_uuid() NOT NULL,
    person_id uuid NOT NULL,
    consent_type_id uuid NOT NULL,
    is_granted boolean NOT NULL,
    granted_at timestamp with time zone,
    revoked_at timestamp with time zone,
    source text,
    raw_value text
);


--
-- Name: user_contact; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_contact (
    contact_id uuid DEFAULT gen_random_uuid() NOT NULL,
    person_id uuid NOT NULL,
    contact_type_id uuid NOT NULL,
    contact_value text NOT NULL,
    raw_value text,
    is_primary boolean DEFAULT false NOT NULL,
    is_verified boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: user_verification_document; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_verification_document (
    document_id uuid DEFAULT gen_random_uuid() NOT NULL,
    person_id uuid NOT NULL,
    document_type_id uuid NOT NULL,
    series text,
    number text,
    issue_date date,
    issue_date_raw text,
    issued_by text,
    raw_document_text text,
    verification_status_id uuid NOT NULL
);


--
-- Data for Name: dict_account_status; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.dict_account_status (account_status_id, code, name) FROM stdin;
f37a570e-9e96-42f2-b363-bcb3450e8e7d	ACTIVE	Активен
7372f8bf-d776-415c-9ed8-e7df6a2c26cd	BLOCKED	Заблокирован
e0672b92-fd72-4612-ae49-874fa4e86e5a	DELETED	Удален
ae855994-f232-46a8-a257-84fe63e10c1c	PENDING	Ожидает подтверждения
\.


--
-- Data for Name: dict_address_type; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.dict_address_type (address_type_id, code, name) FROM stdin;
d2855506-330b-4aad-91d4-b4463ccce58d	DELIVERY	Адрес доставки
66afbd3d-3e14-4a96-bd10-83ad57bf3fba	HOME	Домашний адрес
1d4f3102-974d-4f6d-bd24-b4dc0bfbf6f0	PICKUP	Пункт выдачи
\.


--
-- Data for Name: dict_city; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.dict_city (city_id, region_id, name) FROM stdin;
2c420809-ff60-48ae-9c57-e8210e3a7ba0	897ddad2-a19c-46fc-9384-cacbaad5c62f	Подольск
1eaaed11-fe57-4776-88cb-1357a08fa1be	e986956b-c28d-4551-85b0-af3341e9d804	Казань
c2ef1618-e7ce-41f7-877c-df698f600cd7	e0b522f3-0009-432a-8d34-e2fdf5c62d35	Новосибирск
fa7b3a98-b85f-4a64-892e-5d031f05fb3f	c44371f7-5ee1-4340-800b-0ca1310e6635	Екатеринбург
f432c831-840d-400c-b6ba-4b7d02a87a8e	897ddad2-a19c-46fc-9384-cacbaad5c62f	Химки
10edfe31-3e6c-4413-b2b9-5b8b32772c41	d9de9819-e64a-49f4-806f-4b6c6c6b3eb4	Краснодар
1c2228b2-f6fc-4265-b129-0c4c04dd3c9f	6022e89a-393d-4417-a78f-b3e27c694dc1	Ростов-На-Дону
02722a06-c5b9-4ef0-97dc-ba8cc1ae5eb7	7a7b93d9-6f7a-4627-9806-0904881049b3	Санкт-Петербург
26596967-1869-455a-9b09-51ac5068245e	e99a12cc-6478-4692-9836-829dcd43eb0a	Москва
\.


--
-- Data for Name: dict_consent_type; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.dict_consent_type (consent_type_id, code, name, description) FROM stdin;
47eeac3f-6c9c-4055-8fb2-76d1f182225b	PERSONAL_DATA_PROCESSING	Обработка персональных данных	Согласие на хранение и обработку персональных данных покупателя
ecfba232-e2a2-4d3c-8444-7e62378143b0	MARKETING_EMAIL	Email-рассылка	Согласие на рекламные письма
4f6e6b7e-4a0d-4e99-afa8-4d1f4287c8fa	MARKETING_SMS	SMS-рассылка	Согласие на рекламные SMS
d380a6ef-ae45-43b3-81aa-a51c480615d8	DATA_TRANSFER_TO_PARTNERS	Передача данных партнерам	Согласие на передачу данных службам доставки и партнерам
\.


--
-- Data for Name: dict_contact_type; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.dict_contact_type (contact_type_id, code, name) FROM stdin;
f6b14271-a876-4443-b924-20a6f2fe3b5b	EMAIL	Email
c642e2ad-b8af-4220-bdcd-fd3bd5940af2	PHONE	Телефон
5bbc8e48-2850-4f59-ae6b-5495c9a4fd03	TELEGRAM	Telegram
e77e0bdc-f4b9-4dd8-b6b8-384584c2c4c4	WHATSAPP	WhatsApp
\.


--
-- Data for Name: dict_country; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.dict_country (country_id, iso_code, name) FROM stdin;
598080cf-c8b9-4a59-93f9-fb7707efde59	\N	Россия
\.


--
-- Data for Name: dict_document_type; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.dict_document_type (document_type_id, code, name) FROM stdin;
e1076ae9-c58c-4747-abc4-04d5db1be6ff	PASSPORT_RF	Паспорт РФ
6d30335b-310a-4773-9334-c2998be8fdd5	DRIVER_LICENSE	Водительское удостоверение
10a2c426-fffa-48cb-ae42-21f6ff3182c2	MILITARY_ID	Военный билет
d9b3085d-11cc-4939-a0f9-a93adb6624d3	FOREIGN_PASSPORT	Заграничный паспорт
\.


--
-- Data for Name: dict_gender; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.dict_gender (gender_id, code, name) FROM stdin;
a109ab39-5ecb-4ff7-842b-95e406b00b27	MALE	Мужской
5fe2d248-f344-4f70-bd8b-dc96fd74f016	FEMALE	Женский
5918892b-1285-4fb9-9521-3bf4ba35c17d	UNKNOWN	Не указан
\.


--
-- Data for Name: dict_identifier_type; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.dict_identifier_type (identifier_type_id, code, name) FROM stdin;
ae347dcb-11fc-4366-a9d9-e050777819a3	INN	ИНН
2074a7f8-9f43-465a-a412-5f8111acfc9b	SNILS	СНИЛС
5a157729-5f5d-48f3-8465-326dc1b4d48c	LOYALTY_CARD	Карта лояльности
\.


--
-- Data for Name: dict_region; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.dict_region (region_id, country_id, name) FROM stdin;
e986956b-c28d-4551-85b0-af3341e9d804	598080cf-c8b9-4a59-93f9-fb7707efde59	Татарстан
e0b522f3-0009-432a-8d34-e2fdf5c62d35	598080cf-c8b9-4a59-93f9-fb7707efde59	Новосибирская область
c44371f7-5ee1-4340-800b-0ca1310e6635	598080cf-c8b9-4a59-93f9-fb7707efde59	Свердловская область
897ddad2-a19c-46fc-9384-cacbaad5c62f	598080cf-c8b9-4a59-93f9-fb7707efde59	Московская область
d9de9819-e64a-49f4-806f-4b6c6c6b3eb4	598080cf-c8b9-4a59-93f9-fb7707efde59	Краснодарский край
6022e89a-393d-4417-a78f-b3e27c694dc1	598080cf-c8b9-4a59-93f9-fb7707efde59	Ростовская область
7a7b93d9-6f7a-4627-9806-0904881049b3	598080cf-c8b9-4a59-93f9-fb7707efde59	Санкт-Петербург
e99a12cc-6478-4692-9836-829dcd43eb0a	598080cf-c8b9-4a59-93f9-fb7707efde59	Москва
\.


--
-- Data for Name: dict_street; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.dict_street (street_id, city_id, name) FROM stdin;
9f069d6e-4d47-40b4-9a2a-aa726cf2cb45	f432c831-840d-400c-b6ba-4b7d02a87a8e	Молодежная
12b119de-4910-40d0-9b95-3b55e23522b5	1eaaed11-fe57-4776-88cb-1357a08fa1be	Баумана
39fb4039-0e8f-42ac-b201-bf184e12b550	c2ef1618-e7ce-41f7-877c-df698f600cd7	Красный проспект
ef5dc2de-2744-45f8-98ae-f8cbc4d2f786	26596967-1869-455a-9b09-51ac5068245e	Арбат
c1c47d15-8075-4967-825d-08257c945b25	2c420809-ff60-48ae-9c57-e8210e3a7ba0	Садовая
0b5862b4-31ce-4637-b5cf-886ab336271f	02722a06-c5b9-4ef0-97dc-ba8cc1ae5eb7	Литейный проспект
ca38b426-ae57-47b4-8f57-59c80555ad40	1eaaed11-fe57-4776-88cb-1357a08fa1be	Кремлевская
16d83789-60c0-48e8-8040-2212a2684866	c2ef1618-e7ce-41f7-877c-df698f600cd7	Карла Маркса
873da314-24c4-4444-ada4-0a26117ef143	26596967-1869-455a-9b09-51ac5068245e	Профсоюзная
0a81a6ce-24c9-4465-9a6b-5d8cf76deed1	10edfe31-3e6c-4413-b2b9-5b8b32772c41	Красная
75c611fc-e609-412d-b220-436687f4702a	1c2228b2-f6fc-4265-b129-0c4c04dd3c9f	Большая Садовая
a8dfa922-cc3e-459a-9834-e6c1ffe31ff4	fa7b3a98-b85f-4a64-892e-5d031f05fb3f	Малышева
40b3b21d-8437-4bb0-aadc-8694df12b6fd	02722a06-c5b9-4ef0-97dc-ba8cc1ae5eb7	Невский проспект
6dbad109-aa50-4a98-b544-bd5c531da219	f432c831-840d-400c-b6ba-4b7d02a87a8e	Юбилейный проспект
d53fe71d-ee24-4c0a-a3eb-ecd1b25761e9	26596967-1869-455a-9b09-51ac5068245e	Лесной пер.
4d97deef-4a37-4202-862c-21451d9bff2c	02722a06-c5b9-4ef0-97dc-ba8cc1ae5eb7	Маршала Жукова
aea6275f-eaaf-433e-945a-fa7d7c6d8d62	26596967-1869-455a-9b09-51ac5068245e	Коньково
ed208cf0-affc-4f56-abdb-218ef76571ad	26596967-1869-455a-9b09-51ac5068245e	4-й Лесной пер.
9ccd1d52-bdb0-44c8-a527-e7a727865060	10edfe31-3e6c-4413-b2b9-5b8b32772c41	Северная
0ef656a1-1993-4dcc-8aa5-9edee167b0c9	1c2228b2-f6fc-4265-b129-0c4c04dd3c9f	Ленина
a194a7c8-2bab-43fd-af56-34a7bd055e8a	02722a06-c5b9-4ef0-97dc-ba8cc1ae5eb7	Кронверкский пр-т
fae9a46d-15f6-40dc-9f55-f1457b91e7bd	26596967-1869-455a-9b09-51ac5068245e	Тверская
\.


--
-- Data for Name: dict_verification_status; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.dict_verification_status (verification_status_id, code, name) FROM stdin;
7e64b7b1-888e-4784-bb82-4c967d38a974	NOT_CHECKED	Не проверен
99230a4b-b83c-4e04-8e5c-d105c57c8e96	PENDING	На проверке
29365f47-4486-4f29-a71f-155dfec65fda	VERIFIED	Проверен
a3a23832-503b-410d-b105-adebbeb8cb73	REJECTED	Отклонен
\.


--
-- Data for Name: person_identifier; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.person_identifier (identifier_id, person_id, identifier_type_id, identifier_value, raw_value, is_verified) FROM stdin;
762ff715-777e-4f91-bff6-1331d0686f5f	5aa70819-ca66-4c8a-a9b4-1fbac516f7df	ae347dcb-11fc-4366-a9d9-e050777819a3	770123456789	ИНН: 7701-234567-89	f
7d165641-3737-4075-969e-60d9c7079f75	5aa70819-ca66-4c8a-a9b4-1fbac516f7df	2074a7f8-9f43-465a-a412-5f8111acfc9b	12345678900	123-456-789 00	f
818aa4e6-5294-44b8-a1a9-273e01367f20	855bc0e4-82c8-41f6-a813-b7e6ee7e8a23	5a157729-5f5d-48f3-8465-326dc1b4d48c	00077	карта TECH-00077	t
87c2a6d2-f94d-442d-b232-6abfea4b3bde	fc365817-43bb-468f-94f8-2cde7e25e36b	5a157729-5f5d-48f3-8465-326dc1b4d48c	00001	карта TECH-00001	t
b898f6b8-346e-4c9a-b7df-26d32bf663a9	25853afc-6029-4c0c-a13f-e4738b2dcce4	5a157729-5f5d-48f3-8465-326dc1b4d48c	00002	карта TECH-00002	t
723c057c-f0fe-44e2-9fdd-ac54e249a8f5	fbeb1c48-3620-4ecf-b8a1-bf4a27cf16b4	5a157729-5f5d-48f3-8465-326dc1b4d48c	00003	карта TECH-00003	t
4e037767-856d-43a2-bf95-35b8d67478b4	1afd6722-3382-425e-9ac4-d9bc81faa2ef	5a157729-5f5d-48f3-8465-326dc1b4d48c	00004	карта TECH-00004	t
51c93c73-c70b-4038-a510-e46d087ae040	d6ddb3d0-1f03-49b1-a1a1-c78918b6a273	5a157729-5f5d-48f3-8465-326dc1b4d48c	00005	карта TECH-00005	t
825472a8-ecd3-4c55-aaf6-f8b0aefd9e8a	2fcab39c-aee5-48a2-8c43-0e3289dbd4ed	5a157729-5f5d-48f3-8465-326dc1b4d48c	00006	карта TECH-00006	t
0a7df081-bd37-4571-9fa4-0df65bbd052a	fbe544b5-469e-424d-bbb1-9b2fd820694a	5a157729-5f5d-48f3-8465-326dc1b4d48c	00007	карта TECH-00007	t
6fbddd52-5b46-4d98-b12b-3ac0eacbad1d	acd35a49-f817-4252-88f4-611194a195f1	5a157729-5f5d-48f3-8465-326dc1b4d48c	00008	карта TECH-00008	t
35adb2af-2bca-443d-bc41-100407fcb251	48e18473-6d22-42fa-8df8-042be293eaab	5a157729-5f5d-48f3-8465-326dc1b4d48c	00009	карта TECH-00009	t
67d13f52-d645-4075-9915-2d89a9407588	3a132bab-0588-4f51-b527-4491f0e007eb	5a157729-5f5d-48f3-8465-326dc1b4d48c	00010	карта TECH-00010	t
69ee4874-95ff-491c-910b-ce788db9c030	e339c5c8-853e-4e80-a8bd-065bb83c7285	5a157729-5f5d-48f3-8465-326dc1b4d48c	00011	карта TECH-00011	t
091ffcce-cca5-4948-b740-56c72edcc9f6	6888527f-634d-496f-b96b-444793bca565	5a157729-5f5d-48f3-8465-326dc1b4d48c	00012	карта TECH-00012	t
2bd18b97-9deb-4132-8d94-e0d2deea9fb7	5dfc38a2-3795-49df-aef6-32027b71786a	5a157729-5f5d-48f3-8465-326dc1b4d48c	00013	карта TECH-00013	t
33e1f1e3-f044-4ec6-9aa2-c4efa3436800	8dd81453-964f-4b8b-8249-d7ef8b9d1a0f	5a157729-5f5d-48f3-8465-326dc1b4d48c	00014	карта TECH-00014	t
6528c04b-a5a2-41e4-b5c5-8e948f40609a	c4e8c4b9-3232-445f-8631-0783f78362c4	5a157729-5f5d-48f3-8465-326dc1b4d48c	00015	карта TECH-00015	t
00f62761-1302-4367-bba8-ba65eadc6060	128537da-acbe-48cb-8c24-059585840c3a	5a157729-5f5d-48f3-8465-326dc1b4d48c	00016	карта TECH-00016	t
232d5e68-02e9-4419-acd9-ef5d47ce6a8e	654b993d-15aa-4818-b3b0-546b617fccaf	5a157729-5f5d-48f3-8465-326dc1b4d48c	00017	карта TECH-00017	t
1a999114-8676-4cb0-9f48-8636119724c2	8a966ced-9c88-4e2b-a33d-3ae11f90d634	5a157729-5f5d-48f3-8465-326dc1b4d48c	00018	карта TECH-00018	t
96acecde-69a7-48aa-b55c-b74670f99896	4b933d43-d401-47ad-aba2-fdfb2a2a9a19	5a157729-5f5d-48f3-8465-326dc1b4d48c	00019	карта TECH-00019	t
da0594ec-75f5-45e2-8b9c-f287aa0badd8	2ec9874b-8451-410b-9c20-d32657874d3e	5a157729-5f5d-48f3-8465-326dc1b4d48c	00020	карта TECH-00020	t
\.


--
-- Data for Name: person_profile; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.person_profile (person_id, last_name, first_name, middle_name, birth_date, birth_date_raw, gender_id, created_at) FROM stdin;
5aa70819-ca66-4c8a-a9b4-1fbac516f7df	Иванов	Иван	Иванович	1990-01-05	5 января 1990 года	a109ab39-5ecb-4ff7-842b-95e406b00b27	2026-06-07 18:43:54.252358+03
63bc9c20-2072-4f09-91a7-9b9397a30a7e	Петрова	Мария	\N	1990-05-01	01.05.90	5fe2d248-f344-4f70-bd8b-dc96fd74f016	2026-06-07 18:43:54.269461+03
855bc0e4-82c8-41f6-a813-b7e6ee7e8a23	Сидоров	Алексей	Павлович	1995-12-03	1995-12-03	a109ab39-5ecb-4ff7-842b-95e406b00b27	2026-06-07 18:43:54.273895+03
b799f78d-4fe9-4b37-b960-403b8a99c75b	Кузнецова	Елена	\N	\N	31/02/1988	5fe2d248-f344-4f70-bd8b-dc96fd74f016	2026-06-07 18:43:54.280817+03
550848a3-6fe6-4a35-8423-a6d2319c6310	Орлов	Денис	\N	\N	\N	5918892b-1285-4fb9-9521-3bf4ba35c17d	2026-06-07 18:43:54.284421+03
fc365817-43bb-468f-94f8-2cde7e25e36b	Смирнов	Павел	Олегович	1989-04-12	1989/04/12	a109ab39-5ecb-4ff7-842b-95e406b00b27	2026-06-07 18:43:54.287426+03
25853afc-6029-4c0c-a13f-e4738b2dcce4	Васильева	Ольга	Игоревна	1991-09-12	12.09.1991	5fe2d248-f344-4f70-bd8b-dc96fd74f016	2026-06-07 18:43:54.287426+03
fbeb1c48-3620-4ecf-b8a1-bf4a27cf16b4	Никитин	Роман	\N	1984-11-07	7 ноября 1984 года	a109ab39-5ecb-4ff7-842b-95e406b00b27	2026-06-07 18:43:54.287426+03
1afd6722-3382-425e-9ac4-d9bc81faa2ef	Медведева	Ирина	Сергеевна	2003-03-03	03.03.03	5fe2d248-f344-4f70-bd8b-dc96fd74f016	2026-06-07 18:43:54.287426+03
d6ddb3d0-1f03-49b1-a1a1-c78918b6a273	Алексеев	Григорий	Андреевич	1978-10-30	1978-10-30	a109ab39-5ecb-4ff7-842b-95e406b00b27	2026-06-07 18:43:54.287426+03
2fcab39c-aee5-48a2-8c43-0e3289dbd4ed	Романова	Дарья	\N	\N	н/д	5fe2d248-f344-4f70-bd8b-dc96fd74f016	2026-06-07 18:43:54.287426+03
fbe544b5-469e-424d-bbb1-9b2fd820694a	Гаврилов	Максим	Петрович	1982-02-14	14-02-1982	a109ab39-5ecb-4ff7-842b-95e406b00b27	2026-06-07 18:43:54.287426+03
acd35a49-f817-4252-88f4-611194a195f1	Егорова	Виктория	Алексеевна	1994-06-30	1994-06-30	5fe2d248-f344-4f70-bd8b-dc96fd74f016	2026-06-07 18:43:54.287426+03
48e18473-6d22-42fa-8df8-042be293eaab	Павлов	Степан	Денисович	1991-03-05	March 5, 1991	a109ab39-5ecb-4ff7-842b-95e406b00b27	2026-06-07 18:43:54.287426+03
3a132bab-0588-4f51-b527-4491f0e007eb	Фомина	Ксения	\N	1970-12-25	25/12/1970	5fe2d248-f344-4f70-bd8b-dc96fd74f016	2026-06-07 18:43:54.287426+03
e339c5c8-853e-4e80-a8bd-065bb83c7285	Беляев	Матвей	Ильич	2000-01-01	2000-01-01	a109ab39-5ecb-4ff7-842b-95e406b00b27	2026-06-07 18:43:54.287426+03
6888527f-634d-496f-b96b-444793bca565	Соловьева	Наталья	Романовна	\N	31/02/1988	5fe2d248-f344-4f70-bd8b-dc96fd74f016	2026-06-07 18:43:54.287426+03
5dfc38a2-3795-49df-aef6-32027b71786a	Титов	Арсений	\N	1991-01-05	5 января 1991	a109ab39-5ecb-4ff7-842b-95e406b00b27	2026-06-07 18:43:54.287426+03
8dd81453-964f-4b8b-8249-d7ef8b9d1a0f	Миронова	Алина	Дмитриевна	1994-06-30	30.06.1994	5fe2d248-f344-4f70-bd8b-dc96fd74f016	2026-06-07 18:43:54.287426+03
c4e8c4b9-3232-445f-8631-0783f78362c4	Крылов	Федор	Вячеславович	1979-11-30	1979-11-30	a109ab39-5ecb-4ff7-842b-95e406b00b27	2026-06-07 18:43:54.287426+03
128537da-acbe-48cb-8c24-059585840c3a	Зуева	Марина	\N	1967-08-15	15 августа 1967 года	5fe2d248-f344-4f70-bd8b-dc96fd74f016	2026-06-07 18:43:54.287426+03
654b993d-15aa-4818-b3b0-546b617fccaf	Ковалев	Антон	Михайлович	\N	\N	a109ab39-5ecb-4ff7-842b-95e406b00b27	2026-06-07 18:43:54.287426+03
8a966ced-9c88-4e2b-a33d-3ae11f90d634	Макарова	Юлия	Олеговна	1985-03-15	1985/03/15	5fe2d248-f344-4f70-bd8b-dc96fd74f016	2026-06-07 18:43:54.287426+03
4b933d43-d401-47ad-aba2-fdfb2a2a9a19	Дорофеев	Лев	\N	\N	ноябрь 1979	a109ab39-5ecb-4ff7-842b-95e406b00b27	2026-06-07 18:43:54.287426+03
2ec9874b-8451-410b-9c20-d32657874d3e	Борисова	Светлана	Игоревна	1996-07-04	04.07.1996	5fe2d248-f344-4f70-bd8b-dc96fd74f016	2026-06-07 18:43:54.287426+03
\.


--
-- Data for Name: user_account; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_account (account_id, person_id, login, password_hash, account_status_id, registered_at, last_login_at) FROM stdin;
5f253f0e-2ee7-4651-aace-9871414c90ec	5aa70819-ca66-4c8a-a9b4-1fbac516f7df	ivanov.tech	\N	f37a570e-9e96-42f2-b363-bcb3450e8e7d	2026-06-07 18:43:54.252358+03	\N
acc65654-5766-4deb-afa4-c559a7036bf3	63bc9c20-2072-4f09-91a7-9b9397a30a7e	m.pet.rova@example.com	\N	f37a570e-9e96-42f2-b363-bcb3450e8e7d	2026-06-07 18:43:54.269461+03	\N
18c2cdf7-a65b-40b0-82a0-0fdf361c8e73	855bc0e4-82c8-41f6-a813-b7e6ee7e8a23	alexey.sid	\N	f37a570e-9e96-42f2-b363-bcb3450e8e7d	2026-06-07 18:43:54.273895+03	\N
7478b284-91a9-4110-9013-7875b7d22c0d	b799f78d-4fe9-4b37-b960-403b8a99c75b	elena_k	\N	f37a570e-9e96-42f2-b363-bcb3450e8e7d	2026-06-07 18:43:54.280817+03	\N
5506e2d5-1db2-4670-a909-6379ae762736	550848a3-6fe6-4a35-8423-a6d2319c6310	denis.orlov@example.net	\N	f37a570e-9e96-42f2-b363-bcb3450e8e7d	2026-06-07 18:43:54.284421+03	\N
c131d3bd-1e0e-4084-a044-521220896d35	fc365817-43bb-468f-94f8-2cde7e25e36b	p.smirnov.tech	\N	f37a570e-9e96-42f2-b363-bcb3450e8e7d	2026-06-07 18:43:54.287426+03	\N
59d4308d-de1b-43ef-9bee-ab26745c86cb	25853afc-6029-4c0c-a13f-e4738b2dcce4	olga.v.tech	\N	f37a570e-9e96-42f2-b363-bcb3450e8e7d	2026-06-07 18:43:54.287426+03	\N
9b263ed2-4494-4bf4-9a36-3917572b18bd	fbeb1c48-3620-4ecf-b8a1-bf4a27cf16b4	roman_nikitin	\N	f37a570e-9e96-42f2-b363-bcb3450e8e7d	2026-06-07 18:43:54.287426+03	\N
3d414e2f-85be-4aa1-8ddb-beba63e1ea44	1afd6722-3382-425e-9ac4-d9bc81faa2ef	irina.medvedeva	\N	f37a570e-9e96-42f2-b363-bcb3450e8e7d	2026-06-07 18:43:54.287426+03	\N
1718263c-92e8-4f75-86f7-8b488a67ff08	d6ddb3d0-1f03-49b1-a1a1-c78918b6a273	g.alekseev	\N	f37a570e-9e96-42f2-b363-bcb3450e8e7d	2026-06-07 18:43:54.287426+03	\N
55202874-50a8-4f3f-99fa-8b498e02c369	2fcab39c-aee5-48a2-8c43-0e3289dbd4ed	d.romanova	\N	f37a570e-9e96-42f2-b363-bcb3450e8e7d	2026-06-07 18:43:54.287426+03	\N
f83e8f2d-5410-4b51-a78f-bb75e3c4d783	fbe544b5-469e-424d-bbb1-9b2fd820694a	max.gavrilov	\N	f37a570e-9e96-42f2-b363-bcb3450e8e7d	2026-06-07 18:43:54.287426+03	\N
34b9a1b1-3837-4336-9c07-5bd0921c47b6	acd35a49-f817-4252-88f4-611194a195f1	v.egorova	\N	f37a570e-9e96-42f2-b363-bcb3450e8e7d	2026-06-07 18:43:54.287426+03	\N
8bcc2110-6332-42fd-b0af-5740e4a02b44	48e18473-6d22-42fa-8df8-042be293eaab	stepan.pavlov	\N	f37a570e-9e96-42f2-b363-bcb3450e8e7d	2026-06-07 18:43:54.287426+03	\N
9f2717d5-e511-4bb6-b2aa-836772e18333	3a132bab-0588-4f51-b527-4491f0e007eb	ks.fomina	\N	f37a570e-9e96-42f2-b363-bcb3450e8e7d	2026-06-07 18:43:54.287426+03	\N
ee7dc005-4bd6-4899-b7d7-566e7286791c	e339c5c8-853e-4e80-a8bd-065bb83c7285	matvey.belyaev	\N	f37a570e-9e96-42f2-b363-bcb3450e8e7d	2026-06-07 18:43:54.287426+03	\N
7799dfb4-756b-4a6c-aceb-b9e62b59885a	6888527f-634d-496f-b96b-444793bca565	n.solovieva	\N	f37a570e-9e96-42f2-b363-bcb3450e8e7d	2026-06-07 18:43:54.287426+03	\N
7cfaea4f-5fd0-49c2-a636-41699132a72d	5dfc38a2-3795-49df-aef6-32027b71786a	ars.titov	\N	f37a570e-9e96-42f2-b363-bcb3450e8e7d	2026-06-07 18:43:54.287426+03	\N
36d2b15e-f36f-4406-b1aa-cb2a07e91f18	8dd81453-964f-4b8b-8249-d7ef8b9d1a0f	alina.mironova	\N	f37a570e-9e96-42f2-b363-bcb3450e8e7d	2026-06-07 18:43:54.287426+03	\N
9943e674-2604-49f6-a702-4ea9176aaae2	c4e8c4b9-3232-445f-8631-0783f78362c4	fedor.krylov	\N	f37a570e-9e96-42f2-b363-bcb3450e8e7d	2026-06-07 18:43:54.287426+03	\N
7bd580bb-979d-4145-8f14-23af9ab0d24d	128537da-acbe-48cb-8c24-059585840c3a	marina.zueva	\N	f37a570e-9e96-42f2-b363-bcb3450e8e7d	2026-06-07 18:43:54.287426+03	\N
bc23897a-3d82-4628-9a33-43ce52ad40f1	654b993d-15aa-4818-b3b0-546b617fccaf	anton.kovalev	\N	f37a570e-9e96-42f2-b363-bcb3450e8e7d	2026-06-07 18:43:54.287426+03	\N
2c06aad3-914a-4f3c-a818-b244ff541e32	8a966ced-9c88-4e2b-a33d-3ae11f90d634	y.makarova	\N	f37a570e-9e96-42f2-b363-bcb3450e8e7d	2026-06-07 18:43:54.287426+03	\N
517a028e-d8dd-4c7f-bb1c-867573ce0f94	4b933d43-d401-47ad-aba2-fdfb2a2a9a19	lev.dorofeev	\N	f37a570e-9e96-42f2-b363-bcb3450e8e7d	2026-06-07 18:43:54.287426+03	\N
b131c190-b9bd-4439-b6e6-9dcde35f49a4	2ec9874b-8451-410b-9c20-d32657874d3e	s.borisova	\N	f37a570e-9e96-42f2-b363-bcb3450e8e7d	2026-06-07 18:43:54.287426+03	\N
\.


--
-- Data for Name: user_address; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_address (address_id, person_id, address_type_id, country_id, region_id, city_id, street_id, house, building, flat, postal_code, raw_address, is_default) FROM stdin;
8e54dcfb-a78a-41ba-a129-58400c338cbf	5aa70819-ca66-4c8a-a9b4-1fbac516f7df	d2855506-330b-4aad-91d4-b4463ccce58d	598080cf-c8b9-4a59-93f9-fb7707efde59	e99a12cc-6478-4692-9836-829dcd43eb0a	26596967-1869-455a-9b09-51ac5068245e	fae9a46d-15f6-40dc-9f55-f1457b91e7bd	12	\N	45	125009	Москва, Тверская 12 кв 45, домофон не работает	t
02d3117c-c278-473d-9663-60243c7a3df0	63bc9c20-2072-4f09-91a7-9b9397a30a7e	d2855506-330b-4aad-91d4-b4463ccce58d	598080cf-c8b9-4a59-93f9-fb7707efde59	897ddad2-a19c-46fc-9384-cacbaad5c62f	f432c831-840d-400c-b6ba-4b7d02a87a8e	9f069d6e-4d47-40b4-9a2a-aa726cf2cb45	7	2	101	\N	МО, г Химки, Молодежная 7к2, 101	f
910fcf2c-9b47-4e75-9646-16747c2c1877	855bc0e4-82c8-41f6-a813-b7e6ee7e8a23	d2855506-330b-4aad-91d4-b4463ccce58d	598080cf-c8b9-4a59-93f9-fb7707efde59	7a7b93d9-6f7a-4627-9806-0904881049b3	02722a06-c5b9-4ef0-97dc-ba8cc1ae5eb7	40b3b21d-8437-4bb0-aadc-8694df12b6fd	1	\N	8	\N	СПб Невский 1-8	f
6292c94b-aadf-421c-b428-c15e80f37def	b799f78d-4fe9-4b37-b960-403b8a99c75b	66afbd3d-3e14-4a96-bd10-83ad57bf3fba	598080cf-c8b9-4a59-93f9-fb7707efde59	e986956b-c28d-4551-85b0-af3341e9d804	1eaaed11-fe57-4776-88cb-1357a08fa1be	12b119de-4910-40d0-9b95-3b55e23522b5	5	\N	12	420111	Казань, Баумана 5, квартира 12	f
6d5677a1-35ba-4958-ab7f-3ad70b0c42a9	550848a3-6fe6-4a35-8423-a6d2319c6310	1d4f3102-974d-4f6d-bd24-b4dc0bfbf6f0	598080cf-c8b9-4a59-93f9-fb7707efde59	e0b522f3-0009-432a-8d34-e2fdf5c62d35	c2ef1618-e7ce-41f7-877c-df698f600cd7	39fb4039-0e8f-42ac-b201-bf184e12b550	30	\N	\N	\N	ПВЗ Новосибирск Красный 30	f
293e1a45-83d9-457a-a4c5-771e17eebf29	fc365817-43bb-468f-94f8-2cde7e25e36b	d2855506-330b-4aad-91d4-b4463ccce58d	598080cf-c8b9-4a59-93f9-fb7707efde59	e99a12cc-6478-4692-9836-829dcd43eb0a	26596967-1869-455a-9b09-51ac5068245e	ef5dc2de-2744-45f8-98ae-f8cbc4d2f786	10	\N	15	\N	Москва, Арбат 10 кв. 15	t
48a103fb-d8a5-4334-ae25-55dc15130693	25853afc-6029-4c0c-a13f-e4738b2dcce4	d2855506-330b-4aad-91d4-b4463ccce58d	598080cf-c8b9-4a59-93f9-fb7707efde59	897ddad2-a19c-46fc-9384-cacbaad5c62f	2c420809-ff60-48ae-9c57-e8210e3a7ba0	c1c47d15-8075-4967-825d-08257c945b25	5	\N	7	\N	Подольск, Садовая 5 кв. 7	t
72505ab7-d530-4930-af42-aff617acc8b3	fbeb1c48-3620-4ecf-b8a1-bf4a27cf16b4	d2855506-330b-4aad-91d4-b4463ccce58d	598080cf-c8b9-4a59-93f9-fb7707efde59	7a7b93d9-6f7a-4627-9806-0904881049b3	02722a06-c5b9-4ef0-97dc-ba8cc1ae5eb7	0b5862b4-31ce-4637-b5cf-886ab336271f	44	\N	21	\N	Санкт-Петербург, Литейный проспект 44 кв. 21	t
1e938a6f-a5fc-4a77-859e-6463ce0b8f49	1afd6722-3382-425e-9ac4-d9bc81faa2ef	d2855506-330b-4aad-91d4-b4463ccce58d	598080cf-c8b9-4a59-93f9-fb7707efde59	e986956b-c28d-4551-85b0-af3341e9d804	1eaaed11-fe57-4776-88cb-1357a08fa1be	ca38b426-ae57-47b4-8f57-59c80555ad40	2	\N	11	\N	Казань, Кремлевская 2 кв. 11	t
a2464292-1850-4d35-b779-4a06868b1122	d6ddb3d0-1f03-49b1-a1a1-c78918b6a273	d2855506-330b-4aad-91d4-b4463ccce58d	598080cf-c8b9-4a59-93f9-fb7707efde59	e0b522f3-0009-432a-8d34-e2fdf5c62d35	c2ef1618-e7ce-41f7-877c-df698f600cd7	16d83789-60c0-48e8-8040-2212a2684866	7	\N	19	\N	Новосибирск, Карла Маркса 7 кв. 19	t
6dd000b9-f995-4208-a818-23c6a808d099	2fcab39c-aee5-48a2-8c43-0e3289dbd4ed	d2855506-330b-4aad-91d4-b4463ccce58d	598080cf-c8b9-4a59-93f9-fb7707efde59	e99a12cc-6478-4692-9836-829dcd43eb0a	26596967-1869-455a-9b09-51ac5068245e	873da314-24c4-4444-ada4-0a26117ef143	88	\N	42	\N	Москва, Профсоюзная 88 кв. 42	t
889d09a6-846b-4efb-aeb5-d3822c53067f	fbe544b5-469e-424d-bbb1-9b2fd820694a	d2855506-330b-4aad-91d4-b4463ccce58d	598080cf-c8b9-4a59-93f9-fb7707efde59	d9de9819-e64a-49f4-806f-4b6c6c6b3eb4	10edfe31-3e6c-4413-b2b9-5b8b32772c41	0a81a6ce-24c9-4465-9a6b-5d8cf76deed1	135	\N	3	\N	Краснодар, Красная 135 кв. 3	t
b5a0f6ad-bb7e-4be0-8707-041974f158b9	acd35a49-f817-4252-88f4-611194a195f1	d2855506-330b-4aad-91d4-b4463ccce58d	598080cf-c8b9-4a59-93f9-fb7707efde59	6022e89a-393d-4417-a78f-b3e27c694dc1	1c2228b2-f6fc-4265-b129-0c4c04dd3c9f	75c611fc-e609-412d-b220-436687f4702a	15	\N	304	\N	Ростов-На-Дону, Большая Садовая 15 кв. 304	t
2764fa5c-c7af-4f4b-b054-e2381f939e85	48e18473-6d22-42fa-8df8-042be293eaab	d2855506-330b-4aad-91d4-b4463ccce58d	598080cf-c8b9-4a59-93f9-fb7707efde59	c44371f7-5ee1-4340-800b-0ca1310e6635	fa7b3a98-b85f-4a64-892e-5d031f05fb3f	a8dfa922-cc3e-459a-9834-e6c1ffe31ff4	51	\N	79	\N	Екатеринбург, Малышева 51 кв. 79	t
3b164aa8-2d9e-4b74-b1d8-22cef0933a08	3a132bab-0588-4f51-b527-4491f0e007eb	d2855506-330b-4aad-91d4-b4463ccce58d	598080cf-c8b9-4a59-93f9-fb7707efde59	7a7b93d9-6f7a-4627-9806-0904881049b3	02722a06-c5b9-4ef0-97dc-ba8cc1ae5eb7	40b3b21d-8437-4bb0-aadc-8694df12b6fd	100	\N	200	\N	Санкт-Петербург, Невский проспект 100 кв. 200	t
a564424d-9d9f-447d-89ff-f96ddce61443	e339c5c8-853e-4e80-a8bd-065bb83c7285	d2855506-330b-4aad-91d4-b4463ccce58d	598080cf-c8b9-4a59-93f9-fb7707efde59	e99a12cc-6478-4692-9836-829dcd43eb0a	26596967-1869-455a-9b09-51ac5068245e	fae9a46d-15f6-40dc-9f55-f1457b91e7bd	1	\N	8	\N	Москва, Тверская 1 кв. 8	t
a01145a8-d99c-43fb-836f-5a345e0f8c9f	6888527f-634d-496f-b96b-444793bca565	d2855506-330b-4aad-91d4-b4463ccce58d	598080cf-c8b9-4a59-93f9-fb7707efde59	897ddad2-a19c-46fc-9384-cacbaad5c62f	f432c831-840d-400c-b6ba-4b7d02a87a8e	6dbad109-aa50-4a98-b544-bd5c531da219	78	\N	55	\N	Химки, Юбилейный проспект 78 кв. 55	t
1b30ef61-d749-485d-b0db-2ef752e8d180	5dfc38a2-3795-49df-aef6-32027b71786a	d2855506-330b-4aad-91d4-b4463ccce58d	598080cf-c8b9-4a59-93f9-fb7707efde59	e99a12cc-6478-4692-9836-829dcd43eb0a	26596967-1869-455a-9b09-51ac5068245e	d53fe71d-ee24-4c0a-a3eb-ecd1b25761e9	4	\N	\N	\N	Москва, Лесной пер. 4	t
a8b6a2b9-7b56-4d63-bf74-2da07220f575	8dd81453-964f-4b8b-8249-d7ef8b9d1a0f	d2855506-330b-4aad-91d4-b4463ccce58d	598080cf-c8b9-4a59-93f9-fb7707efde59	7a7b93d9-6f7a-4627-9806-0904881049b3	02722a06-c5b9-4ef0-97dc-ba8cc1ae5eb7	4d97deef-4a37-4202-862c-21451d9bff2c	41	\N	22	\N	Санкт-Петербург, Маршала Жукова 41 кв. 22	t
edaf17a4-c920-4880-a797-2a7b955283f1	c4e8c4b9-3232-445f-8631-0783f78362c4	d2855506-330b-4aad-91d4-b4463ccce58d	598080cf-c8b9-4a59-93f9-fb7707efde59	e99a12cc-6478-4692-9836-829dcd43eb0a	26596967-1869-455a-9b09-51ac5068245e	aea6275f-eaaf-433e-945a-fa7d7c6d8d62	9	\N	17	\N	Москва, Коньково 9 кв. 17	t
fe17bd85-1b51-4944-a843-a0c72f54baf0	128537da-acbe-48cb-8c24-059585840c3a	d2855506-330b-4aad-91d4-b4463ccce58d	598080cf-c8b9-4a59-93f9-fb7707efde59	e99a12cc-6478-4692-9836-829dcd43eb0a	26596967-1869-455a-9b09-51ac5068245e	ed208cf0-affc-4f56-abdb-218ef76571ad	4	\N	\N	\N	Москва, 4-й Лесной пер. 4	t
82345d60-e933-48b1-93c7-9ce7bb86afb5	654b993d-15aa-4818-b3b0-546b617fccaf	d2855506-330b-4aad-91d4-b4463ccce58d	598080cf-c8b9-4a59-93f9-fb7707efde59	d9de9819-e64a-49f4-806f-4b6c6c6b3eb4	10edfe31-3e6c-4413-b2b9-5b8b32772c41	9ccd1d52-bdb0-44c8-a527-e7a727865060	20	\N	2	\N	Краснодар, Северная 20 кв. 2	t
e58bc8f1-80cc-4715-aa3d-5f40f58a188a	8a966ced-9c88-4e2b-a33d-3ae11f90d634	d2855506-330b-4aad-91d4-b4463ccce58d	598080cf-c8b9-4a59-93f9-fb7707efde59	6022e89a-393d-4417-a78f-b3e27c694dc1	1c2228b2-f6fc-4265-b129-0c4c04dd3c9f	0ef656a1-1993-4dcc-8aa5-9edee167b0c9	15	\N	304	\N	Ростов-На-Дону, Ленина 15 кв. 304	t
6e9019b5-9beb-4a64-9c8f-5ac950e345df	4b933d43-d401-47ad-aba2-fdfb2a2a9a19	d2855506-330b-4aad-91d4-b4463ccce58d	598080cf-c8b9-4a59-93f9-fb7707efde59	7a7b93d9-6f7a-4627-9806-0904881049b3	02722a06-c5b9-4ef0-97dc-ba8cc1ae5eb7	a194a7c8-2bab-43fd-af56-34a7bd055e8a	7	\N	14	\N	Санкт-Петербург, Кронверкский пр-т 7 кв. 14	t
be322bf2-8c7d-4767-9f45-f0054b8a411b	2ec9874b-8451-410b-9c20-d32657874d3e	d2855506-330b-4aad-91d4-b4463ccce58d	598080cf-c8b9-4a59-93f9-fb7707efde59	e99a12cc-6478-4692-9836-829dcd43eb0a	26596967-1869-455a-9b09-51ac5068245e	fae9a46d-15f6-40dc-9f55-f1457b91e7bd	12	\N	45	\N	Москва, Тверская 12 кв. 45	t
\.


--
-- Data for Name: user_attribute_type; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_attribute_type (attribute_type_id, code, name, value_type, description) FROM stdin;
9205a743-a241-42cc-87f7-e7fc4e7327fb	FAVORITE_TECH_CATEGORY	Любимая категория техники	text	Например смартфоны, ноутбуки, умный дом
cffa1f86-7909-410d-af03-1b0683c766c2	PREFERRED_BRAND	Предпочитаемый бренд	text	Маркетинговое предпочтение покупателя
1ef47454-c491-4de0-80f5-ba34c8450cff	INSTALLMENT_INTEREST	Интерес к рассрочке	bool	Покупатель интересуется рассрочкой
a84692f6-4b77-4352-9743-3652de3d6416	AVG_ORDER_BUDGET	Средний бюджет заказа	number	Примерный бюджет покупки техники
3f80b3fb-a833-4aa5-bfca-4f1e87f76a0a	HAS_SMART_HOME	Есть устройства умного дома	bool	Гибкий признак покупателя техники
7181cdb4-fd79-4e3a-9613-f8f00260d7ae	DEVICE_ECOSYSTEM	Экосистема устройств	text	Apple, Android, Windows, mixed
6c423ade-7da5-4549-bbdb-c87dab0076d0	LOYALTY_LEVEL	Уровень лояльности	text	basic, silver, gold
6125c6ec-897e-4170-a36b-d611fb165667	BIOMETRIC_FACE_REF	Ссылка на биометрический шаблон лица	text	Опциональная ссылка на внешний биометрический шаблон
\.


--
-- Data for Name: user_attribute_value; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_attribute_value (attribute_value_id, person_id, attribute_type_id, value_text, value_number, value_date, value_bool, value_json, raw_value) FROM stdin;
828876cb-6d40-490d-a7e7-88fdf7db6486	5aa70819-ca66-4c8a-a9b4-1fbac516f7df	6c423ade-7da5-4549-bbdb-c87dab0076d0	gold	\N	\N	\N	\N	"gold"
da7c92bd-5d19-45dd-b0f2-02e6091f4cce	5aa70819-ca66-4c8a-a9b4-1fbac516f7df	3f80b3fb-a833-4aa5-bfca-4f1e87f76a0a	\N	\N	\N	t	\N	true
205cee5c-1a0b-4296-a09b-ff287d380f79	5aa70819-ca66-4c8a-a9b4-1fbac516f7df	cffa1f86-7909-410d-af03-1b0683c766c2	Samsung	\N	\N	\N	\N	"Samsung"
900e7950-c14f-4518-ab96-25a7c24eaa28	5aa70819-ca66-4c8a-a9b4-1fbac516f7df	a84692f6-4b77-4352-9743-3652de3d6416	\N	65000	\N	\N	\N	65000
f0efafb7-9cb4-4c6e-8884-8d81bd04c63f	5aa70819-ca66-4c8a-a9b4-1fbac516f7df	7181cdb4-fd79-4e3a-9613-f8f00260d7ae	Android	\N	\N	\N	\N	"Android"
00a17fd7-f3a5-419d-a0d8-8338e6cb0711	5aa70819-ca66-4c8a-a9b4-1fbac516f7df	1ef47454-c491-4de0-80f5-ba34c8450cff	\N	\N	\N	t	\N	true
5abb9db7-2c60-486b-855e-1f1b56e5c5ac	5aa70819-ca66-4c8a-a9b4-1fbac516f7df	9205a743-a241-42cc-87f7-e7fc4e7327fb	смартфоны	\N	\N	\N	\N	"смартфоны"
b21035fe-e573-4261-8c31-13fee2327dcd	63bc9c20-2072-4f09-91a7-9b9397a30a7e	6c423ade-7da5-4549-bbdb-c87dab0076d0	silver	\N	\N	\N	\N	"silver"
27b400fb-06d6-4a22-8b82-e426bcf8e02b	63bc9c20-2072-4f09-91a7-9b9397a30a7e	cffa1f86-7909-410d-af03-1b0683c766c2	Apple	\N	\N	\N	\N	"Apple"
707163d4-b4ba-48bd-b4a5-2e1e1789df05	63bc9c20-2072-4f09-91a7-9b9397a30a7e	a84692f6-4b77-4352-9743-3652de3d6416	\N	120000	\N	\N	\N	120000
1b1a0a0c-e483-4cbf-b023-a794293f71f8	63bc9c20-2072-4f09-91a7-9b9397a30a7e	7181cdb4-fd79-4e3a-9613-f8f00260d7ae	Apple	\N	\N	\N	\N	"Apple"
0ed6613e-99b9-4a9f-abca-19e17bf6a724	63bc9c20-2072-4f09-91a7-9b9397a30a7e	1ef47454-c491-4de0-80f5-ba34c8450cff	\N	\N	\N	f	\N	false
a517c2cb-152c-4b18-a747-9140bda3c22e	63bc9c20-2072-4f09-91a7-9b9397a30a7e	9205a743-a241-42cc-87f7-e7fc4e7327fb	ноутбуки	\N	\N	\N	\N	"ноутбуки"
ac629f80-0a76-49fa-b3c4-cc875de610e1	855bc0e4-82c8-41f6-a813-b7e6ee7e8a23	6c423ade-7da5-4549-bbdb-c87dab0076d0	basic	\N	\N	\N	\N	"basic"
925d4dd3-96dc-481e-beda-cc2508c5bf03	855bc0e4-82c8-41f6-a813-b7e6ee7e8a23	3f80b3fb-a833-4aa5-bfca-4f1e87f76a0a	\N	\N	\N	f	\N	false
8f13bc9f-04de-4d1b-ab4a-eb16ce62a9a3	855bc0e4-82c8-41f6-a813-b7e6ee7e8a23	cffa1f86-7909-410d-af03-1b0683c766c2	Sony	\N	\N	\N	\N	"Sony"
0c655c32-ca3d-4725-8347-64fbda6437e4	855bc0e4-82c8-41f6-a813-b7e6ee7e8a23	a84692f6-4b77-4352-9743-3652de3d6416	\N	80000	\N	\N	\N	80000
bcfc860c-0245-42de-9545-1a86f2d2c883	855bc0e4-82c8-41f6-a813-b7e6ee7e8a23	1ef47454-c491-4de0-80f5-ba34c8450cff	\N	\N	\N	t	\N	true
4f2f4f67-4b95-467f-b06c-9a6f922107b8	855bc0e4-82c8-41f6-a813-b7e6ee7e8a23	9205a743-a241-42cc-87f7-e7fc4e7327fb	игровые консоли	\N	\N	\N	\N	"игровые консоли"
30db0827-e52d-400d-be07-ecb5146aa5d6	b799f78d-4fe9-4b37-b960-403b8a99c75b	3f80b3fb-a833-4aa5-bfca-4f1e87f76a0a	\N	\N	\N	t	\N	true
3307a6c4-6214-4609-aed1-a643d544747f	b799f78d-4fe9-4b37-b960-403b8a99c75b	cffa1f86-7909-410d-af03-1b0683c766c2	Xiaomi	\N	\N	\N	\N	"Xiaomi"
3937c774-efae-447d-a5fd-d35e105e7699	b799f78d-4fe9-4b37-b960-403b8a99c75b	a84692f6-4b77-4352-9743-3652de3d6416	\N	30000	\N	\N	\N	30000
9827133e-417c-48ff-9317-d4ea1cc2d074	b799f78d-4fe9-4b37-b960-403b8a99c75b	7181cdb4-fd79-4e3a-9613-f8f00260d7ae	mixed	\N	\N	\N	\N	"mixed"
88dbfa45-aaf5-4817-84f9-427cf0995ee2	b799f78d-4fe9-4b37-b960-403b8a99c75b	6125c6ec-897e-4170-a36b-d611fb165667	face-template://legacy/4451	\N	\N	\N	\N	"face-template://legacy/4451"
354de957-aa25-4c20-b1ee-8bb9f97a3668	b799f78d-4fe9-4b37-b960-403b8a99c75b	1ef47454-c491-4de0-80f5-ba34c8450cff	\N	\N	\N	t	\N	true
0b41b48a-3377-4d61-a13e-90aedb0a1556	b799f78d-4fe9-4b37-b960-403b8a99c75b	9205a743-a241-42cc-87f7-e7fc4e7327fb	умный дом	\N	\N	\N	\N	"умный дом"
beede8fa-db81-4959-b9e7-ab16c9872662	550848a3-6fe6-4a35-8423-a6d2319c6310	6c423ade-7da5-4549-bbdb-c87dab0076d0	basic	\N	\N	\N	\N	"basic"
3d180cf6-e22d-4003-a1c2-0c45d8b87f0e	550848a3-6fe6-4a35-8423-a6d2319c6310	cffa1f86-7909-410d-af03-1b0683c766c2	AMD	\N	\N	\N	\N	"AMD"
6a54dcbd-acbd-402a-804b-e4906048d866	550848a3-6fe6-4a35-8423-a6d2319c6310	a84692f6-4b77-4352-9743-3652de3d6416	\N	45000	\N	\N	\N	45000
492fc09d-3ac4-4a9e-94c1-45901b05b6dc	550848a3-6fe6-4a35-8423-a6d2319c6310	1ef47454-c491-4de0-80f5-ba34c8450cff	\N	\N	\N	f	\N	false
25bb2982-ea15-4207-8bad-7f1fddc53523	550848a3-6fe6-4a35-8423-a6d2319c6310	9205a743-a241-42cc-87f7-e7fc4e7327fb	комплектующие	\N	\N	\N	\N	"комплектующие"
404a39a2-d728-4533-80b1-1b915e97b0da	fc365817-43bb-468f-94f8-2cde7e25e36b	6c423ade-7da5-4549-bbdb-c87dab0076d0	gold	\N	\N	\N	\N	"gold"
954c618e-10db-4e83-a797-e8269da95d3a	fc365817-43bb-468f-94f8-2cde7e25e36b	cffa1f86-7909-410d-af03-1b0683c766c2	Lenovo	\N	\N	\N	\N	"Lenovo"
f2f7a403-adde-49d0-b85d-9b7b986e0612	fc365817-43bb-468f-94f8-2cde7e25e36b	a84692f6-4b77-4352-9743-3652de3d6416	\N	90000	\N	\N	\N	90000
6b856f1d-37e2-4b0c-8ee4-ac4de1082543	fc365817-43bb-468f-94f8-2cde7e25e36b	1ef47454-c491-4de0-80f5-ba34c8450cff	\N	\N	\N	t	\N	true
7eeec111-91c1-46da-a3d7-97b45f91db49	fc365817-43bb-468f-94f8-2cde7e25e36b	9205a743-a241-42cc-87f7-e7fc4e7327fb	ноутбуки	\N	\N	\N	\N	"ноутбуки"
3132df4d-bb00-4930-ad5a-878e3c573f5e	25853afc-6029-4c0c-a13f-e4738b2dcce4	6c423ade-7da5-4549-bbdb-c87dab0076d0	gold	\N	\N	\N	\N	"gold"
9b33f59f-9f24-4de8-9d24-8151e6f46120	25853afc-6029-4c0c-a13f-e4738b2dcce4	cffa1f86-7909-410d-af03-1b0683c766c2	Apple	\N	\N	\N	\N	"Apple"
43479c3a-9a06-4aaf-a9a7-f24167af3df7	25853afc-6029-4c0c-a13f-e4738b2dcce4	a84692f6-4b77-4352-9743-3652de3d6416	\N	110000	\N	\N	\N	110000
650358f4-6d91-4974-9f23-69d787ef94f2	25853afc-6029-4c0c-a13f-e4738b2dcce4	1ef47454-c491-4de0-80f5-ba34c8450cff	\N	\N	\N	f	\N	false
51b2074a-ca99-4875-b45a-79e37d50f26e	25853afc-6029-4c0c-a13f-e4738b2dcce4	9205a743-a241-42cc-87f7-e7fc4e7327fb	смартфоны	\N	\N	\N	\N	"смартфоны"
79e744c2-0be7-4ec3-b43b-cca7544f0ab3	fbeb1c48-3620-4ecf-b8a1-bf4a27cf16b4	6c423ade-7da5-4549-bbdb-c87dab0076d0	silver	\N	\N	\N	\N	"silver"
2d0503f0-91af-4c9a-830b-2f4b512960f3	fbeb1c48-3620-4ecf-b8a1-bf4a27cf16b4	cffa1f86-7909-410d-af03-1b0683c766c2	LG	\N	\N	\N	\N	"LG"
35f95ae3-209e-4903-b5aa-7f187e4d9f8a	fbeb1c48-3620-4ecf-b8a1-bf4a27cf16b4	a84692f6-4b77-4352-9743-3652de3d6416	\N	70000	\N	\N	\N	70000
dd475d9c-4b08-4e27-a125-80cdba09c7d1	fbeb1c48-3620-4ecf-b8a1-bf4a27cf16b4	1ef47454-c491-4de0-80f5-ba34c8450cff	\N	\N	\N	t	\N	true
b3d279bc-99c1-4305-8796-137dfb4e2c31	fbeb1c48-3620-4ecf-b8a1-bf4a27cf16b4	9205a743-a241-42cc-87f7-e7fc4e7327fb	телевизоры	\N	\N	\N	\N	"телевизоры"
470202e0-054f-435a-91a9-4ba34a2b59fb	1afd6722-3382-425e-9ac4-d9bc81faa2ef	6c423ade-7da5-4549-bbdb-c87dab0076d0	basic	\N	\N	\N	\N	"basic"
bc72d46e-627a-492f-b807-a95c3308dcb4	1afd6722-3382-425e-9ac4-d9bc81faa2ef	cffa1f86-7909-410d-af03-1b0683c766c2	Xiaomi	\N	\N	\N	\N	"Xiaomi"
ce9181c2-e2d2-4356-8065-124dec473a79	1afd6722-3382-425e-9ac4-d9bc81faa2ef	a84692f6-4b77-4352-9743-3652de3d6416	\N	35000	\N	\N	\N	35000
64507a29-e95c-4d15-bb39-71b4b6ba60f7	1afd6722-3382-425e-9ac4-d9bc81faa2ef	1ef47454-c491-4de0-80f5-ba34c8450cff	\N	\N	\N	t	\N	true
cffaff11-9f26-4237-847b-ca76374a297a	1afd6722-3382-425e-9ac4-d9bc81faa2ef	9205a743-a241-42cc-87f7-e7fc4e7327fb	умный дом	\N	\N	\N	\N	"умный дом"
ef1965b0-0214-46dd-a7dc-c853d2f99041	d6ddb3d0-1f03-49b1-a1a1-c78918b6a273	6c423ade-7da5-4549-bbdb-c87dab0076d0	silver	\N	\N	\N	\N	"silver"
dec63656-d40d-40cf-b797-7bc1bd08eb37	d6ddb3d0-1f03-49b1-a1a1-c78918b6a273	cffa1f86-7909-410d-af03-1b0683c766c2	AMD	\N	\N	\N	\N	"AMD"
d47b2995-d905-46b7-8681-48b2ae149871	d6ddb3d0-1f03-49b1-a1a1-c78918b6a273	a84692f6-4b77-4352-9743-3652de3d6416	\N	55000	\N	\N	\N	55000
1b192554-4ba5-41b1-8466-98daca89753c	d6ddb3d0-1f03-49b1-a1a1-c78918b6a273	1ef47454-c491-4de0-80f5-ba34c8450cff	\N	\N	\N	f	\N	false
7d40d755-752e-41df-b8db-6256afce318f	d6ddb3d0-1f03-49b1-a1a1-c78918b6a273	9205a743-a241-42cc-87f7-e7fc4e7327fb	комплектующие	\N	\N	\N	\N	"комплектующие"
79c77043-611e-4f7f-902a-63278489fdf5	2fcab39c-aee5-48a2-8c43-0e3289dbd4ed	6c423ade-7da5-4549-bbdb-c87dab0076d0	silver	\N	\N	\N	\N	"silver"
18479bb8-5d87-429f-a50b-c2287b7d41db	2fcab39c-aee5-48a2-8c43-0e3289dbd4ed	cffa1f86-7909-410d-af03-1b0683c766c2	Samsung	\N	\N	\N	\N	"Samsung"
a3ddc0ad-08aa-4b1b-b1f7-998a29cbd53d	2fcab39c-aee5-48a2-8c43-0e3289dbd4ed	a84692f6-4b77-4352-9743-3652de3d6416	\N	50000	\N	\N	\N	50000
8de85f9a-3f96-4da9-8a61-de10e492b2b6	2fcab39c-aee5-48a2-8c43-0e3289dbd4ed	1ef47454-c491-4de0-80f5-ba34c8450cff	\N	\N	\N	t	\N	true
b57ae9a5-b269-4e67-b754-f60b510d606a	2fcab39c-aee5-48a2-8c43-0e3289dbd4ed	9205a743-a241-42cc-87f7-e7fc4e7327fb	планшеты	\N	\N	\N	\N	"планшеты"
da216659-b2d4-47ee-9009-197a384a85ee	fbe544b5-469e-424d-bbb1-9b2fd820694a	6c423ade-7da5-4549-bbdb-c87dab0076d0	silver	\N	\N	\N	\N	"silver"
8cab5650-9eda-47d5-b0f5-bf726cb66026	fbe544b5-469e-424d-bbb1-9b2fd820694a	cffa1f86-7909-410d-af03-1b0683c766c2	Sony	\N	\N	\N	\N	"Sony"
77fe6e85-d5dc-4383-9a37-75d1262ccc01	fbe544b5-469e-424d-bbb1-9b2fd820694a	a84692f6-4b77-4352-9743-3652de3d6416	\N	78000	\N	\N	\N	78000
606b8a1f-e50b-4e82-8788-d40287e2867c	fbe544b5-469e-424d-bbb1-9b2fd820694a	1ef47454-c491-4de0-80f5-ba34c8450cff	\N	\N	\N	t	\N	true
38134594-c16e-4f01-b0d7-34b86609c6d5	fbe544b5-469e-424d-bbb1-9b2fd820694a	9205a743-a241-42cc-87f7-e7fc4e7327fb	игровые консоли	\N	\N	\N	\N	"игровые консоли"
2ab542f7-7a4f-47fb-86db-3b711e80a26b	acd35a49-f817-4252-88f4-611194a195f1	6c423ade-7da5-4549-bbdb-c87dab0076d0	silver	\N	\N	\N	\N	"silver"
e13cc95d-194e-4a0a-a474-ffebf1143ecf	acd35a49-f817-4252-88f4-611194a195f1	cffa1f86-7909-410d-af03-1b0683c766c2	Canon	\N	\N	\N	\N	"Canon"
bd5e0ee8-1792-4386-a199-720a83779dc0	acd35a49-f817-4252-88f4-611194a195f1	a84692f6-4b77-4352-9743-3652de3d6416	\N	65000	\N	\N	\N	65000
ca00cd82-ed18-4e62-9724-60dc3d1f3096	acd35a49-f817-4252-88f4-611194a195f1	1ef47454-c491-4de0-80f5-ba34c8450cff	\N	\N	\N	f	\N	false
801a5fa6-894c-4672-8478-c165b7846bc0	acd35a49-f817-4252-88f4-611194a195f1	9205a743-a241-42cc-87f7-e7fc4e7327fb	фото	\N	\N	\N	\N	"фото"
0eff62bf-d7d7-4173-8bc8-ea590534c9a2	48e18473-6d22-42fa-8df8-042be293eaab	6c423ade-7da5-4549-bbdb-c87dab0076d0	silver	\N	\N	\N	\N	"silver"
6a403bb5-8baf-453b-92ab-bc1edc9f61ae	48e18473-6d22-42fa-8df8-042be293eaab	cffa1f86-7909-410d-af03-1b0683c766c2	HP	\N	\N	\N	\N	"HP"
9f9fcb06-8530-406b-b17f-9b23b248a1ab	48e18473-6d22-42fa-8df8-042be293eaab	a84692f6-4b77-4352-9743-3652de3d6416	\N	60000	\N	\N	\N	60000
71175687-2f2f-42ba-b1bb-784c3e18441f	48e18473-6d22-42fa-8df8-042be293eaab	1ef47454-c491-4de0-80f5-ba34c8450cff	\N	\N	\N	f	\N	false
0e453fdb-4bf0-4add-9e86-512847b38fd4	48e18473-6d22-42fa-8df8-042be293eaab	9205a743-a241-42cc-87f7-e7fc4e7327fb	ноутбуки	\N	\N	\N	\N	"ноутбуки"
a30445eb-235d-4d17-9d03-3c7eb5d3d4ae	3a132bab-0588-4f51-b527-4491f0e007eb	6c423ade-7da5-4549-bbdb-c87dab0076d0	basic	\N	\N	\N	\N	"basic"
d70f22a6-36ac-4a2f-b971-8a380a9893ce	3a132bab-0588-4f51-b527-4491f0e007eb	cffa1f86-7909-410d-af03-1b0683c766c2	Huawei	\N	\N	\N	\N	"Huawei"
0fd17d04-a67b-4e2d-8aad-420a109a02e2	3a132bab-0588-4f51-b527-4491f0e007eb	a84692f6-4b77-4352-9743-3652de3d6416	\N	42000	\N	\N	\N	42000
6c06bafb-f34d-4bd7-82c4-53dc5e20b07d	3a132bab-0588-4f51-b527-4491f0e007eb	1ef47454-c491-4de0-80f5-ba34c8450cff	\N	\N	\N	t	\N	true
991e7393-aca5-43ee-8cf7-ae90b9702c03	3a132bab-0588-4f51-b527-4491f0e007eb	9205a743-a241-42cc-87f7-e7fc4e7327fb	смартфоны	\N	\N	\N	\N	"смартфоны"
ac4173e1-aabe-48ea-a32f-1fcccea3019b	e339c5c8-853e-4e80-a8bd-065bb83c7285	6c423ade-7da5-4549-bbdb-c87dab0076d0	basic	\N	\N	\N	\N	"basic"
a17d56d9-8ed4-4d54-90eb-267717c41594	e339c5c8-853e-4e80-a8bd-065bb83c7285	cffa1f86-7909-410d-af03-1b0683c766c2	Sony	\N	\N	\N	\N	"Sony"
d65083b0-fe40-4f40-998c-9320300e0a51	e339c5c8-853e-4e80-a8bd-065bb83c7285	a84692f6-4b77-4352-9743-3652de3d6416	\N	22000	\N	\N	\N	22000
3f39e969-df12-4091-ad42-77d67372919d	e339c5c8-853e-4e80-a8bd-065bb83c7285	1ef47454-c491-4de0-80f5-ba34c8450cff	\N	\N	\N	f	\N	false
1b518399-eeac-48b3-bb23-62ca6d1fc2bf	e339c5c8-853e-4e80-a8bd-065bb83c7285	9205a743-a241-42cc-87f7-e7fc4e7327fb	наушники	\N	\N	\N	\N	"наушники"
1b161e07-5c0f-411d-9aec-9d4dd2c50f7b	6888527f-634d-496f-b96b-444793bca565	6c423ade-7da5-4549-bbdb-c87dab0076d0	basic	\N	\N	\N	\N	"basic"
b35531b4-a90e-423b-b5e1-02124bef34f6	6888527f-634d-496f-b96b-444793bca565	cffa1f86-7909-410d-af03-1b0683c766c2	Aqara	\N	\N	\N	\N	"Aqara"
95ebd353-f4be-466b-a478-922c24ced6c2	6888527f-634d-496f-b96b-444793bca565	a84692f6-4b77-4352-9743-3652de3d6416	\N	28000	\N	\N	\N	28000
e1359c32-60ca-468e-8912-70effe103c6a	6888527f-634d-496f-b96b-444793bca565	1ef47454-c491-4de0-80f5-ba34c8450cff	\N	\N	\N	t	\N	true
3a2ae68a-f076-477a-8717-33a0cb8e338a	6888527f-634d-496f-b96b-444793bca565	9205a743-a241-42cc-87f7-e7fc4e7327fb	умный дом	\N	\N	\N	\N	"умный дом"
bd3b1670-e76d-4dbf-93ef-f8c1a9124cc1	5dfc38a2-3795-49df-aef6-32027b71786a	6c423ade-7da5-4549-bbdb-c87dab0076d0	basic	\N	\N	\N	\N	"basic"
3a8187c0-e9c2-405f-b7f7-879eced16b29	5dfc38a2-3795-49df-aef6-32027b71786a	cffa1f86-7909-410d-af03-1b0683c766c2	Intel	\N	\N	\N	\N	"Intel"
246d59c2-0034-438c-882b-bb9d836ecd6a	5dfc38a2-3795-49df-aef6-32027b71786a	a84692f6-4b77-4352-9743-3652de3d6416	\N	47000	\N	\N	\N	47000
6ff08a03-d0fa-4915-b570-d7c29bf10f3c	5dfc38a2-3795-49df-aef6-32027b71786a	1ef47454-c491-4de0-80f5-ba34c8450cff	\N	\N	\N	f	\N	false
d4ca4bd6-eb53-4660-8439-8dd29743fefd	5dfc38a2-3795-49df-aef6-32027b71786a	9205a743-a241-42cc-87f7-e7fc4e7327fb	комплектующие	\N	\N	\N	\N	"комплектующие"
b5293b2e-7c93-44b4-a825-0dedf4dee714	8dd81453-964f-4b8b-8249-d7ef8b9d1a0f	6c423ade-7da5-4549-bbdb-c87dab0076d0	silver	\N	\N	\N	\N	"silver"
e9c002e4-40e2-4354-b424-4af7ee1d8b45	8dd81453-964f-4b8b-8249-d7ef8b9d1a0f	cffa1f86-7909-410d-af03-1b0683c766c2	Bosch	\N	\N	\N	\N	"Bosch"
701b3077-0ef5-4723-8eb5-10404695e802	8dd81453-964f-4b8b-8249-d7ef8b9d1a0f	a84692f6-4b77-4352-9743-3652de3d6416	\N	52000	\N	\N	\N	52000
f5cdc939-289d-42cc-b2cf-f34e9cb5d3bd	8dd81453-964f-4b8b-8249-d7ef8b9d1a0f	1ef47454-c491-4de0-80f5-ba34c8450cff	\N	\N	\N	t	\N	true
32f04d66-4ce9-4433-a1e3-4a6e7c6d98da	8dd81453-964f-4b8b-8249-d7ef8b9d1a0f	9205a743-a241-42cc-87f7-e7fc4e7327fb	бытовая техника	\N	\N	\N	\N	"бытовая техника"
f8a02205-ab28-4f64-a8f4-1859c0d58eb8	c4e8c4b9-3232-445f-8631-0783f78362c4	6c423ade-7da5-4549-bbdb-c87dab0076d0	basic	\N	\N	\N	\N	"basic"
b2dc2741-8c18-415a-a103-e409c697ff9d	c4e8c4b9-3232-445f-8631-0783f78362c4	cffa1f86-7909-410d-af03-1b0683c766c2	TCL	\N	\N	\N	\N	"TCL"
8e251a8a-bbad-4dc4-aee0-d32be08907a9	c4e8c4b9-3232-445f-8631-0783f78362c4	a84692f6-4b77-4352-9743-3652de3d6416	\N	33000	\N	\N	\N	33000
e4a92f22-a627-4f54-a50b-1db70bcf44fb	c4e8c4b9-3232-445f-8631-0783f78362c4	1ef47454-c491-4de0-80f5-ba34c8450cff	\N	\N	\N	f	\N	false
73a9d805-1368-4d4f-8a4d-0b3ab93dc7a6	c4e8c4b9-3232-445f-8631-0783f78362c4	9205a743-a241-42cc-87f7-e7fc4e7327fb	телевизоры	\N	\N	\N	\N	"телевизоры"
c264c17f-de9e-44bc-a049-3b128736f64b	128537da-acbe-48cb-8c24-059585840c3a	6c423ade-7da5-4549-bbdb-c87dab0076d0	basic	\N	\N	\N	\N	"basic"
030e2265-4d8d-4873-b999-c88f118060fc	128537da-acbe-48cb-8c24-059585840c3a	cffa1f86-7909-410d-af03-1b0683c766c2	Xiaomi	\N	\N	\N	\N	"Xiaomi"
85c22280-37b9-42ec-b6e7-18a39cca4481	128537da-acbe-48cb-8c24-059585840c3a	a84692f6-4b77-4352-9743-3652de3d6416	\N	39000	\N	\N	\N	39000
7b7c8db4-2ac6-4303-856c-51b1b1c8c849	128537da-acbe-48cb-8c24-059585840c3a	1ef47454-c491-4de0-80f5-ba34c8450cff	\N	\N	\N	t	\N	true
31617776-f7d6-4895-9b3d-d3899c17f903	128537da-acbe-48cb-8c24-059585840c3a	9205a743-a241-42cc-87f7-e7fc4e7327fb	смартфоны	\N	\N	\N	\N	"смартфоны"
a9ecdbf7-aa65-4fb6-b371-9810f1557ae3	654b993d-15aa-4818-b3b0-546b617fccaf	6c423ade-7da5-4549-bbdb-c87dab0076d0	gold	\N	\N	\N	\N	"gold"
d573cdf4-afd7-45c0-9d21-0d2a982ae764	654b993d-15aa-4818-b3b0-546b617fccaf	cffa1f86-7909-410d-af03-1b0683c766c2	Microsoft	\N	\N	\N	\N	"Microsoft"
5a7bcf13-a981-4413-b97b-fa0268dd626f	654b993d-15aa-4818-b3b0-546b617fccaf	a84692f6-4b77-4352-9743-3652de3d6416	\N	85000	\N	\N	\N	85000
19ff6374-18f6-4c98-8462-63e9760dbbc5	654b993d-15aa-4818-b3b0-546b617fccaf	1ef47454-c491-4de0-80f5-ba34c8450cff	\N	\N	\N	t	\N	true
488a361d-42a6-48d7-b503-ec28fc9deef6	654b993d-15aa-4818-b3b0-546b617fccaf	9205a743-a241-42cc-87f7-e7fc4e7327fb	игровые консоли	\N	\N	\N	\N	"игровые консоли"
3b47ef6f-7383-4075-b224-766966094129	8a966ced-9c88-4e2b-a33d-3ae11f90d634	6c423ade-7da5-4549-bbdb-c87dab0076d0	gold	\N	\N	\N	\N	"gold"
63c00df9-0db0-44d6-9440-078528b76418	8a966ced-9c88-4e2b-a33d-3ae11f90d634	cffa1f86-7909-410d-af03-1b0683c766c2	Asus	\N	\N	\N	\N	"Asus"
4269e6b5-ede8-4cf5-b2fd-b87412b9f718	8a966ced-9c88-4e2b-a33d-3ae11f90d634	a84692f6-4b77-4352-9743-3652de3d6416	\N	95000	\N	\N	\N	95000
0511cf1a-c42b-464b-9bb5-70166f5abda7	8a966ced-9c88-4e2b-a33d-3ae11f90d634	1ef47454-c491-4de0-80f5-ba34c8450cff	\N	\N	\N	f	\N	false
5749072a-b415-49fe-af24-d25098e93662	8a966ced-9c88-4e2b-a33d-3ae11f90d634	9205a743-a241-42cc-87f7-e7fc4e7327fb	ноутбуки	\N	\N	\N	\N	"ноутбуки"
9da403ad-4a51-4717-ac7b-e3c6ecbc0e11	4b933d43-d401-47ad-aba2-fdfb2a2a9a19	6c423ade-7da5-4549-bbdb-c87dab0076d0	silver	\N	\N	\N	\N	"silver"
3aba770e-f6be-41eb-869f-d2923c0940a9	4b933d43-d401-47ad-aba2-fdfb2a2a9a19	cffa1f86-7909-410d-af03-1b0683c766c2	Nikon	\N	\N	\N	\N	"Nikon"
540552ac-5d9c-4c9c-bccd-749fb0aa6e8b	4b933d43-d401-47ad-aba2-fdfb2a2a9a19	a84692f6-4b77-4352-9743-3652de3d6416	\N	73000	\N	\N	\N	73000
4f1c1c14-37b8-4899-a85e-19393ccded1e	4b933d43-d401-47ad-aba2-fdfb2a2a9a19	1ef47454-c491-4de0-80f5-ba34c8450cff	\N	\N	\N	t	\N	true
1ef00f9a-cade-4a08-a345-b4ec4c27dffc	4b933d43-d401-47ad-aba2-fdfb2a2a9a19	9205a743-a241-42cc-87f7-e7fc4e7327fb	фото	\N	\N	\N	\N	"фото"
32511fad-a67a-4f1d-ab22-726a2d81b278	2ec9874b-8451-410b-9c20-d32657874d3e	6c423ade-7da5-4549-bbdb-c87dab0076d0	basic	\N	\N	\N	\N	"basic"
0b374626-c673-4ca6-8c6f-89e4b4da4e44	2ec9874b-8451-410b-9c20-d32657874d3e	cffa1f86-7909-410d-af03-1b0683c766c2	Яндекс	\N	\N	\N	\N	"Яндекс"
99788d33-2451-487b-9cd8-3f34e66d8833	2ec9874b-8451-410b-9c20-d32657874d3e	a84692f6-4b77-4352-9743-3652de3d6416	\N	25000	\N	\N	\N	25000
1e029b61-9ca5-4dc1-9031-cb983ebc022f	2ec9874b-8451-410b-9c20-d32657874d3e	1ef47454-c491-4de0-80f5-ba34c8450cff	\N	\N	\N	f	\N	false
9a445919-4462-4cf2-8b87-c3d4ade48b83	2ec9874b-8451-410b-9c20-d32657874d3e	9205a743-a241-42cc-87f7-e7fc4e7327fb	умный дом	\N	\N	\N	\N	"умный дом"
\.


--
-- Data for Name: user_consent; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_consent (consent_id, person_id, consent_type_id, is_granted, granted_at, revoked_at, source, raw_value) FROM stdin;
61b93c1b-73ee-49b2-800b-7ab4ef990ca6	5aa70819-ca66-4c8a-a9b4-1fbac516f7df	47eeac3f-6c9c-4055-8fb2-76d1f182225b	t	2026-05-06 10:00:00+03	\N	web_form	согласен на обработку ПД
a0199f46-feff-48b3-9f18-6f8886c92cec	5aa70819-ca66-4c8a-a9b4-1fbac516f7df	ecfba232-e2a2-4d3c-8444-7e62378143b0	t	2026-05-06 10:00:00+03	\N	web_form	да, хочу скидки
c31f7017-f594-4c11-ad6f-82b92c37664b	63bc9c20-2072-4f09-91a7-9b9397a30a7e	47eeac3f-6c9c-4055-8fb2-76d1f182225b	t	2026-05-07 12:20:00+03	\N	mobile_app	+
06d3d197-519c-47d7-b1b7-36b53937469b	63bc9c20-2072-4f09-91a7-9b9397a30a7e	4f6e6b7e-4a0d-4e99-afa8-4d1f4287c8fa	f	\N	\N	mobile_app	sms: нет
473d48e6-55d6-4250-89d4-d894b2a4d507	855bc0e4-82c8-41f6-a813-b7e6ee7e8a23	47eeac3f-6c9c-4055-8fb2-76d1f182225b	t	2026-05-08 09:00:00+03	\N	call_center	оператор отметил согласие
de3a76da-bdc0-4855-a559-28e11ecd0438	b799f78d-4fe9-4b37-b960-403b8a99c75b	47eeac3f-6c9c-4055-8fb2-76d1f182225b	t	\N	\N	paper_form	бумажная анкета: да
c213aa02-745a-4a1c-840e-591e1e1eb148	b799f78d-4fe9-4b37-b960-403b8a99c75b	d380a6ef-ae45-43b3-81aa-a51c480615d8	t	\N	\N	paper_form	передача партнерам: согласна
cb09888b-f79f-44c5-8e0c-8650f32a45f0	550848a3-6fe6-4a35-8423-a6d2319c6310	47eeac3f-6c9c-4055-8fb2-76d1f182225b	t	2026-05-09 17:45:00+03	\N	web_form	accepted
ad588a45-bea9-4613-bac4-44d9f634fc11	fc365817-43bb-468f-94f8-2cde7e25e36b	47eeac3f-6c9c-4055-8fb2-76d1f182225b	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
ad392a73-c86e-4568-9791-eb00f551031c	fc365817-43bb-468f-94f8-2cde7e25e36b	ecfba232-e2a2-4d3c-8444-7e62378143b0	f	\N	\N	seed_bulk	email no
973a2c85-260c-43b5-8c9c-580b9950d4ba	25853afc-6029-4c0c-a13f-e4738b2dcce4	47eeac3f-6c9c-4055-8fb2-76d1f182225b	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
a9d2d022-e1d6-4fbf-ac24-4af6fa714a08	25853afc-6029-4c0c-a13f-e4738b2dcce4	ecfba232-e2a2-4d3c-8444-7e62378143b0	t	\N	\N	seed_bulk	email yes
abb83ca6-9898-4244-8bfb-bf2778da820c	fbeb1c48-3620-4ecf-b8a1-bf4a27cf16b4	47eeac3f-6c9c-4055-8fb2-76d1f182225b	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
30da7ef1-ef1a-4de8-9d41-af77e20000ce	fbeb1c48-3620-4ecf-b8a1-bf4a27cf16b4	ecfba232-e2a2-4d3c-8444-7e62378143b0	f	\N	\N	seed_bulk	email no
9980f298-c373-41b5-8389-3b41a4c32848	1afd6722-3382-425e-9ac4-d9bc81faa2ef	47eeac3f-6c9c-4055-8fb2-76d1f182225b	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
7396f731-fd81-434b-82ef-2f5e53964351	1afd6722-3382-425e-9ac4-d9bc81faa2ef	ecfba232-e2a2-4d3c-8444-7e62378143b0	t	\N	\N	seed_bulk	email yes
04644af6-5f7f-490a-8acf-b2d31ed391c4	d6ddb3d0-1f03-49b1-a1a1-c78918b6a273	47eeac3f-6c9c-4055-8fb2-76d1f182225b	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
9054640a-8a40-4e19-b9ef-3f357d2515a9	d6ddb3d0-1f03-49b1-a1a1-c78918b6a273	ecfba232-e2a2-4d3c-8444-7e62378143b0	f	\N	\N	seed_bulk	email no
6886ef3d-5b1a-4ffc-bef0-e7a54f2d909f	2fcab39c-aee5-48a2-8c43-0e3289dbd4ed	47eeac3f-6c9c-4055-8fb2-76d1f182225b	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
24e9dd8d-1832-4fae-b0a2-2addd2e361f6	2fcab39c-aee5-48a2-8c43-0e3289dbd4ed	ecfba232-e2a2-4d3c-8444-7e62378143b0	t	\N	\N	seed_bulk	email yes
0d8affd7-3d10-4b2e-aebe-c66fd423d8a6	fbe544b5-469e-424d-bbb1-9b2fd820694a	47eeac3f-6c9c-4055-8fb2-76d1f182225b	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
4e4f72d2-131f-4756-8a01-be702015c892	fbe544b5-469e-424d-bbb1-9b2fd820694a	ecfba232-e2a2-4d3c-8444-7e62378143b0	f	\N	\N	seed_bulk	email no
8724c4e5-cf2c-473e-bef7-6ec6720a127f	acd35a49-f817-4252-88f4-611194a195f1	47eeac3f-6c9c-4055-8fb2-76d1f182225b	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
0c47e28d-17f9-4c1b-a241-72bf0b98f3dd	acd35a49-f817-4252-88f4-611194a195f1	ecfba232-e2a2-4d3c-8444-7e62378143b0	t	\N	\N	seed_bulk	email yes
92d760b9-f078-4e52-96aa-94827d6fa513	48e18473-6d22-42fa-8df8-042be293eaab	47eeac3f-6c9c-4055-8fb2-76d1f182225b	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
35ce69c1-4628-4375-9449-549f99d534e3	48e18473-6d22-42fa-8df8-042be293eaab	ecfba232-e2a2-4d3c-8444-7e62378143b0	f	\N	\N	seed_bulk	email no
784dddba-0d51-44fa-a425-2fa2afc4d468	3a132bab-0588-4f51-b527-4491f0e007eb	47eeac3f-6c9c-4055-8fb2-76d1f182225b	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
1a6c80aa-4cf2-47bc-b85a-dac627c7c368	3a132bab-0588-4f51-b527-4491f0e007eb	ecfba232-e2a2-4d3c-8444-7e62378143b0	t	\N	\N	seed_bulk	email yes
9a77eee1-046d-4edc-9586-f5aaf3a407a8	e339c5c8-853e-4e80-a8bd-065bb83c7285	47eeac3f-6c9c-4055-8fb2-76d1f182225b	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
902fc3d3-7323-43ab-82e2-c4d46c9ec6b1	e339c5c8-853e-4e80-a8bd-065bb83c7285	ecfba232-e2a2-4d3c-8444-7e62378143b0	f	\N	\N	seed_bulk	email no
ea46d99d-a99e-4535-b631-e797f416e328	6888527f-634d-496f-b96b-444793bca565	47eeac3f-6c9c-4055-8fb2-76d1f182225b	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
734c9dc3-cfd1-4ad9-980a-1b4d941240e8	6888527f-634d-496f-b96b-444793bca565	ecfba232-e2a2-4d3c-8444-7e62378143b0	t	\N	\N	seed_bulk	email yes
9995973f-522b-4a56-afa0-e4077b3d2dff	5dfc38a2-3795-49df-aef6-32027b71786a	47eeac3f-6c9c-4055-8fb2-76d1f182225b	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
35f7b5a4-55db-4f3f-acb5-1019a37dc8d2	5dfc38a2-3795-49df-aef6-32027b71786a	ecfba232-e2a2-4d3c-8444-7e62378143b0	f	\N	\N	seed_bulk	email no
c6868e87-f836-4d7a-9f14-0c224d0eb3b7	8dd81453-964f-4b8b-8249-d7ef8b9d1a0f	47eeac3f-6c9c-4055-8fb2-76d1f182225b	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
41b4e4e2-df08-40d4-b2fa-7fa0a5d45cba	8dd81453-964f-4b8b-8249-d7ef8b9d1a0f	ecfba232-e2a2-4d3c-8444-7e62378143b0	t	\N	\N	seed_bulk	email yes
b4446a9a-3f45-4623-9cf8-7d3b44058236	c4e8c4b9-3232-445f-8631-0783f78362c4	47eeac3f-6c9c-4055-8fb2-76d1f182225b	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
4149b921-8551-4a70-b348-3a7e3bcd7b6c	c4e8c4b9-3232-445f-8631-0783f78362c4	ecfba232-e2a2-4d3c-8444-7e62378143b0	f	\N	\N	seed_bulk	email no
e0938ee0-7aeb-4cb2-adab-cf37cb3afbb8	128537da-acbe-48cb-8c24-059585840c3a	47eeac3f-6c9c-4055-8fb2-76d1f182225b	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
f06c3c0d-d32d-48c4-aabd-55fa52472d5c	128537da-acbe-48cb-8c24-059585840c3a	ecfba232-e2a2-4d3c-8444-7e62378143b0	t	\N	\N	seed_bulk	email yes
be47b945-4626-40f6-b0ca-a5569ae05eef	654b993d-15aa-4818-b3b0-546b617fccaf	47eeac3f-6c9c-4055-8fb2-76d1f182225b	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
07731ed9-a64c-496f-973c-37efa003bd10	654b993d-15aa-4818-b3b0-546b617fccaf	ecfba232-e2a2-4d3c-8444-7e62378143b0	f	\N	\N	seed_bulk	email no
dc1677d3-9421-4424-8118-f7fbb7103db7	8a966ced-9c88-4e2b-a33d-3ae11f90d634	47eeac3f-6c9c-4055-8fb2-76d1f182225b	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
dc4df3bb-5676-40f7-9d20-3e0417275df1	8a966ced-9c88-4e2b-a33d-3ae11f90d634	ecfba232-e2a2-4d3c-8444-7e62378143b0	t	\N	\N	seed_bulk	email yes
14946017-b0d1-44d9-8fcf-13d45e2f3144	4b933d43-d401-47ad-aba2-fdfb2a2a9a19	47eeac3f-6c9c-4055-8fb2-76d1f182225b	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
57992f1c-73d7-4a10-a041-52a1e1aa2636	4b933d43-d401-47ad-aba2-fdfb2a2a9a19	ecfba232-e2a2-4d3c-8444-7e62378143b0	f	\N	\N	seed_bulk	email no
f954d702-8e78-44d5-b615-af78db01c00e	2ec9874b-8451-410b-9c20-d32657874d3e	47eeac3f-6c9c-4055-8fb2-76d1f182225b	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
7bc5e6d0-c213-4386-9189-83e4763952bf	2ec9874b-8451-410b-9c20-d32657874d3e	ecfba232-e2a2-4d3c-8444-7e62378143b0	t	\N	\N	seed_bulk	email yes
\.


--
-- Data for Name: user_contact; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_contact (contact_id, person_id, contact_type_id, contact_value, raw_value, is_primary, is_verified, created_at) FROM stdin;
d6099a5a-21e1-4e4a-84db-cead44a6d6be	5aa70819-ca66-4c8a-a9b4-1fbac516f7df	f6b14271-a876-4443-b924-20a6f2fe3b5b	ivanov@example.ru	ivanov@example.ru, i.ivanov@oldmail.ru	t	t	2026-06-07 18:43:54.252358+03
fbdc8718-a005-4c0e-99e9-926b8a5d693d	5aa70819-ca66-4c8a-a9b4-1fbac516f7df	c642e2ad-b8af-4220-bdcd-fd3bd5940af2	+79991234567	+7 (999) 123-45-67 / tg: @ivan_tech	t	f	2026-06-07 18:43:54.252358+03
5e09a60e-ee9c-4022-9a36-a4aea75a72cc	5aa70819-ca66-4c8a-a9b4-1fbac516f7df	5bbc8e48-2850-4f59-ae6b-5495c9a4fd03	@ivan_tech	+7 (999) 123-45-67 / tg: @ivan_tech	f	f	2026-06-07 18:43:54.252358+03
8cf72270-8b27-4b91-ab3c-db6d4b8f60e1	63bc9c20-2072-4f09-91a7-9b9397a30a7e	f6b14271-a876-4443-b924-20a6f2fe3b5b	m.pet.rova@example.com	m.pet.rova@example.com; petrova.work@example.org	t	f	2026-06-07 18:43:54.269461+03
53411ac7-025e-4588-9348-aefa860b664d	63bc9c20-2072-4f09-91a7-9b9397a30a7e	f6b14271-a876-4443-b924-20a6f2fe3b5b	petrova.work@example.org	m.pet.rova@example.com; petrova.work@example.org	f	f	2026-06-07 18:43:54.269461+03
fe6e9559-0c75-4d8d-a390-309c8d0e582a	63bc9c20-2072-4f09-91a7-9b9397a30a7e	c642e2ad-b8af-4220-bdcd-fd3bd5940af2	+79161230000	8-916-123-00-00	f	f	2026-06-07 18:43:54.269461+03
494ec710-dcd6-4980-8cd2-b53c97194567	855bc0e4-82c8-41f6-a813-b7e6ee7e8a23	f6b14271-a876-4443-b924-20a6f2fe3b5b	bad-email-without-at	bad-email-without-at, alexey.sid@mail.ru	t	f	2026-06-07 18:43:54.273895+03
e0117af0-6efc-438e-b8eb-82d2526c8e99	855bc0e4-82c8-41f6-a813-b7e6ee7e8a23	f6b14271-a876-4443-b924-20a6f2fe3b5b	alexey.sid@mail.ru	bad-email-without-at, alexey.sid@mail.ru	f	f	2026-06-07 18:43:54.273895+03
82216a8e-42fb-4ae9-9012-f34389e34847	855bc0e4-82c8-41f6-a813-b7e6ee7e8a23	e77e0bdc-f4b9-4dd8-b6b8-384584c2c4c4	+79260001122	whatsapp +7 926 000 11 22	f	f	2026-06-07 18:43:54.273895+03
040b246a-0632-4f4d-97c0-0d9acd541aa3	b799f78d-4fe9-4b37-b960-403b8a99c75b	c642e2ad-b8af-4220-bdcd-fd3bd5940af2	+79035556677	тел. 9035556677	f	f	2026-06-07 18:43:54.280817+03
e0845144-205e-46ec-84e2-0eb23f5eb2f5	b799f78d-4fe9-4b37-b960-403b8a99c75b	5bbc8e48-2850-4f59-ae6b-5495c9a4fd03	@elena_devices	telegram: @elena_devices	f	f	2026-06-07 18:43:54.280817+03
41abd123-4d11-40b2-aedf-5e25f0862403	550848a3-6fe6-4a35-8423-a6d2319c6310	f6b14271-a876-4443-b924-20a6f2fe3b5b	denis.orlov@example.net	\N	t	t	2026-06-07 18:43:54.284421+03
323b7450-a3cb-40d0-a4b5-331aab06c82b	fc365817-43bb-468f-94f8-2cde7e25e36b	f6b14271-a876-4443-b924-20a6f2fe3b5b	p.smirnov@example.ru	p.smirnov@example.ru, smirnov.old@mail.ru	t	t	2026-06-07 18:43:54.287426+03
c62e978a-dcc8-422d-a73d-e0497252c436	fc365817-43bb-468f-94f8-2cde7e25e36b	c642e2ad-b8af-4220-bdcd-fd3bd5940af2	+7 (916) 100-20-30	+7 (916) 100-20-30	f	f	2026-06-07 18:43:54.287426+03
ae4fe05c-f377-454f-a12d-a25e0ed5dbfe	25853afc-6029-4c0c-a13f-e4738b2dcce4	f6b14271-a876-4443-b924-20a6f2fe3b5b	olga.v@example.ru	olga.v@example.ru	t	t	2026-06-07 18:43:54.287426+03
21dc362f-9ac7-430c-8b89-3cd659c62130	25853afc-6029-4c0c-a13f-e4738b2dcce4	c642e2ad-b8af-4220-bdcd-fd3bd5940af2	8-926-222-33-44	8-926-222-33-44	f	f	2026-06-07 18:43:54.287426+03
930c9ef5-bb0a-4e07-b4c1-34bf5ed40175	fbeb1c48-3620-4ecf-b8a1-bf4a27cf16b4	f6b14271-a876-4443-b924-20a6f2fe3b5b	roman.n@example.ru	roman.n@example.ru; r.nikitin@work.ru	t	t	2026-06-07 18:43:54.287426+03
72a60bbd-d7b1-4b8e-8bff-1ae38dea8f1b	fbeb1c48-3620-4ecf-b8a1-bf4a27cf16b4	c642e2ad-b8af-4220-bdcd-fd3bd5940af2	+7 812 333 44 55	+7 812 333 44 55	f	f	2026-06-07 18:43:54.287426+03
53a94a93-80e1-49ca-a056-b58f47a51cd7	1afd6722-3382-425e-9ac4-d9bc81faa2ef	f6b14271-a876-4443-b924-20a6f2fe3b5b	irina.m@example.ru	irina.m@example.ru	t	t	2026-06-07 18:43:54.287426+03
4578f31a-cf3e-4ee5-a899-7488cf4d2679	1afd6722-3382-425e-9ac4-d9bc81faa2ef	c642e2ad-b8af-4220-bdcd-fd3bd5940af2	9035556677	9035556677	f	f	2026-06-07 18:43:54.287426+03
ebe0005e-87e8-4474-b19b-5c32f4401ebc	d6ddb3d0-1f03-49b1-a1a1-c78918b6a273	f6b14271-a876-4443-b924-20a6f2fe3b5b	g.alekseev@example.ru	g.alekseev@example.ru	t	t	2026-06-07 18:43:54.287426+03
03d743c3-0867-4f17-9629-c6de15c183b1	d6ddb3d0-1f03-49b1-a1a1-c78918b6a273	c642e2ad-b8af-4220-bdcd-fd3bd5940af2	+7(383)123-45-67	+7(383)123-45-67	f	f	2026-06-07 18:43:54.287426+03
a1571247-1eb6-404f-8a33-cbf55e66e42f	2fcab39c-aee5-48a2-8c43-0e3289dbd4ed	f6b14271-a876-4443-b924-20a6f2fe3b5b	d.romanova.example.ru	d.romanova.example.ru	t	f	2026-06-07 18:43:54.287426+03
c9be3d4d-e7d9-4b74-b77c-60296d3e240b	2fcab39c-aee5-48a2-8c43-0e3289dbd4ed	c642e2ad-b8af-4220-bdcd-fd3bd5940af2	+7 495 777 88 99	+7 495 777 88 99	f	f	2026-06-07 18:43:54.287426+03
752589ee-1321-482c-a239-4d11d4b17a24	fbe544b5-469e-424d-bbb1-9b2fd820694a	f6b14271-a876-4443-b924-20a6f2fe3b5b	max.g@example.ru	max.g@example.ru, gavrilov.max@mail.ru	t	t	2026-06-07 18:43:54.287426+03
e70098ca-e0b9-4984-ae2a-485df793835b	fbe544b5-469e-424d-bbb1-9b2fd820694a	c642e2ad-b8af-4220-bdcd-fd3bd5940af2	8 800 555 35 35	8 800 555 35 35	f	f	2026-06-07 18:43:54.287426+03
37a67df3-d597-48f5-b5f8-2897c0add2ef	acd35a49-f817-4252-88f4-611194a195f1	f6b14271-a876-4443-b924-20a6f2fe3b5b	v.egorova@example.ru	v.egorova@example.ru	t	t	2026-06-07 18:43:54.287426+03
c5073444-ed60-44eb-95c1-8d15ec4a5aa4	acd35a49-f817-4252-88f4-611194a195f1	c642e2ad-b8af-4220-bdcd-fd3bd5940af2	+7-917-111-22-33	+7-917-111-22-33	f	f	2026-06-07 18:43:54.287426+03
2ba00cec-d5bf-4d09-b994-72242164b2e6	48e18473-6d22-42fa-8df8-042be293eaab	f6b14271-a876-4443-b924-20a6f2fe3b5b	s.pavlov@example.ru	s.pavlov@example.ru	t	t	2026-06-07 18:43:54.287426+03
a6d10510-4ce1-4cc5-93df-3364a7c9c01f	48e18473-6d22-42fa-8df8-042be293eaab	c642e2ad-b8af-4220-bdcd-fd3bd5940af2	89161231212	89161231212	f	f	2026-06-07 18:43:54.287426+03
25f33c48-b45d-4158-927f-c1f019473f27	3a132bab-0588-4f51-b527-4491f0e007eb	f6b14271-a876-4443-b924-20a6f2fe3b5b	ks.fomina@example.ru	ks.fomina@example.ru; k.fomina@old.ru	t	t	2026-06-07 18:43:54.287426+03
b4507f8a-aa26-40ef-a5d2-3ee8bbaf767e	3a132bab-0588-4f51-b527-4491f0e007eb	c642e2ad-b8af-4220-bdcd-fd3bd5940af2	+7 921 000 11 22	+7 921 000 11 22	f	f	2026-06-07 18:43:54.287426+03
7b7fcdfc-83f3-420c-bcbe-a52258d1eea9	e339c5c8-853e-4e80-a8bd-065bb83c7285	f6b14271-a876-4443-b924-20a6f2fe3b5b	matvey.b@example.ru	matvey.b@example.ru	t	t	2026-06-07 18:43:54.287426+03
5706ce02-945d-4f1c-9f43-3093019f2539	e339c5c8-853e-4e80-a8bd-065bb83c7285	c642e2ad-b8af-4220-bdcd-fd3bd5940af2	+7 999 010 20 30	+7 999 010 20 30	f	f	2026-06-07 18:43:54.287426+03
c405834a-defe-4e1b-be65-6bf988d4a019	6888527f-634d-496f-b96b-444793bca565	f6b14271-a876-4443-b924-20a6f2fe3b5b	n.solovieva@example.ru	n.solovieva@example.ru	t	t	2026-06-07 18:43:54.287426+03
912ff467-63a1-459b-9739-636b463ad47e	6888527f-634d-496f-b96b-444793bca565	c642e2ad-b8af-4220-bdcd-fd3bd5940af2	+7 903 444 55 66	+7 903 444 55 66	f	f	2026-06-07 18:43:54.287426+03
837f9b4c-b044-41e3-b901-4200be4d10f3	5dfc38a2-3795-49df-aef6-32027b71786a	f6b14271-a876-4443-b924-20a6f2fe3b5b	ars.titov@example.ru	ars.titov@example.ru	t	t	2026-06-07 18:43:54.287426+03
abc1834a-9708-43c1-a304-c4e2bc189be0	5dfc38a2-3795-49df-aef6-32027b71786a	c642e2ad-b8af-4220-bdcd-fd3bd5940af2	8(901)234-56-78	8(901)234-56-78	f	f	2026-06-07 18:43:54.287426+03
9488873f-d28a-4858-bfb7-2222d32273d4	8dd81453-964f-4b8b-8249-d7ef8b9d1a0f	f6b14271-a876-4443-b924-20a6f2fe3b5b	alina.m@example.ru	alina.m@example.ru	t	t	2026-06-07 18:43:54.287426+03
659c4cb6-ad1b-4fd3-9100-f6c5da03441f	8dd81453-964f-4b8b-8249-d7ef8b9d1a0f	c642e2ad-b8af-4220-bdcd-fd3bd5940af2	+79269998877	+79269998877	f	f	2026-06-07 18:43:54.287426+03
b40e5bea-fa32-4bad-ba7e-54f56ccd47a4	c4e8c4b9-3232-445f-8631-0783f78362c4	f6b14271-a876-4443-b924-20a6f2fe3b5b	fedorkrylov.mail.ru	fedorkrylov.mail.ru	t	f	2026-06-07 18:43:54.287426+03
9c686c4b-7360-4f43-84f0-4b36a6f7f14b	c4e8c4b9-3232-445f-8631-0783f78362c4	c642e2ad-b8af-4220-bdcd-fd3bd5940af2	+79123456789	+79123456789	f	f	2026-06-07 18:43:54.287426+03
40c842ef-22a3-451e-a417-30d2714609ef	128537da-acbe-48cb-8c24-059585840c3a	f6b14271-a876-4443-b924-20a6f2fe3b5b	m.zueva@example.ru	m.zueva@example.ru, marina.zueva@work.ru	t	t	2026-06-07 18:43:54.287426+03
7aba0f84-24f1-4dc7-93e0-d20e02a61e33	128537da-acbe-48cb-8c24-059585840c3a	c642e2ad-b8af-4220-bdcd-fd3bd5940af2	8 800 333 44 55	8 800 333 44 55	f	f	2026-06-07 18:43:54.287426+03
2c53a82c-6ecd-4e84-bc9d-4872e34fdccf	654b993d-15aa-4818-b3b0-546b617fccaf	f6b14271-a876-4443-b924-20a6f2fe3b5b	anton.k@example.ru	anton.k@example.ru	t	t	2026-06-07 18:43:54.287426+03
0923fdc8-f9b0-4353-b44e-95f1bc07cdeb	654b993d-15aa-4818-b3b0-546b617fccaf	c642e2ad-b8af-4220-bdcd-fd3bd5940af2	+74951234567	+74951234567	f	f	2026-06-07 18:43:54.287426+03
b0c0f31f-5630-4b7c-b79d-79f98fbaf90c	8a966ced-9c88-4e2b-a33d-3ae11f90d634	f6b14271-a876-4443-b924-20a6f2fe3b5b	y.makarova@example.ru	y.makarova@example.ru	t	t	2026-06-07 18:43:54.287426+03
224fd000-cb1d-4806-b24b-1d141799d87b	8a966ced-9c88-4e2b-a33d-3ae11f90d634	c642e2ad-b8af-4220-bdcd-fd3bd5940af2	+7(863)222-33-44	+7(863)222-33-44	f	f	2026-06-07 18:43:54.287426+03
0275ef5a-684c-4ea4-96a5-ab38b1b017ee	4b933d43-d401-47ad-aba2-fdfb2a2a9a19	f6b14271-a876-4443-b924-20a6f2fe3b5b	lev.d@example.ru	lev.d@example.ru	t	t	2026-06-07 18:43:54.287426+03
9e5f37f9-e371-4cb2-983d-92a89c08cae3	4b933d43-d401-47ad-aba2-fdfb2a2a9a19	c642e2ad-b8af-4220-bdcd-fd3bd5940af2	+7 812 333 44 56	+7 812 333 44 56	f	f	2026-06-07 18:43:54.287426+03
32bfcb07-66f8-4909-b614-dfe59bcd7f91	2ec9874b-8451-410b-9c20-d32657874d3e	f6b14271-a876-4443-b924-20a6f2fe3b5b	s.borisova@example.ru	s.borisova@example.ru	t	t	2026-06-07 18:43:54.287426+03
cd1d18a8-c865-4658-8407-19385087a478	2ec9874b-8451-410b-9c20-d32657874d3e	c642e2ad-b8af-4220-bdcd-fd3bd5940af2	8-926-123-45-67	8-926-123-45-67	f	f	2026-06-07 18:43:54.287426+03
\.


--
-- Data for Name: user_verification_document; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_verification_document (document_id, person_id, document_type_id, series, number, issue_date, issue_date_raw, issued_by, raw_document_text, verification_status_id) FROM stdin;
446c90f3-b07d-4f84-8909-db81458440ff	5aa70819-ca66-4c8a-a9b4-1fbac516f7df	e1076ae9-c58c-4747-abc4-04d5db1be6ff	4510	123456	2018-02-10	10.02.2018	ОВД Тверского района	4510 123456 выдан ОВД Тверского района 10.02.2018	29365f47-4486-4f29-a71f-155dfec65fda
90b69397-64c9-4311-98d1-94fb203e9048	63bc9c20-2072-4f09-91a7-9b9397a30a7e	6d30335b-310a-4773-9334-c2998be8fdd5	77AA	654321	2019-03-15	2019-03-15	ГИБДД Москва	ВУ 77AA 654321 от 2019-03-15	99230a4b-b83c-4e04-8e5c-d105c57c8e96
68de60f3-7595-47cc-9c4c-648068dbe4d5	855bc0e4-82c8-41f6-a813-b7e6ee7e8a23	e1076ae9-c58c-4747-abc4-04d5db1be6ff	4012	777888	2016-03-20	20 марта 2016 года	ТП №1	паспорт 4012 777888 кем и когда выдан: ТП №1 20 марта 2016 года	7e64b7b1-888e-4784-bb82-4c967d38a974
a1f74d6a-9704-46fe-be6f-f2651d1b0f05	b799f78d-4fe9-4b37-b960-403b8a99c75b	10a2c426-fffa-48cb-ae42-21f6ff3182c2	МК	009988	2020-01-01	01.01.20	военкомат	МК 009988 военкомат 01.01.20	a3a23832-503b-410d-b105-adebbeb8cb73
5f291e49-4633-446a-af1c-f9fcdde0bdb0	fbeb1c48-3620-4ecf-b8a1-bf4a27cf16b4	e1076ae9-c58c-4747-abc4-04d5db1be6ff	4513	500111	2013-04-10	10.04.2013	ОВД района	паспорт одной строкой: серия 4513 номер 500111	7e64b7b1-888e-4784-bb82-4c967d38a974
c9fbcf29-3ada-4a4b-9aa8-b1564394a66e	2fcab39c-aee5-48a2-8c43-0e3289dbd4ed	e1076ae9-c58c-4747-abc4-04d5db1be6ff	4516	500222	2016-07-10	10.07.2016	ОВД района	паспорт одной строкой: серия 4516 номер 500222	7e64b7b1-888e-4784-bb82-4c967d38a974
afef2bf5-8460-454d-87fd-c797e714a144	48e18473-6d22-42fa-8df8-042be293eaab	e1076ae9-c58c-4747-abc4-04d5db1be6ff	4519	500333	2019-02-10	10.02.2019	ОВД района	паспорт одной строкой: серия 4519 номер 500333	7e64b7b1-888e-4784-bb82-4c967d38a974
57097222-90d1-489f-92ef-de1591ced6d6	6888527f-634d-496f-b96b-444793bca565	e1076ae9-c58c-4747-abc4-04d5db1be6ff	4522	500444	2012-05-10	10.05.2012	ОВД района	паспорт одной строкой: серия 4522 номер 500444	7e64b7b1-888e-4784-bb82-4c967d38a974
6d0c96e6-cdc3-4a67-abbf-19e9b9fe8052	c4e8c4b9-3232-445f-8631-0783f78362c4	e1076ae9-c58c-4747-abc4-04d5db1be6ff	4525	500555	2015-08-10	10.08.2015	ОВД района	паспорт одной строкой: серия 4525 номер 500555	7e64b7b1-888e-4784-bb82-4c967d38a974
cdb2832e-3408-40bf-8ebb-3ce6e1499ae9	8a966ced-9c88-4e2b-a33d-3ae11f90d634	e1076ae9-c58c-4747-abc4-04d5db1be6ff	4528	500666	2018-03-10	10.03.2018	ОВД района	паспорт одной строкой: серия 4528 номер 500666	7e64b7b1-888e-4784-bb82-4c967d38a974
\.


--
-- Name: dict_account_status dict_account_status_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dict_account_status
    ADD CONSTRAINT dict_account_status_code_key UNIQUE (code);


--
-- Name: dict_account_status dict_account_status_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dict_account_status
    ADD CONSTRAINT dict_account_status_pkey PRIMARY KEY (account_status_id);


--
-- Name: dict_address_type dict_address_type_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dict_address_type
    ADD CONSTRAINT dict_address_type_code_key UNIQUE (code);


--
-- Name: dict_address_type dict_address_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dict_address_type
    ADD CONSTRAINT dict_address_type_pkey PRIMARY KEY (address_type_id);


--
-- Name: dict_city dict_city_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dict_city
    ADD CONSTRAINT dict_city_pkey PRIMARY KEY (city_id);


--
-- Name: dict_city dict_city_region_id_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dict_city
    ADD CONSTRAINT dict_city_region_id_name_key UNIQUE (region_id, name);


--
-- Name: dict_consent_type dict_consent_type_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dict_consent_type
    ADD CONSTRAINT dict_consent_type_code_key UNIQUE (code);


--
-- Name: dict_consent_type dict_consent_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dict_consent_type
    ADD CONSTRAINT dict_consent_type_pkey PRIMARY KEY (consent_type_id);


--
-- Name: dict_contact_type dict_contact_type_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dict_contact_type
    ADD CONSTRAINT dict_contact_type_code_key UNIQUE (code);


--
-- Name: dict_contact_type dict_contact_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dict_contact_type
    ADD CONSTRAINT dict_contact_type_pkey PRIMARY KEY (contact_type_id);


--
-- Name: dict_country dict_country_iso_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dict_country
    ADD CONSTRAINT dict_country_iso_code_key UNIQUE (iso_code);


--
-- Name: dict_country dict_country_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dict_country
    ADD CONSTRAINT dict_country_name_key UNIQUE (name);


--
-- Name: dict_country dict_country_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dict_country
    ADD CONSTRAINT dict_country_pkey PRIMARY KEY (country_id);


--
-- Name: dict_document_type dict_document_type_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dict_document_type
    ADD CONSTRAINT dict_document_type_code_key UNIQUE (code);


--
-- Name: dict_document_type dict_document_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dict_document_type
    ADD CONSTRAINT dict_document_type_pkey PRIMARY KEY (document_type_id);


--
-- Name: dict_gender dict_gender_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dict_gender
    ADD CONSTRAINT dict_gender_code_key UNIQUE (code);


--
-- Name: dict_gender dict_gender_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dict_gender
    ADD CONSTRAINT dict_gender_pkey PRIMARY KEY (gender_id);


--
-- Name: dict_identifier_type dict_identifier_type_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dict_identifier_type
    ADD CONSTRAINT dict_identifier_type_code_key UNIQUE (code);


--
-- Name: dict_identifier_type dict_identifier_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dict_identifier_type
    ADD CONSTRAINT dict_identifier_type_pkey PRIMARY KEY (identifier_type_id);


--
-- Name: dict_region dict_region_country_id_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dict_region
    ADD CONSTRAINT dict_region_country_id_name_key UNIQUE (country_id, name);


--
-- Name: dict_region dict_region_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dict_region
    ADD CONSTRAINT dict_region_pkey PRIMARY KEY (region_id);


--
-- Name: dict_street dict_street_city_id_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dict_street
    ADD CONSTRAINT dict_street_city_id_name_key UNIQUE (city_id, name);


--
-- Name: dict_street dict_street_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dict_street
    ADD CONSTRAINT dict_street_pkey PRIMARY KEY (street_id);


--
-- Name: dict_verification_status dict_verification_status_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dict_verification_status
    ADD CONSTRAINT dict_verification_status_code_key UNIQUE (code);


--
-- Name: dict_verification_status dict_verification_status_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dict_verification_status
    ADD CONSTRAINT dict_verification_status_pkey PRIMARY KEY (verification_status_id);


--
-- Name: person_identifier person_identifier_identifier_type_id_identifier_value_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.person_identifier
    ADD CONSTRAINT person_identifier_identifier_type_id_identifier_value_key UNIQUE (identifier_type_id, identifier_value);


--
-- Name: person_identifier person_identifier_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.person_identifier
    ADD CONSTRAINT person_identifier_pkey PRIMARY KEY (identifier_id);


--
-- Name: person_profile person_profile_last_name_first_name_middle_name_birth_date_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.person_profile
    ADD CONSTRAINT person_profile_last_name_first_name_middle_name_birth_date_key UNIQUE (last_name, first_name, middle_name, birth_date);


--
-- Name: person_profile person_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.person_profile
    ADD CONSTRAINT person_profile_pkey PRIMARY KEY (person_id);


--
-- Name: user_account user_account_login_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_account
    ADD CONSTRAINT user_account_login_key UNIQUE (login);


--
-- Name: user_account user_account_person_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_account
    ADD CONSTRAINT user_account_person_id_key UNIQUE (person_id);


--
-- Name: user_account user_account_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_account
    ADD CONSTRAINT user_account_pkey PRIMARY KEY (account_id);


--
-- Name: user_address user_address_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_address
    ADD CONSTRAINT user_address_pkey PRIMARY KEY (address_id);


--
-- Name: user_attribute_type user_attribute_type_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_attribute_type
    ADD CONSTRAINT user_attribute_type_code_key UNIQUE (code);


--
-- Name: user_attribute_type user_attribute_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_attribute_type
    ADD CONSTRAINT user_attribute_type_pkey PRIMARY KEY (attribute_type_id);


--
-- Name: user_attribute_value user_attribute_value_person_id_attribute_type_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_attribute_value
    ADD CONSTRAINT user_attribute_value_person_id_attribute_type_id_key UNIQUE (person_id, attribute_type_id);


--
-- Name: user_attribute_value user_attribute_value_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_attribute_value
    ADD CONSTRAINT user_attribute_value_pkey PRIMARY KEY (attribute_value_id);


--
-- Name: user_consent user_consent_person_id_consent_type_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_consent
    ADD CONSTRAINT user_consent_person_id_consent_type_id_key UNIQUE (person_id, consent_type_id);


--
-- Name: user_consent user_consent_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_consent
    ADD CONSTRAINT user_consent_pkey PRIMARY KEY (consent_id);


--
-- Name: user_contact user_contact_person_id_contact_type_id_contact_value_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_contact
    ADD CONSTRAINT user_contact_person_id_contact_type_id_contact_value_key UNIQUE (person_id, contact_type_id, contact_value);


--
-- Name: user_contact user_contact_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_contact
    ADD CONSTRAINT user_contact_pkey PRIMARY KEY (contact_id);


--
-- Name: user_verification_document user_verification_document_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_verification_document
    ADD CONSTRAINT user_verification_document_pkey PRIMARY KEY (document_id);


--
-- Name: person_profile_natural_uidx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX person_profile_natural_uidx ON public.person_profile USING btree (lower(last_name), lower(first_name), COALESCE(lower(middle_name), ''::text), birth_date) WHERE (birth_date IS NOT NULL);


--
-- Name: user_address_dedupe_uidx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX user_address_dedupe_uidx ON public.user_address USING btree (person_id, address_type_id, COALESCE(country_id, '00000000-0000-0000-0000-000000000000'::uuid), COALESCE(region_id, '00000000-0000-0000-0000-000000000000'::uuid), COALESCE(city_id, '00000000-0000-0000-0000-000000000000'::uuid), COALESCE(street_id, '00000000-0000-0000-0000-000000000000'::uuid), COALESCE(house, ''::text), COALESCE(building, ''::text), COALESCE(flat, ''::text), COALESCE(postal_code, ''::text), COALESCE(raw_address, ''::text));


--
-- Name: user_verification_document_dedupe_uidx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX user_verification_document_dedupe_uidx ON public.user_verification_document USING btree (person_id, document_type_id, COALESCE(series, ''::text), COALESCE(number, ''::text), COALESCE(raw_document_text, ''::text));


--
-- Name: dict_city dict_city_region_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dict_city
    ADD CONSTRAINT dict_city_region_id_fkey FOREIGN KEY (region_id) REFERENCES public.dict_region(region_id);


--
-- Name: dict_region dict_region_country_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dict_region
    ADD CONSTRAINT dict_region_country_id_fkey FOREIGN KEY (country_id) REFERENCES public.dict_country(country_id);


--
-- Name: dict_street dict_street_city_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dict_street
    ADD CONSTRAINT dict_street_city_id_fkey FOREIGN KEY (city_id) REFERENCES public.dict_city(city_id);


--
-- Name: person_identifier person_identifier_identifier_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.person_identifier
    ADD CONSTRAINT person_identifier_identifier_type_id_fkey FOREIGN KEY (identifier_type_id) REFERENCES public.dict_identifier_type(identifier_type_id);


--
-- Name: person_identifier person_identifier_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.person_identifier
    ADD CONSTRAINT person_identifier_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person_profile(person_id) ON DELETE CASCADE;


--
-- Name: person_profile person_profile_gender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.person_profile
    ADD CONSTRAINT person_profile_gender_id_fkey FOREIGN KEY (gender_id) REFERENCES public.dict_gender(gender_id);


--
-- Name: user_account user_account_account_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_account
    ADD CONSTRAINT user_account_account_status_id_fkey FOREIGN KEY (account_status_id) REFERENCES public.dict_account_status(account_status_id);


--
-- Name: user_account user_account_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_account
    ADD CONSTRAINT user_account_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person_profile(person_id) ON DELETE CASCADE;


--
-- Name: user_address user_address_address_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_address
    ADD CONSTRAINT user_address_address_type_id_fkey FOREIGN KEY (address_type_id) REFERENCES public.dict_address_type(address_type_id);


--
-- Name: user_address user_address_city_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_address
    ADD CONSTRAINT user_address_city_id_fkey FOREIGN KEY (city_id) REFERENCES public.dict_city(city_id);


--
-- Name: user_address user_address_country_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_address
    ADD CONSTRAINT user_address_country_id_fkey FOREIGN KEY (country_id) REFERENCES public.dict_country(country_id);


--
-- Name: user_address user_address_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_address
    ADD CONSTRAINT user_address_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person_profile(person_id) ON DELETE CASCADE;


--
-- Name: user_address user_address_region_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_address
    ADD CONSTRAINT user_address_region_id_fkey FOREIGN KEY (region_id) REFERENCES public.dict_region(region_id);


--
-- Name: user_address user_address_street_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_address
    ADD CONSTRAINT user_address_street_id_fkey FOREIGN KEY (street_id) REFERENCES public.dict_street(street_id);


--
-- Name: user_attribute_value user_attribute_value_attribute_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_attribute_value
    ADD CONSTRAINT user_attribute_value_attribute_type_id_fkey FOREIGN KEY (attribute_type_id) REFERENCES public.user_attribute_type(attribute_type_id);


--
-- Name: user_attribute_value user_attribute_value_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_attribute_value
    ADD CONSTRAINT user_attribute_value_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person_profile(person_id) ON DELETE CASCADE;


--
-- Name: user_consent user_consent_consent_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_consent
    ADD CONSTRAINT user_consent_consent_type_id_fkey FOREIGN KEY (consent_type_id) REFERENCES public.dict_consent_type(consent_type_id);


--
-- Name: user_consent user_consent_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_consent
    ADD CONSTRAINT user_consent_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person_profile(person_id) ON DELETE CASCADE;


--
-- Name: user_contact user_contact_contact_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_contact
    ADD CONSTRAINT user_contact_contact_type_id_fkey FOREIGN KEY (contact_type_id) REFERENCES public.dict_contact_type(contact_type_id);


--
-- Name: user_contact user_contact_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_contact
    ADD CONSTRAINT user_contact_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person_profile(person_id) ON DELETE CASCADE;


--
-- Name: user_verification_document user_verification_document_document_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_verification_document
    ADD CONSTRAINT user_verification_document_document_type_id_fkey FOREIGN KEY (document_type_id) REFERENCES public.dict_document_type(document_type_id);


--
-- Name: user_verification_document user_verification_document_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_verification_document
    ADD CONSTRAINT user_verification_document_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person_profile(person_id) ON DELETE CASCADE;


--
-- Name: user_verification_document user_verification_document_verification_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_verification_document
    ADD CONSTRAINT user_verification_document_verification_status_id_fkey FOREIGN KEY (verification_status_id) REFERENCES public.dict_verification_status(verification_status_id);


--
-- PostgreSQL database dump complete
--

\unrestrict h3GICmJvipwU0wwgPhdG2918b6KZH6Pfg2paRV5g7nkDNlst7EjafX0qhTr5mPL

