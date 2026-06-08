--
-- PostgreSQL database dump
--

\restrict yRAjiEEqBb7LDDcPTb2hBxD3ddt9cG6VlOQDPsgkMzmSva802HVRcgkzWNfW2vI

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

DROP DATABASE IF EXISTS migration_error_demo;
--
-- Name: migration_error_demo; Type: DATABASE; Schema: -; Owner: yui
--

CREATE DATABASE migration_error_demo WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'C.UTF-8';


ALTER DATABASE migration_error_demo OWNER TO yui;

\unrestrict yRAjiEEqBb7LDDcPTb2hBxD3ddt9cG6VlOQDPsgkMzmSva802HVRcgkzWNfW2vI
\connect migration_error_demo
\restrict yRAjiEEqBb7LDDcPTb2hBxD3ddt9cG6VlOQDPsgkMzmSva802HVRcgkzWNfW2vI

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
-- Name: map; Type: SCHEMA; Schema: -; Owner: yui
--

CREATE SCHEMA map;


ALTER SCHEMA map OWNER TO yui;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: attribute_code(text, text); Type: FUNCTION; Schema: map; Owner: yui
--

CREATE FUNCTION map.attribute_code(p_name text, p_value text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
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


ALTER FUNCTION map.attribute_code(p_name text, p_value text) OWNER TO yui;

--
-- Name: attribute_value(text, text); Type: FUNCTION; Schema: map; Owner: yui
--

CREATE FUNCTION map.attribute_value(p_code text, p_value text) RETURNS jsonb
    LANGUAGE plpgsql IMMUTABLE
    AS $$
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


ALTER FUNCTION map.attribute_value(p_code text, p_value text) OWNER TO yui;

--
-- Name: city_normalized(text); Type: FUNCTION; Schema: map; Owner: yui
--

CREATE FUNCTION map.city_normalized(p_city text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
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


ALTER FUNCTION map.city_normalized(p_city text) OWNER TO yui;

--
-- Name: document_issue_date_raw(text); Type: FUNCTION; Schema: map; Owner: yui
--

CREATE FUNCTION map.document_issue_date_raw(p_doc_data text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
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


ALTER FUNCTION map.document_issue_date_raw(p_doc_data text) OWNER TO yui;

--
-- Name: document_number(text); Type: FUNCTION; Schema: map; Owner: yui
--

CREATE FUNCTION map.document_number(p_doc_data text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
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


ALTER FUNCTION map.document_number(p_doc_data text) OWNER TO yui;

--
-- Name: document_series(text); Type: FUNCTION; Schema: map; Owner: yui
--

CREATE FUNCTION map.document_series(p_doc_data text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
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


ALTER FUNCTION map.document_series(p_doc_data text) OWNER TO yui;

--
-- Name: email_array(text); Type: FUNCTION; Schema: map; Owner: yui
--

CREATE FUNCTION map.email_array(p_value text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $$
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


ALTER FUNCTION map.email_array(p_value text) OWNER TO yui;

--
-- Name: flat_from_address(text); Type: FUNCTION; Schema: map; Owner: yui
--

CREATE FUNCTION map.flat_from_address(p_address text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
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


ALTER FUNCTION map.flat_from_address(p_address text) OWNER TO yui;

--
-- Name: house_from_address(text); Type: FUNCTION; Schema: map; Owner: yui
--

CREATE FUNCTION map.house_from_address(p_address text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
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


ALTER FUNCTION map.house_from_address(p_address text) OWNER TO yui;

--
-- Name: map_account_status_code(text); Type: FUNCTION; Schema: map; Owner: yui
--

CREATE FUNCTION map.map_account_status_code(p_value text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
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


ALTER FUNCTION map.map_account_status_code(p_value text) OWNER TO yui;

--
-- Name: map_address_type_code(text); Type: FUNCTION; Schema: map; Owner: yui
--

CREATE FUNCTION map.map_address_type_code(p_value text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
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


ALTER FUNCTION map.map_address_type_code(p_value text) OWNER TO yui;

--
-- Name: map_consent_type_code(text); Type: FUNCTION; Schema: map; Owner: yui
--

CREATE FUNCTION map.map_consent_type_code(p_value text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
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


ALTER FUNCTION map.map_consent_type_code(p_value text) OWNER TO yui;

--
-- Name: map_document_type_code(text); Type: FUNCTION; Schema: map; Owner: yui
--

CREATE FUNCTION map.map_document_type_code(p_value text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
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


ALTER FUNCTION map.map_document_type_code(p_value text) OWNER TO yui;

--
-- Name: map_gender_code(text); Type: FUNCTION; Schema: map; Owner: yui
--

CREATE FUNCTION map.map_gender_code(p_value text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
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


ALTER FUNCTION map.map_gender_code(p_value text) OWNER TO yui;

--
-- Name: migrate_partner_customers(uuid); Type: FUNCTION; Schema: map; Owner: yui
--

CREATE FUNCTION map.migrate_partner_customers(p_migration_run_id uuid DEFAULT gen_random_uuid()) RETURNS uuid
    LANGUAGE plpgsql
    AS $_$
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
$_$;


ALTER FUNCTION map.migrate_partner_customers(p_migration_run_id uuid) OWNER TO yui;

--
-- Name: parse_bool(text); Type: FUNCTION; Schema: map; Owner: yui
--

CREATE FUNCTION map.parse_bool(p_value text) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
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


ALTER FUNCTION map.parse_bool(p_value text) OWNER TO yui;

--
-- Name: phone_contacts(text, text); Type: FUNCTION; Schema: map; Owner: yui
--

CREATE FUNCTION map.phone_contacts(p_phone text, p_phone2 text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $$
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


ALTER FUNCTION map.phone_contacts(p_phone text, p_phone2 text) OWNER TO yui;

--
-- Name: region_by_city(text); Type: FUNCTION; Schema: map; Owner: yui
--

CREATE FUNCTION map.region_by_city(p_city text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
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


ALTER FUNCTION map.region_by_city(p_city text) OWNER TO yui;

--
-- Name: split_full_name(text); Type: FUNCTION; Schema: map; Owner: yui
--

CREATE FUNCTION map.split_full_name(p_full_name text, OUT last_name text, OUT first_name text, OUT middle_name text) RETURNS record
    LANGUAGE plpgsql IMMUTABLE
    AS $$
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


ALTER FUNCTION map.split_full_name(p_full_name text, OUT last_name text, OUT first_name text, OUT middle_name text) OWNER TO yui;

--
-- Name: street_from_address(text); Type: FUNCTION; Schema: map; Owner: yui
--

CREATE FUNCTION map.street_from_address(p_address text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $_$
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
$_$;


ALTER FUNCTION map.street_from_address(p_address text) OWNER TO yui;

--
-- Name: add_customer_address(uuid, text, text, text, text, text, text, text, text, text, text, boolean); Type: FUNCTION; Schema: public; Owner: yui
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


ALTER FUNCTION public.add_customer_address(p_person_id uuid, p_address_type_code text, p_country_name text, p_region_name text, p_city_name text, p_street_name text, p_house text, p_building text, p_flat text, p_postal_code text, p_raw_address text, p_is_default boolean) OWNER TO yui;

--
-- Name: add_customer_consent(uuid, text, boolean, timestamp with time zone, timestamp with time zone, text, text); Type: FUNCTION; Schema: public; Owner: yui
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


ALTER FUNCTION public.add_customer_consent(p_person_id uuid, p_consent_type_code text, p_is_granted boolean, p_granted_at timestamp with time zone, p_revoked_at timestamp with time zone, p_source text, p_raw_value text) OWNER TO yui;

--
-- Name: add_customer_contact(uuid, text, text, text, boolean, boolean); Type: FUNCTION; Schema: public; Owner: yui
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


ALTER FUNCTION public.add_customer_contact(p_person_id uuid, p_contact_type_code text, p_contact_value text, p_raw_value text, p_is_primary boolean, p_is_verified boolean) OWNER TO yui;

--
-- Name: add_customer_document(uuid, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: yui
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


ALTER FUNCTION public.add_customer_document(p_person_id uuid, p_document_type_code text, p_series text, p_number text, p_issue_date_raw text, p_issued_by text, p_raw_document_text text, p_verification_status_code text) OWNER TO yui;

--
-- Name: add_customer_identifier(uuid, text, text, text, boolean); Type: FUNCTION; Schema: public; Owner: yui
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


ALTER FUNCTION public.add_customer_identifier(p_person_id uuid, p_identifier_type_code text, p_identifier_value text, p_raw_value text, p_is_verified boolean) OWNER TO yui;

--
-- Name: create_marketplace_customer(text, text, text, text, text, text, text, text, jsonb, jsonb, jsonb, jsonb, jsonb, jsonb); Type: FUNCTION; Schema: public; Owner: yui
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


ALTER FUNCTION public.create_marketplace_customer(p_last_name text, p_first_name text, p_login text, p_middle_name text, p_birth_date_raw text, p_gender_code text, p_password_hash text, p_account_status_code text, p_contacts jsonb, p_addresses jsonb, p_identifiers jsonb, p_documents jsonb, p_consents jsonb, p_attributes jsonb) OWNER TO yui;

--
-- Name: find_marketplace_customer(text, text, text, text, text, jsonb, jsonb); Type: FUNCTION; Schema: public; Owner: yui
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


ALTER FUNCTION public.find_marketplace_customer(p_last_name text, p_first_name text, p_middle_name text, p_birth_date_raw text, p_login text, p_contacts jsonb, p_identifiers jsonb) OWNER TO yui;

--
-- Name: get_account_status_id(text); Type: FUNCTION; Schema: public; Owner: yui
--

CREATE FUNCTION public.get_account_status_id(p_code text) RETURNS uuid
    LANGUAGE sql STABLE
    AS $$
    select account_status_id
    from dict_account_status
    where code = coalesce(normalize_code(p_code), 'ACTIVE')
$$;


ALTER FUNCTION public.get_account_status_id(p_code text) OWNER TO yui;

--
-- Name: get_gender_id(text); Type: FUNCTION; Schema: public; Owner: yui
--

CREATE FUNCTION public.get_gender_id(p_code text) RETURNS uuid
    LANGUAGE sql STABLE
    AS $$
    select gender_id
    from dict_gender
    where code = coalesce(normalize_code(p_code), 'UNKNOWN')
$$;


ALTER FUNCTION public.get_gender_id(p_code text) OWNER TO yui;

--
-- Name: normalize_code(text); Type: FUNCTION; Schema: public; Owner: yui
--

CREATE FUNCTION public.normalize_code(p_value text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
    select nullif(upper(trim(p_value)), '')
$$;


ALTER FUNCTION public.normalize_code(p_value text) OWNER TO yui;

--
-- Name: normalize_digits(text); Type: FUNCTION; Schema: public; Owner: yui
--

CREATE FUNCTION public.normalize_digits(p_value text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
    select nullif(regexp_replace(coalesce(p_value, ''), '\D', '', 'g'), '')
$$;


ALTER FUNCTION public.normalize_digits(p_value text) OWNER TO yui;

--
-- Name: parse_birth_date(text); Type: FUNCTION; Schema: public; Owner: yui
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


ALTER FUNCTION public.parse_birth_date(p_raw text) OWNER TO yui;

--
-- Name: set_customer_attribute(uuid, text, jsonb, text); Type: FUNCTION; Schema: public; Owner: yui
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


ALTER FUNCTION public.set_customer_attribute(p_person_id uuid, p_attribute_code text, p_value jsonb, p_raw_value text) OWNER TO yui;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: cust_addresses; Type: TABLE; Schema: map; Owner: yui
--

CREATE TABLE map.cust_addresses (
    addr_id integer NOT NULL,
    cust_id integer NOT NULL,
    addr_type character varying(50),
    address text,
    city character varying(100),
    zip_code character varying(20)
);


ALTER TABLE map.cust_addresses OWNER TO yui;

--
-- Name: cust_addresses_addr_id_seq; Type: SEQUENCE; Schema: map; Owner: yui
--

CREATE SEQUENCE map.cust_addresses_addr_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE map.cust_addresses_addr_id_seq OWNER TO yui;

--
-- Name: cust_addresses_addr_id_seq; Type: SEQUENCE OWNED BY; Schema: map; Owner: yui
--

ALTER SEQUENCE map.cust_addresses_addr_id_seq OWNED BY map.cust_addresses.addr_id;


--
-- Name: cust_consents; Type: TABLE; Schema: map; Owner: yui
--

CREATE TABLE map.cust_consents (
    consent_id integer NOT NULL,
    cust_id integer NOT NULL,
    consent_for character varying(100),
    agreed character varying(10),
    dt character varying(50)
);


ALTER TABLE map.cust_consents OWNER TO yui;

--
-- Name: cust_consents_consent_id_seq; Type: SEQUENCE; Schema: map; Owner: yui
--

CREATE SEQUENCE map.cust_consents_consent_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE map.cust_consents_consent_id_seq OWNER TO yui;

--
-- Name: cust_consents_consent_id_seq; Type: SEQUENCE OWNED BY; Schema: map; Owner: yui
--

ALTER SEQUENCE map.cust_consents_consent_id_seq OWNED BY map.cust_consents.consent_id;


--
-- Name: cust_docs; Type: TABLE; Schema: map; Owner: yui
--

CREATE TABLE map.cust_docs (
    doc_id integer NOT NULL,
    cust_id integer NOT NULL,
    doc_type character varying(50),
    doc_data text
);


ALTER TABLE map.cust_docs OWNER TO yui;

--
-- Name: cust_docs_doc_id_seq; Type: SEQUENCE; Schema: map; Owner: yui
--

CREATE SEQUENCE map.cust_docs_doc_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE map.cust_docs_doc_id_seq OWNER TO yui;

--
-- Name: cust_docs_doc_id_seq; Type: SEQUENCE OWNED BY; Schema: map; Owner: yui
--

ALTER SEQUENCE map.cust_docs_doc_id_seq OWNED BY map.cust_docs.doc_id;


--
-- Name: cust_extra; Type: TABLE; Schema: map; Owner: yui
--

CREATE TABLE map.cust_extra (
    extra_id integer NOT NULL,
    cust_id integer NOT NULL,
    param_name character varying(100),
    param_val text
);


ALTER TABLE map.cust_extra OWNER TO yui;

--
-- Name: cust_extra_extra_id_seq; Type: SEQUENCE; Schema: map; Owner: yui
--

CREATE SEQUENCE map.cust_extra_extra_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE map.cust_extra_extra_id_seq OWNER TO yui;

--
-- Name: cust_extra_extra_id_seq; Type: SEQUENCE OWNED BY; Schema: map; Owner: yui
--

ALTER SEQUENCE map.cust_extra_extra_id_seq OWNED BY map.cust_extra.extra_id;


--
-- Name: customers; Type: TABLE; Schema: map; Owner: yui
--

CREATE TABLE map.customers (
    cust_id integer NOT NULL,
    fullname character varying(300),
    birth_dt character varying(50),
    sex character varying(20),
    email character varying(500),
    phone character varying(50),
    phone2 character varying(50),
    inn character varying(30),
    snils character varying(30),
    marital character varying(50),
    loyalty_lvl character varying(50),
    login character varying(150),
    reg_date character varying(50),
    status character varying(30) DEFAULT 'активен'::character varying,
    notes text
);


ALTER TABLE map.customers OWNER TO yui;

--
-- Name: customers_cust_id_seq; Type: SEQUENCE; Schema: map; Owner: yui
--

CREATE SEQUENCE map.customers_cust_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE map.customers_cust_id_seq OWNER TO yui;

--
-- Name: customers_cust_id_seq; Type: SEQUENCE OWNED BY; Schema: map; Owner: yui
--

ALTER SEQUENCE map.customers_cust_id_seq OWNED BY map.customers.cust_id;


--
-- Name: migration_log; Type: TABLE; Schema: map; Owner: yui
--

CREATE TABLE map.migration_log (
    log_id uuid DEFAULT gen_random_uuid() NOT NULL,
    migration_run_id uuid NOT NULL,
    source_system text NOT NULL,
    source_record_id text,
    target_person_id uuid,
    status text NOT NULL,
    stage text NOT NULL,
    error_code text,
    error_message text,
    warning_messages text[],
    source_data jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT migration_log_status_check CHECK ((status = ANY (ARRAY['success'::text, 'warning'::text, 'error'::text, 'skipped'::text])))
);


ALTER TABLE map.migration_log OWNER TO yui;

--
-- Name: migration_person_link; Type: TABLE; Schema: map; Owner: yui
--

CREATE TABLE map.migration_person_link (
    link_id uuid DEFAULT gen_random_uuid() NOT NULL,
    migration_run_id uuid NOT NULL,
    source_system text NOT NULL,
    source_record_id text NOT NULL,
    target_person_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE map.migration_person_link OWNER TO yui;

--
-- Name: migration_unmapped_attribute; Type: TABLE; Schema: map; Owner: yui
--

CREATE TABLE map.migration_unmapped_attribute (
    unmapped_attribute_id uuid DEFAULT gen_random_uuid() NOT NULL,
    migration_run_id uuid NOT NULL,
    source_system text NOT NULL,
    source_record_id text NOT NULL,
    target_person_id uuid,
    source_field_name text NOT NULL,
    source_field_value text,
    reason text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE map.migration_unmapped_attribute OWNER TO yui;

--
-- Name: dict_account_status; Type: TABLE; Schema: public; Owner: yui
--

CREATE TABLE public.dict_account_status (
    account_status_id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL
);


ALTER TABLE public.dict_account_status OWNER TO yui;

--
-- Name: dict_address_type; Type: TABLE; Schema: public; Owner: yui
--

CREATE TABLE public.dict_address_type (
    address_type_id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL
);


ALTER TABLE public.dict_address_type OWNER TO yui;

--
-- Name: dict_city; Type: TABLE; Schema: public; Owner: yui
--

CREATE TABLE public.dict_city (
    city_id uuid DEFAULT gen_random_uuid() NOT NULL,
    region_id uuid NOT NULL,
    name text NOT NULL
);


ALTER TABLE public.dict_city OWNER TO yui;

--
-- Name: dict_consent_type; Type: TABLE; Schema: public; Owner: yui
--

CREATE TABLE public.dict_consent_type (
    consent_type_id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    description text
);


ALTER TABLE public.dict_consent_type OWNER TO yui;

--
-- Name: dict_contact_type; Type: TABLE; Schema: public; Owner: yui
--

CREATE TABLE public.dict_contact_type (
    contact_type_id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL
);


ALTER TABLE public.dict_contact_type OWNER TO yui;

--
-- Name: dict_country; Type: TABLE; Schema: public; Owner: yui
--

CREATE TABLE public.dict_country (
    country_id uuid DEFAULT gen_random_uuid() NOT NULL,
    iso_code text,
    name text NOT NULL
);


ALTER TABLE public.dict_country OWNER TO yui;

--
-- Name: dict_document_type; Type: TABLE; Schema: public; Owner: yui
--

CREATE TABLE public.dict_document_type (
    document_type_id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL
);


ALTER TABLE public.dict_document_type OWNER TO yui;

--
-- Name: dict_gender; Type: TABLE; Schema: public; Owner: yui
--

CREATE TABLE public.dict_gender (
    gender_id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL
);


ALTER TABLE public.dict_gender OWNER TO yui;

--
-- Name: dict_identifier_type; Type: TABLE; Schema: public; Owner: yui
--

CREATE TABLE public.dict_identifier_type (
    identifier_type_id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL
);


ALTER TABLE public.dict_identifier_type OWNER TO yui;

--
-- Name: dict_region; Type: TABLE; Schema: public; Owner: yui
--

CREATE TABLE public.dict_region (
    region_id uuid DEFAULT gen_random_uuid() NOT NULL,
    country_id uuid NOT NULL,
    name text NOT NULL
);


ALTER TABLE public.dict_region OWNER TO yui;

--
-- Name: dict_street; Type: TABLE; Schema: public; Owner: yui
--

CREATE TABLE public.dict_street (
    street_id uuid DEFAULT gen_random_uuid() NOT NULL,
    city_id uuid NOT NULL,
    name text NOT NULL
);


ALTER TABLE public.dict_street OWNER TO yui;

--
-- Name: dict_verification_status; Type: TABLE; Schema: public; Owner: yui
--

CREATE TABLE public.dict_verification_status (
    verification_status_id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL
);


ALTER TABLE public.dict_verification_status OWNER TO yui;

--
-- Name: person_identifier; Type: TABLE; Schema: public; Owner: yui
--

CREATE TABLE public.person_identifier (
    identifier_id uuid DEFAULT gen_random_uuid() NOT NULL,
    person_id uuid NOT NULL,
    identifier_type_id uuid NOT NULL,
    identifier_value text NOT NULL,
    raw_value text,
    is_verified boolean DEFAULT false NOT NULL
);


ALTER TABLE public.person_identifier OWNER TO yui;

--
-- Name: person_profile; Type: TABLE; Schema: public; Owner: yui
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


ALTER TABLE public.person_profile OWNER TO yui;

--
-- Name: user_account; Type: TABLE; Schema: public; Owner: yui
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


ALTER TABLE public.user_account OWNER TO yui;

--
-- Name: user_address; Type: TABLE; Schema: public; Owner: yui
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


ALTER TABLE public.user_address OWNER TO yui;

--
-- Name: user_attribute_type; Type: TABLE; Schema: public; Owner: yui
--

CREATE TABLE public.user_attribute_type (
    attribute_type_id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    value_type text NOT NULL,
    description text,
    CONSTRAINT user_attribute_type_value_type_check CHECK ((value_type = ANY (ARRAY['text'::text, 'number'::text, 'date'::text, 'bool'::text, 'json'::text])))
);


ALTER TABLE public.user_attribute_type OWNER TO yui;

--
-- Name: user_attribute_value; Type: TABLE; Schema: public; Owner: yui
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


ALTER TABLE public.user_attribute_value OWNER TO yui;

--
-- Name: user_consent; Type: TABLE; Schema: public; Owner: yui
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


ALTER TABLE public.user_consent OWNER TO yui;

--
-- Name: user_contact; Type: TABLE; Schema: public; Owner: yui
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


ALTER TABLE public.user_contact OWNER TO yui;

--
-- Name: user_verification_document; Type: TABLE; Schema: public; Owner: yui
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


ALTER TABLE public.user_verification_document OWNER TO yui;

--
-- Name: cust_addresses addr_id; Type: DEFAULT; Schema: map; Owner: yui
--

ALTER TABLE ONLY map.cust_addresses ALTER COLUMN addr_id SET DEFAULT nextval('map.cust_addresses_addr_id_seq'::regclass);


--
-- Name: cust_consents consent_id; Type: DEFAULT; Schema: map; Owner: yui
--

ALTER TABLE ONLY map.cust_consents ALTER COLUMN consent_id SET DEFAULT nextval('map.cust_consents_consent_id_seq'::regclass);


--
-- Name: cust_docs doc_id; Type: DEFAULT; Schema: map; Owner: yui
--

ALTER TABLE ONLY map.cust_docs ALTER COLUMN doc_id SET DEFAULT nextval('map.cust_docs_doc_id_seq'::regclass);


--
-- Name: cust_extra extra_id; Type: DEFAULT; Schema: map; Owner: yui
--

ALTER TABLE ONLY map.cust_extra ALTER COLUMN extra_id SET DEFAULT nextval('map.cust_extra_extra_id_seq'::regclass);


--
-- Name: customers cust_id; Type: DEFAULT; Schema: map; Owner: yui
--

ALTER TABLE ONLY map.customers ALTER COLUMN cust_id SET DEFAULT nextval('map.customers_cust_id_seq'::regclass);


--
-- Data for Name: cust_addresses; Type: TABLE DATA; Schema: map; Owner: yui
--

COPY map.cust_addresses (addr_id, cust_id, addr_type, address, city, zip_code) FROM stdin;
1	1	доставка	Каширское шоссе 34 кв. 128	Москва	115533
2	2	delivery	Кронверкский пр-т, 7, кв.14	СПб	197101
3	3	дом	Красный проспект 26/5	Новосибирск	630099
4	4	home	ул. Ленина 100, кв 55	Екатеринбург	620000
5	5	Адрес доставки	ул. Пушкина д. 10 кв. 35	Москва	125009
6	5	регистрация	Московская обл г Подольск ул Садовая 5	\N	142100
7	6	дом	пр. Мира 55-А кв.3	Москва	129085
8	7	адр	Невский пр. 100 кв.200	Санкт-Петербург	191025
9	8	доставка	Россия, г.Москва, ул.Тверская, дом 1	Москва	125009
10	9	delivery	\N	Москва	\N
11	10	доставка	Пр. Ленина 15 оф. 304	Ростов-на-Дону	344000
12	11	home	Россия 620000 Свердл.обл г.Екб ул.Малышева 51-79	Екатеринбург	620000
13	12	доставка	Москва ул.4-я Тверская-Ямская 5	Москва	125047
14	13	дом	Казань ул. Баумана 10	Казань	420000
15	14	delivery	198328, г. Санкт-Петербург, ул. Маршала Жукова, д.41 к.1 кв.22	СПб	198328
16	15	home	Новосибирск пр-т Карла Маркса 7 кв 19	Нвсб	630007
17	16	доставка	МО, Химки, Юбилейный пр. 78, кв.55	Химки	141400
18	17	дом	Краснодар Красная 135	Краснодар	350000
19	20	home	г. Москва 4-й Лесной пер. 4	Москва	125047
20	21	доставка	Санкт-Петербург Литейный проспект 44	СПб	191014
\.


--
-- Data for Name: cust_consents; Type: TABLE DATA; Schema: map; Owner: yui
--

COPY map.cust_consents (consent_id, cust_id, consent_for, agreed, dt) FROM stdin;
1	1	обработка персональных данных	да	2021-05-10
2	1	рекламные рассылки	да	2021-05-10
3	1	передача данных партнёрам	нет	2021-05-10
4	2	персональные данные	1	2022-11-03
5	2	маркетинг	0	2022-11-03
6	3	обработка ПД	yes	2020-02-14
7	3	реклама	no	2020-02-14
8	4	ПД	+	2023-04-01
9	5	обработка персональных данных	ДА	2019-08-20
10	5	рекламные рассылки	ДА	2019-08-20
11	5	передача партнёрам	НЕТ	2019-08-20
12	6	персональные данные	true	2018-06-05
13	6	маркетинг	false	2018-06-05
14	7	ПД	+	2017-03-22
15	8	обработка ПД	Да	2024-02-29
16	9	персональные данные	1	2025-01-10
17	10	ПД	да	2020-09-01
18	10	реклама	-	2020-09-01
19	11	обработка персональных данных	yes	2016-12-01
20	12	ПД	да	2021-07-07
21	12	маркетинг	да	2021-07-07
22	13	персональные данные	TRUE	2022-07-15
23	14	ПД	1	2023-09-10
24	15	обработка ПД	да	2021-01-11
25	16	персональные данные	+	2023-03-05
\.


--
-- Data for Name: cust_docs; Type: TABLE DATA; Schema: map; Owner: yui
--

COPY map.cust_docs (doc_id, cust_id, doc_type, doc_data) FROM stdin;
1	1	паспорт РФ	4516 654321 выдан ОУФМС России по р-ну Печатники г.Москвы 01.04.2016 к/п 770-007
2	2	Паспорт	серия 4513 № 123789, ОВД Академический г.Москвы, дата 20.08.2012
3	3	паспорт	45 12 998877 ОВД района Бибирево г.Москвы 12.09.2012
4	4	ПАСПОРТ РФ	Серия:45 08 Номер:789012, Кем выдан: ОФМС района Измайлово г.Москвы, Дата:01.06.2008
5	5	паспорт РФ	4509 112233 ОУФМС России 77 рег. 20.04.2009 770-043
6	6	п-т	40 14 876543 / ОУФМС Тверской / 15-03-2014 / к/п 770-013
7	7	Паспорт гражданина РФ	с.4515 н.567890 выд.15.12.2015 УФМС по г.СПб и ЛО по Адмиралтейскому р-ну
8	8	паспорт	4516123456,ОУФМС по ЗАО г.Москвы,2016-07-15
9	10	вод. удостоверение	77УТ 445566 выд. 15.05.2019 ГИБДД УМВД России по г.Ростов-на-Дону кат. B,C
10	11	Паспорт	серия 4510 номер 334455 ОУФМС СВАО Москвы 20.03.2010
11	12	паспорт РФ	45 14 223344 ФКУ ГИАЦ МВД России 10.06.2014
12	13	ПАСПОРТ	4512 887766 УФМС ПО Г.КАЗАНИ 01.08.2012
13	15	вод.уд.	77 ХА 123456 2005-11-01 УГИБДД ГУВД г.Москвы A,B
14	19	паспорт РФ	4509 556677, ОУФМС по р-ну Коньково г.Москвы, 15.06.2009, к/п 770-091
15	24	загранпаспорт	MD серия MS номер 1234567 выдан 01.03.2019 истекает 01.03.2029 Кишинёв
\.


--
-- Data for Name: cust_extra; Type: TABLE DATA; Schema: map; Owner: yui
--

COPY map.cust_extra (extra_id, cust_id, param_name, param_val) FROM stdin;
1	1	любимая_категория	ноутбуки
2	1	preferred_brand	Apple
3	1	budget	150000
4	2	fav_category	смартфоны
5	2	brand	Samsung
6	2	рассрочка	да
7	3	категория	gaming
8	3	бюджет_руб	80 000
9	4	любимый_бренд	Lenovo
10	5	любимая категория	умный дом
11	5	smart_home	yes
12	5	бюджет	300тыс
13	6	категория	телевизоры
14	7	fav_cat	TV
15	7	preferred_brand	LG
16	8	Sony	да
17	8	категория	фото
18	10	brand	нет предпочтений
19	11	любимая_категория	Ноутбуки
20	12	fav	iPhone
21	12	smart_home	1
22	15	бренд	HP
23	17	категория	смартфоны
24	20	preferred_brand	Apple
25	20	ecosystem	Apple
\.


--
-- Data for Name: customers; Type: TABLE DATA; Schema: map; Owner: yui
--

COPY map.customers (cust_id, fullname, birth_dt, sex, email, phone, phone2, inn, snils, marital, loyalty_lvl, login, reg_date, status, notes) FROM stdin;
1	Иванов Иван Сергеевич	1988-03-15	M	ivan.ivanov@gmail.com	+79261234567	\N	7743001234	112-233-445 95	женат	gold	ivan.ivanov88	2021-05-10	активен	\N
2	ПЕТРОВА АННА МИХАЙЛОВНА	15.07.1992	Ж	ANNA.PETROVA@MAIL.RU, a.petrova@yandex.ru	8(916)555-11-22	\N	7701 00 223344	\N	не замужем	Серебряный	anna.petrova	2022-11-03	активен	\N
3	Козлов А.Е.	5 января 1990 года	муж	kozlov.ae@bk.ru	8 383 444 55 66	\N	\N	32145678901	холост	bronze	a.kozlov1990	2020-02-14	активен	\N
4	Сидоров Борис Геннадьевич	15-08-1985	МУЖСКОЙ	b.sidorov@inbox.ru	89161112233	\N	540100 998877	321 456 789 01	Разведён	bronze	b.sidorov85	2023-04-01	активен	\N
5	новикова елена александровна	01.05.1985	Женский	e.novikova@work.ru,novikova85@mail.ru ,ea_nov@yandex.ru	+7-495-600-11-22	\N	\N	100-200-300 40	замужем	platinum	novikova_ea	2019-08-20	активен	\N
6	Морозов Д.А.	01.05.90	1	morozov_da@gmail.com	8 926 777 88 99	\N	6612005544332	55566677700	\N	silver	morozov_da	2018-06-05	активен	ИНН — уточнить
7	Лебедев Сергей Николаевич	ноябрь 1979	М	lebedev.sergey@list.ru	+7 812 333 44 55	\N	\N	55566677700	женат	gold	s.lebedev79	2017-03-22	заблокирован	VIP до 2023
8	СОКОЛОВА Н.А.	4 июля 1996	ж	nat.sokolova@gmail.com	8-926-123-45-67	\N	7 701 987 654	999 888 777 66	одинока	bronze	natalia.sokolova96	2024-02-29	активен	\N
9	Михайлов Андрей	\N	male	andreyM_2000@inbox.ru  andr.mikhaylov@corp.ru	\N	\N	\N	\N	не указано	bronze	a.mikhaylov	2025-01-10	активен	дублирующийся аккаунт — проверить
10	Федорова Юлия Олеговна	1985/03/15	Ж	fedorova_y@yandex.ru	+7(863)222-33-44	\N	6 164 001 122 33	100.200.300-40	разведена	silver	yuliya.fedorova85	2020-09-01	активен	\N
11	Попов Виктор Геннадьевич	03.11.1972	М	v.popov@corp.ru	+7 495 111 22 33	\N	7 743 000 132	77700011200	женат	gold	viktor.popov72	2016-12-01	активен	\N
12	Кузнецова Анна Максимовна	25 декабря 1993 года	F	anna.k@gmail.com	+7(495) 123-45-67	8-926-888-99-00	7701987654	445-566-778 99	замужем	platinum	anna.kuznetsova93	2021-07-07	активен	\N
13	ЗАЙЦЕВ РОМАН ЕВГЕНЬЕВИЧ	07-04-1991	М	roman.zaitsev@rambler.ru	89031234567	\N	5040-001-234-56	98765432100	Холост	silver	roman.zaitsev91	2022-07-15	активен	\N
14	Белова К.	1998/06/22	female	belova_ks@mail.ru, belova.kseniya@gmail.com	926-111-22-33	\N	5030101234	\N	не замужем	bronze	belova_ks98	2023-09-10	активен	\N
15	Тарасов Константин Игоревич	25/12/1970	0	k.tarasov@yandex.ru	8(383)999-88-77	\N	7700000000	123 456 789 00	вдовец	silver	k.tarasov70	2021-01-11	активен	\N
16	ГРОМОВ АРТЁМ ВИКТОРОВИЧ	12.09.1993	Мужчина	artem.gromov@gmail.com;a.gromov@work.ru	+79151234567	\N	5050 1234 56	88899900011	не женат	bronze	artem.gromov93	2023-03-05	активен	\N
17	Фролова Наталья	March 5, 1991	female	frolova_n@bk.ru	+7 917 777 66 55	\N	\N	321-654-987 00	одинокая	\N	natasha.frolova91	2022-04-20	активен	\N
18	Захаров Олег Михайлович	12-09-1983	м	o.zakharov@inbox.ru	8 (925) 456 78 90	\N	7714 998877	88899900011	Женат	bronze	o.zakharov83	2020-11-30	активен	\N
19	Крылова Марина Вячеславовна	1979-11-30	Ж	marinakrylova.mail.ru	+79123456789	\N	7714998877	001 002 003 04	замужем	silver	marina.krylova79	2019-05-15	активен	email уточнить
20	Богданов Виктор Анатольевич	15 августа 1967 года	M	v.bogdanov@gmail.com	8 800 333 44 55	\N	\N	001 002 003 04	женат	gold	v.bogdanov67	2016-06-01	активен	\N
21	Симонова Алина Дмитриевна	30.06.1994	Ж	alina.simonova@yandex.ru	+79269998877	\N	770100445566	\N	незамужем	silver	alina.simonova94	2023-08-12	активен	\N
22	Вешняков Кирилл Павлович	1988/11/11	М	kirill_v@hotmail.com	\N	\N	770100445566	123-456-789 00	холостой	bronze	kirill.v88	2024-05-03	активен	\N
23	Горбунова Диана Сергеевна	н/д	Ж	d.gorbunova@gmail.com	+74951234567	\N	\N	\N	Замужем	bronze	diana.gorbunova	2025-03-15	активен	дата рождения неизвестна
24	Попеску Ион Александрович	15.03.1987	М	ion.popescu@mail.ru	+37369123456	\N	\N	\N	женат	silver	ion.popescu87	2022-10-10	активен	гражданин Молдовы, ИНН отсутствует
25	Чернов Илья Павлович	5 января 1991	муж.	ilya.chernov@gmail.com	8 901 234 56 78	\N	7701-00-445566	321-654-987 00	не женат	bronze	ilya.chernov91	2023-11-20	активен	\N
9001		1990-01-01	М	error.empty.fullname@example.ru	+79990000001	\N	\N	\N	\N	demo	error_empty_fullname	2026-06-07	активен	Демонстрационная ошибка: пустое ФИО
9002	Ошибка Без Логина	1992-02-02	Ж	error.empty.login@example.ru	+79990000002	\N	\N	\N	\N	demo	\N	2026-06-07	активен	Демонстрационная ошибка: пустой login
\.


--
-- Data for Name: migration_log; Type: TABLE DATA; Schema: map; Owner: yui
--

COPY map.migration_log (log_id, migration_run_id, source_system, source_record_id, target_person_id, status, stage, error_code, error_message, warning_messages, source_data, created_at) FROM stdin;
edab88c0-77a4-4e4b-9ca9-80520e4096e5	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	1	841a025c-4b12-41ab-aaad-d88bdff03406	success	load	\N	\N	\N	{"inn": "7743001234", "sex": "M", "email": "ivan.ivanov@gmail.com", "login": "ivan.ivanov88", "notes": null, "phone": "+79261234567", "snils": "112-233-445 95", "phone2": null, "status": "активен", "cust_id": 1, "marital": "женат", "birth_dt": "1988-03-15", "fullname": "Иванов Иван Сергеевич", "reg_date": "2021-05-10", "loyalty_lvl": "gold"}	2026-06-07 20:42:54.833905+03
f96be6c1-5739-4939-b354-ac0f5fa941b9	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	2	6295c95d-393f-4dc4-822e-b1fb1e14c4e2	success	load	\N	\N	\N	{"inn": "7701 00 223344", "sex": "Ж", "email": "ANNA.PETROVA@MAIL.RU, a.petrova@yandex.ru", "login": "anna.petrova", "notes": null, "phone": "8(916)555-11-22", "snils": null, "phone2": null, "status": "активен", "cust_id": 2, "marital": "не замужем", "birth_dt": "15.07.1992", "fullname": "ПЕТРОВА АННА МИХАЙЛОВНА", "reg_date": "2022-11-03", "loyalty_lvl": "Серебряный"}	2026-06-07 20:42:54.833905+03
9a9b0f21-070b-4387-9acc-ef7cd8b437ae	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	3	46d321ec-69be-4de6-a08e-31b3607a0a78	warning	load	\N	\N	{"ФИО содержит инициалы или неполное имя: Козлов А.Е."}	{"inn": null, "sex": "муж", "email": "kozlov.ae@bk.ru", "login": "a.kozlov1990", "notes": null, "phone": "8 383 444 55 66", "snils": "32145678901", "phone2": null, "status": "активен", "cust_id": 3, "marital": "холост", "birth_dt": "5 января 1990 года", "fullname": "Козлов А.Е.", "reg_date": "2020-02-14", "loyalty_lvl": "bronze"}	2026-06-07 20:42:54.833905+03
df66af79-311c-4cae-930f-93d7888f53a8	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	4	46d321ec-69be-4de6-a08e-31b3607a0a78	success	load	\N	\N	\N	{"inn": "540100 998877", "sex": "МУЖСКОЙ", "email": "b.sidorov@inbox.ru", "login": "b.sidorov85", "notes": null, "phone": "89161112233", "snils": "321 456 789 01", "phone2": null, "status": "активен", "cust_id": 4, "marital": "Разведён", "birth_dt": "15-08-1985", "fullname": "Сидоров Борис Геннадьевич", "reg_date": "2023-04-01", "loyalty_lvl": "bronze"}	2026-06-07 20:42:54.833905+03
1f0fd0d5-fa0f-44e8-88b0-774d88299e68	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	5	9fb760a6-3618-4999-8537-bce4c127800e	success	load	\N	\N	\N	{"inn": null, "sex": "Женский", "email": "e.novikova@work.ru,novikova85@mail.ru ,ea_nov@yandex.ru", "login": "novikova_ea", "notes": null, "phone": "+7-495-600-11-22", "snils": "100-200-300 40", "phone2": null, "status": "активен", "cust_id": 5, "marital": "замужем", "birth_dt": "01.05.1985", "fullname": "новикова елена александровна", "reg_date": "2019-08-20", "loyalty_lvl": "platinum"}	2026-06-07 20:42:54.833905+03
eaca8303-34a2-4550-9dfc-b97930c01880	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	6	f3b76a50-5950-4a1e-9132-ac769c5b9e97	warning	load	\N	\N	{"ФИО содержит инициалы или неполное имя: Морозов Д.А."}	{"inn": "6612005544332", "sex": "1", "email": "morozov_da@gmail.com", "login": "morozov_da", "notes": "ИНН — уточнить", "phone": "8 926 777 88 99", "snils": "55566677700", "phone2": null, "status": "активен", "cust_id": 6, "marital": null, "birth_dt": "01.05.90", "fullname": "Морозов Д.А.", "reg_date": "2018-06-05", "loyalty_lvl": "silver"}	2026-06-07 20:42:54.833905+03
6dbc1ddc-04ca-45d2-8ee3-1ddfbda6d170	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	7	f3b76a50-5950-4a1e-9132-ac769c5b9e97	warning	load	\N	\N	{"Дата рождения не распознана: ноябрь 1979"}	{"inn": null, "sex": "М", "email": "lebedev.sergey@list.ru", "login": "s.lebedev79", "notes": "VIP до 2023", "phone": "+7 812 333 44 55", "snils": "55566677700", "phone2": null, "status": "заблокирован", "cust_id": 7, "marital": "женат", "birth_dt": "ноябрь 1979", "fullname": "Лебедев Сергей Николаевич", "reg_date": "2017-03-22", "loyalty_lvl": "gold"}	2026-06-07 20:42:54.833905+03
54d32856-ed0e-42f6-bb4d-69929df3bc0a	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	8	d4c7f619-e8a9-470d-acc0-d1c976cbbf11	warning	load	\N	\N	{"ФИО содержит инициалы или неполное имя: СОКОЛОВА Н.А."}	{"inn": "7 701 987 654", "sex": "ж", "email": "nat.sokolova@gmail.com", "login": "natalia.sokolova96", "notes": null, "phone": "8-926-123-45-67", "snils": "999 888 777 66", "phone2": null, "status": "активен", "cust_id": 8, "marital": "одинока", "birth_dt": "4 июля 1996", "fullname": "СОКОЛОВА Н.А.", "reg_date": "2024-02-29", "loyalty_lvl": "bronze"}	2026-06-07 20:42:54.833905+03
c1a95485-2d85-46c2-9238-6a5fcbe79a09	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	9	fce2d6eb-fc55-4d17-bab0-06e159c14686	warning	load	\N	\N	{"Адрес отсутствует или пустой"}	{"inn": null, "sex": "male", "email": "andreyM_2000@inbox.ru  andr.mikhaylov@corp.ru", "login": "a.mikhaylov", "notes": "дублирующийся аккаунт — проверить", "phone": null, "snils": null, "phone2": null, "status": "активен", "cust_id": 9, "marital": "не указано", "birth_dt": null, "fullname": "Михайлов Андрей", "reg_date": "2025-01-10", "loyalty_lvl": "bronze"}	2026-06-07 20:42:54.833905+03
141dc3bb-3943-4cdf-a8c3-769be849ef88	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	10	9fb760a6-3618-4999-8537-bce4c127800e	success	load	\N	\N	\N	{"inn": "6 164 001 122 33", "sex": "Ж", "email": "fedorova_y@yandex.ru", "login": "yuliya.fedorova85", "notes": null, "phone": "+7(863)222-33-44", "snils": "100.200.300-40", "phone2": null, "status": "активен", "cust_id": 10, "marital": "разведена", "birth_dt": "1985/03/15", "fullname": "Федорова Юлия Олеговна", "reg_date": "2020-09-01", "loyalty_lvl": "silver"}	2026-06-07 20:42:54.833905+03
e67c3186-adf9-46cd-8834-878f8f1a8592	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	11	7fb42bd1-ad5a-4582-ac10-9e5bcc2dd8e1	success	load	\N	\N	\N	{"inn": "7 743 000 132", "sex": "М", "email": "v.popov@corp.ru", "login": "viktor.popov72", "notes": null, "phone": "+7 495 111 22 33", "snils": "77700011200", "phone2": null, "status": "активен", "cust_id": 11, "marital": "женат", "birth_dt": "03.11.1972", "fullname": "Попов Виктор Геннадьевич", "reg_date": "2016-12-01", "loyalty_lvl": "gold"}	2026-06-07 20:42:54.833905+03
a549c2ad-27ae-4f09-b312-42c906e6189e	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	12	d4c7f619-e8a9-470d-acc0-d1c976cbbf11	success	load	\N	\N	\N	{"inn": "7701987654", "sex": "F", "email": "anna.k@gmail.com", "login": "anna.kuznetsova93", "notes": null, "phone": "+7(495) 123-45-67", "snils": "445-566-778 99", "phone2": "8-926-888-99-00", "status": "активен", "cust_id": 12, "marital": "замужем", "birth_dt": "25 декабря 1993 года", "fullname": "Кузнецова Анна Максимовна", "reg_date": "2021-07-07", "loyalty_lvl": "platinum"}	2026-06-07 20:42:54.833905+03
8d5529e6-3fff-4bcd-95ce-45f6b62f9f71	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	13	50fc12d2-3450-4db8-aebe-c1a1a251254a	success	load	\N	\N	\N	{"inn": "5040-001-234-56", "sex": "М", "email": "roman.zaitsev@rambler.ru", "login": "roman.zaitsev91", "notes": null, "phone": "89031234567", "snils": "98765432100", "phone2": null, "status": "активен", "cust_id": 13, "marital": "Холост", "birth_dt": "07-04-1991", "fullname": "ЗАЙЦЕВ РОМАН ЕВГЕНЬЕВИЧ", "reg_date": "2022-07-15", "loyalty_lvl": "silver"}	2026-06-07 20:42:54.833905+03
a80e6f05-cf3b-48f2-826b-0b02d5c1c567	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	14	2f4be900-91d9-49ed-855f-8ca0fc20b7aa	warning	load	\N	\N	{"ФИО содержит инициалы или неполное имя: Белова К."}	{"inn": "5030101234", "sex": "female", "email": "belova_ks@mail.ru, belova.kseniya@gmail.com", "login": "belova_ks98", "notes": null, "phone": "926-111-22-33", "snils": null, "phone2": null, "status": "активен", "cust_id": 14, "marital": "не замужем", "birth_dt": "1998/06/22", "fullname": "Белова К.", "reg_date": "2023-09-10", "loyalty_lvl": "bronze"}	2026-06-07 20:42:54.833905+03
ea714187-46a0-4531-b7df-5f3440e6416f	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	15	97a57ff9-a693-4a11-9f75-726a3be36cac	success	load	\N	\N	\N	{"inn": "7700000000", "sex": "0", "email": "k.tarasov@yandex.ru", "login": "k.tarasov70", "notes": null, "phone": "8(383)999-88-77", "snils": "123 456 789 00", "phone2": null, "status": "активен", "cust_id": 15, "marital": "вдовец", "birth_dt": "25/12/1970", "fullname": "Тарасов Константин Игоревич", "reg_date": "2021-01-11", "loyalty_lvl": "silver"}	2026-06-07 20:42:54.833905+03
76fe094b-b5ad-4d2f-8b25-f73583166bbe	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	16	fad46874-5f76-47dd-bcd6-f40b9ee82cef	success	load	\N	\N	\N	{"inn": "5050 1234 56", "sex": "Мужчина", "email": "artem.gromov@gmail.com;a.gromov@work.ru", "login": "artem.gromov93", "notes": null, "phone": "+79151234567", "snils": "88899900011", "phone2": null, "status": "активен", "cust_id": 16, "marital": "не женат", "birth_dt": "12.09.1993", "fullname": "ГРОМОВ АРТЁМ ВИКТОРОВИЧ", "reg_date": "2023-03-05", "loyalty_lvl": "bronze"}	2026-06-07 20:42:54.833905+03
3b7ff4f7-c8c1-4e99-b74d-81b629a2a5d6	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	17	bb6e1a4b-9893-4b53-b078-c4861951aa77	success	load	\N	\N	\N	{"inn": null, "sex": "female", "email": "frolova_n@bk.ru", "login": "natasha.frolova91", "notes": null, "phone": "+7 917 777 66 55", "snils": "321-654-987 00", "phone2": null, "status": "активен", "cust_id": 17, "marital": "одинокая", "birth_dt": "March 5, 1991", "fullname": "Фролова Наталья", "reg_date": "2022-04-20", "loyalty_lvl": null}	2026-06-07 20:42:54.833905+03
3ac54340-32f0-4aec-a32a-d50b4bd60fd7	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	18	fad46874-5f76-47dd-bcd6-f40b9ee82cef	warning	load	\N	\N	{"Адрес отсутствует или пустой"}	{"inn": "7714 998877", "sex": "м", "email": "o.zakharov@inbox.ru", "login": "o.zakharov83", "notes": null, "phone": "8 (925) 456 78 90", "snils": "88899900011", "phone2": null, "status": "активен", "cust_id": 18, "marital": "Женат", "birth_dt": "12-09-1983", "fullname": "Захаров Олег Михайлович", "reg_date": "2020-11-30", "loyalty_lvl": "bronze"}	2026-06-07 20:42:54.833905+03
13c1b0b3-59e6-41da-89e6-a82ab7b1ca7b	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	19	fad46874-5f76-47dd-bcd6-f40b9ee82cef	warning	load	\N	\N	{"Подозрительный контакт: marinakrylova.mail.ru","Адрес отсутствует или пустой"}	{"inn": "7714998877", "sex": "Ж", "email": "marinakrylova.mail.ru", "login": "marina.krylova79", "notes": "email уточнить", "phone": "+79123456789", "snils": "001 002 003 04", "phone2": null, "status": "активен", "cust_id": 19, "marital": "замужем", "birth_dt": "1979-11-30", "fullname": "Крылова Марина Вячеславовна", "reg_date": "2019-05-15", "loyalty_lvl": "silver"}	2026-06-07 20:42:54.833905+03
8273234a-d942-4dbd-bdf6-41d1ce7ef69b	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	20	fad46874-5f76-47dd-bcd6-f40b9ee82cef	success	load	\N	\N	\N	{"inn": null, "sex": "M", "email": "v.bogdanov@gmail.com", "login": "v.bogdanov67", "notes": null, "phone": "8 800 333 44 55", "snils": "001 002 003 04", "phone2": null, "status": "активен", "cust_id": 20, "marital": "женат", "birth_dt": "15 августа 1967 года", "fullname": "Богданов Виктор Анатольевич", "reg_date": "2016-06-01", "loyalty_lvl": "gold"}	2026-06-07 20:42:54.833905+03
4c1decaf-c1fe-4f16-9fa7-59bc077afd26	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	21	dae8c362-ab3a-45f8-8ea9-e610ecdc6834	success	load	\N	\N	\N	{"inn": "770100445566", "sex": "Ж", "email": "alina.simonova@yandex.ru", "login": "alina.simonova94", "notes": null, "phone": "+79269998877", "snils": null, "phone2": null, "status": "активен", "cust_id": 21, "marital": "незамужем", "birth_dt": "30.06.1994", "fullname": "Симонова Алина Дмитриевна", "reg_date": "2023-08-12", "loyalty_lvl": "silver"}	2026-06-07 20:42:54.833905+03
5f7586b4-7fc2-4779-a459-54af92dd4b0e	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	22	dae8c362-ab3a-45f8-8ea9-e610ecdc6834	warning	load	\N	\N	{"Адрес отсутствует или пустой"}	{"inn": "770100445566", "sex": "М", "email": "kirill_v@hotmail.com", "login": "kirill.v88", "notes": null, "phone": null, "snils": "123-456-789 00", "phone2": null, "status": "активен", "cust_id": 22, "marital": "холостой", "birth_dt": "1988/11/11", "fullname": "Вешняков Кирилл Павлович", "reg_date": "2024-05-03", "loyalty_lvl": "bronze"}	2026-06-07 20:42:54.833905+03
49ecd3fc-848c-480b-818d-ff938302649a	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	23	a8b406e8-3108-4af6-a1f5-a7a72610fa77	warning	load	\N	\N	{"Дата рождения не распознана: н/д","Адрес отсутствует или пустой"}	{"inn": null, "sex": "Ж", "email": "d.gorbunova@gmail.com", "login": "diana.gorbunova", "notes": "дата рождения неизвестна", "phone": "+74951234567", "snils": null, "phone2": null, "status": "активен", "cust_id": 23, "marital": "Замужем", "birth_dt": "н/д", "fullname": "Горбунова Диана Сергеевна", "reg_date": "2025-03-15", "loyalty_lvl": "bronze"}	2026-06-07 20:42:54.833905+03
0fd0e641-eae0-422b-8bec-6a83d4325d5d	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	24	a4ff128d-9934-40f3-a356-e9a2127694b0	warning	load	\N	\N	{"Адрес отсутствует или пустой"}	{"inn": null, "sex": "М", "email": "ion.popescu@mail.ru", "login": "ion.popescu87", "notes": "гражданин Молдовы, ИНН отсутствует", "phone": "+37369123456", "snils": null, "phone2": null, "status": "активен", "cust_id": 24, "marital": "женат", "birth_dt": "15.03.1987", "fullname": "Попеску Ион Александрович", "reg_date": "2022-10-10", "loyalty_lvl": "silver"}	2026-06-07 20:42:54.833905+03
66ebfe73-a184-4813-8c33-3c4950db2554	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	25	dae8c362-ab3a-45f8-8ea9-e610ecdc6834	warning	load	\N	\N	{"Адрес отсутствует или пустой"}	{"inn": "7701-00-445566", "sex": "муж.", "email": "ilya.chernov@gmail.com", "login": "ilya.chernov91", "notes": null, "phone": "8 901 234 56 78", "snils": "321-654-987 00", "phone2": null, "status": "активен", "cust_id": 25, "marital": "не женат", "birth_dt": "5 января 1991", "fullname": "Чернов Илья Павлович", "reg_date": "2023-11-20", "loyalty_lvl": "bronze"}	2026-06-07 20:42:54.833905+03
2ef1698c-46d6-4018-b7ad-d2c14fdc7167	c85f67f6-d913-424a-a416-c710bfe3ec5f	partner_bd2	1	841a025c-4b12-41ab-aaad-d88bdff03406	skipped	deduplicate	\N	\N	\N	{"inn": "7743001234", "sex": "M", "email": "ivan.ivanov@gmail.com", "login": "ivan.ivanov88", "notes": null, "phone": "+79261234567", "snils": "112-233-445 95", "phone2": null, "status": "активен", "cust_id": 1, "marital": "женат", "birth_dt": "1988-03-15", "fullname": "Иванов Иван Сергеевич", "reg_date": "2021-05-10", "loyalty_lvl": "gold"}	2026-06-07 20:42:54.904709+03
470b6d95-8e41-457c-aba8-56df69ca6169	c85f67f6-d913-424a-a416-c710bfe3ec5f	partner_bd2	2	6295c95d-393f-4dc4-822e-b1fb1e14c4e2	skipped	deduplicate	\N	\N	\N	{"inn": "7701 00 223344", "sex": "Ж", "email": "ANNA.PETROVA@MAIL.RU, a.petrova@yandex.ru", "login": "anna.petrova", "notes": null, "phone": "8(916)555-11-22", "snils": null, "phone2": null, "status": "активен", "cust_id": 2, "marital": "не замужем", "birth_dt": "15.07.1992", "fullname": "ПЕТРОВА АННА МИХАЙЛОВНА", "reg_date": "2022-11-03", "loyalty_lvl": "Серебряный"}	2026-06-07 20:42:54.904709+03
6bb54951-379b-4be0-8b8e-bd0b8d3dc7f5	c85f67f6-d913-424a-a416-c710bfe3ec5f	partner_bd2	3	46d321ec-69be-4de6-a08e-31b3607a0a78	skipped	deduplicate	\N	\N	\N	{"inn": null, "sex": "муж", "email": "kozlov.ae@bk.ru", "login": "a.kozlov1990", "notes": null, "phone": "8 383 444 55 66", "snils": "32145678901", "phone2": null, "status": "активен", "cust_id": 3, "marital": "холост", "birth_dt": "5 января 1990 года", "fullname": "Козлов А.Е.", "reg_date": "2020-02-14", "loyalty_lvl": "bronze"}	2026-06-07 20:42:54.904709+03
116e945c-6e44-45c7-adf3-f15f7b6d7b4e	c85f67f6-d913-424a-a416-c710bfe3ec5f	partner_bd2	4	46d321ec-69be-4de6-a08e-31b3607a0a78	skipped	deduplicate	\N	\N	\N	{"inn": "540100 998877", "sex": "МУЖСКОЙ", "email": "b.sidorov@inbox.ru", "login": "b.sidorov85", "notes": null, "phone": "89161112233", "snils": "321 456 789 01", "phone2": null, "status": "активен", "cust_id": 4, "marital": "Разведён", "birth_dt": "15-08-1985", "fullname": "Сидоров Борис Геннадьевич", "reg_date": "2023-04-01", "loyalty_lvl": "bronze"}	2026-06-07 20:42:54.904709+03
6c9562b9-ca53-4194-9e6a-091ac1d610ff	c85f67f6-d913-424a-a416-c710bfe3ec5f	partner_bd2	5	9fb760a6-3618-4999-8537-bce4c127800e	skipped	deduplicate	\N	\N	\N	{"inn": null, "sex": "Женский", "email": "e.novikova@work.ru,novikova85@mail.ru ,ea_nov@yandex.ru", "login": "novikova_ea", "notes": null, "phone": "+7-495-600-11-22", "snils": "100-200-300 40", "phone2": null, "status": "активен", "cust_id": 5, "marital": "замужем", "birth_dt": "01.05.1985", "fullname": "новикова елена александровна", "reg_date": "2019-08-20", "loyalty_lvl": "platinum"}	2026-06-07 20:42:54.904709+03
748cd70f-ad0a-424a-81f8-feefd432c274	c85f67f6-d913-424a-a416-c710bfe3ec5f	partner_bd2	6	f3b76a50-5950-4a1e-9132-ac769c5b9e97	skipped	deduplicate	\N	\N	\N	{"inn": "6612005544332", "sex": "1", "email": "morozov_da@gmail.com", "login": "morozov_da", "notes": "ИНН — уточнить", "phone": "8 926 777 88 99", "snils": "55566677700", "phone2": null, "status": "активен", "cust_id": 6, "marital": null, "birth_dt": "01.05.90", "fullname": "Морозов Д.А.", "reg_date": "2018-06-05", "loyalty_lvl": "silver"}	2026-06-07 20:42:54.904709+03
5479b3ab-7eab-4e93-9de2-539723f50680	c85f67f6-d913-424a-a416-c710bfe3ec5f	partner_bd2	7	f3b76a50-5950-4a1e-9132-ac769c5b9e97	skipped	deduplicate	\N	\N	\N	{"inn": null, "sex": "М", "email": "lebedev.sergey@list.ru", "login": "s.lebedev79", "notes": "VIP до 2023", "phone": "+7 812 333 44 55", "snils": "55566677700", "phone2": null, "status": "заблокирован", "cust_id": 7, "marital": "женат", "birth_dt": "ноябрь 1979", "fullname": "Лебедев Сергей Николаевич", "reg_date": "2017-03-22", "loyalty_lvl": "gold"}	2026-06-07 20:42:54.904709+03
75577a29-c82a-49ff-ae53-83faa1697e76	c85f67f6-d913-424a-a416-c710bfe3ec5f	partner_bd2	8	d4c7f619-e8a9-470d-acc0-d1c976cbbf11	skipped	deduplicate	\N	\N	\N	{"inn": "7 701 987 654", "sex": "ж", "email": "nat.sokolova@gmail.com", "login": "natalia.sokolova96", "notes": null, "phone": "8-926-123-45-67", "snils": "999 888 777 66", "phone2": null, "status": "активен", "cust_id": 8, "marital": "одинока", "birth_dt": "4 июля 1996", "fullname": "СОКОЛОВА Н.А.", "reg_date": "2024-02-29", "loyalty_lvl": "bronze"}	2026-06-07 20:42:54.904709+03
d768b652-1df1-4db1-ac6f-c8a1ee671c11	c85f67f6-d913-424a-a416-c710bfe3ec5f	partner_bd2	9	fce2d6eb-fc55-4d17-bab0-06e159c14686	skipped	deduplicate	\N	\N	\N	{"inn": null, "sex": "male", "email": "andreyM_2000@inbox.ru  andr.mikhaylov@corp.ru", "login": "a.mikhaylov", "notes": "дублирующийся аккаунт — проверить", "phone": null, "snils": null, "phone2": null, "status": "активен", "cust_id": 9, "marital": "не указано", "birth_dt": null, "fullname": "Михайлов Андрей", "reg_date": "2025-01-10", "loyalty_lvl": "bronze"}	2026-06-07 20:42:54.904709+03
588d47fb-f2a0-417d-8419-b7a0d09b50e6	c85f67f6-d913-424a-a416-c710bfe3ec5f	partner_bd2	10	9fb760a6-3618-4999-8537-bce4c127800e	skipped	deduplicate	\N	\N	\N	{"inn": "6 164 001 122 33", "sex": "Ж", "email": "fedorova_y@yandex.ru", "login": "yuliya.fedorova85", "notes": null, "phone": "+7(863)222-33-44", "snils": "100.200.300-40", "phone2": null, "status": "активен", "cust_id": 10, "marital": "разведена", "birth_dt": "1985/03/15", "fullname": "Федорова Юлия Олеговна", "reg_date": "2020-09-01", "loyalty_lvl": "silver"}	2026-06-07 20:42:54.904709+03
f8aecdb8-77d0-4d1e-9d25-4c7ff0ca761b	c85f67f6-d913-424a-a416-c710bfe3ec5f	partner_bd2	11	7fb42bd1-ad5a-4582-ac10-9e5bcc2dd8e1	skipped	deduplicate	\N	\N	\N	{"inn": "7 743 000 132", "sex": "М", "email": "v.popov@corp.ru", "login": "viktor.popov72", "notes": null, "phone": "+7 495 111 22 33", "snils": "77700011200", "phone2": null, "status": "активен", "cust_id": 11, "marital": "женат", "birth_dt": "03.11.1972", "fullname": "Попов Виктор Геннадьевич", "reg_date": "2016-12-01", "loyalty_lvl": "gold"}	2026-06-07 20:42:54.904709+03
1f920f2a-3cf4-4bde-97f8-e1561b364c92	c85f67f6-d913-424a-a416-c710bfe3ec5f	partner_bd2	12	d4c7f619-e8a9-470d-acc0-d1c976cbbf11	skipped	deduplicate	\N	\N	\N	{"inn": "7701987654", "sex": "F", "email": "anna.k@gmail.com", "login": "anna.kuznetsova93", "notes": null, "phone": "+7(495) 123-45-67", "snils": "445-566-778 99", "phone2": "8-926-888-99-00", "status": "активен", "cust_id": 12, "marital": "замужем", "birth_dt": "25 декабря 1993 года", "fullname": "Кузнецова Анна Максимовна", "reg_date": "2021-07-07", "loyalty_lvl": "platinum"}	2026-06-07 20:42:54.904709+03
784de9d1-f55d-437b-98db-4de6ef222497	c85f67f6-d913-424a-a416-c710bfe3ec5f	partner_bd2	13	50fc12d2-3450-4db8-aebe-c1a1a251254a	skipped	deduplicate	\N	\N	\N	{"inn": "5040-001-234-56", "sex": "М", "email": "roman.zaitsev@rambler.ru", "login": "roman.zaitsev91", "notes": null, "phone": "89031234567", "snils": "98765432100", "phone2": null, "status": "активен", "cust_id": 13, "marital": "Холост", "birth_dt": "07-04-1991", "fullname": "ЗАЙЦЕВ РОМАН ЕВГЕНЬЕВИЧ", "reg_date": "2022-07-15", "loyalty_lvl": "silver"}	2026-06-07 20:42:54.904709+03
bf4899e5-b6ca-49b8-a0cd-38e6ce514294	c85f67f6-d913-424a-a416-c710bfe3ec5f	partner_bd2	14	2f4be900-91d9-49ed-855f-8ca0fc20b7aa	skipped	deduplicate	\N	\N	\N	{"inn": "5030101234", "sex": "female", "email": "belova_ks@mail.ru, belova.kseniya@gmail.com", "login": "belova_ks98", "notes": null, "phone": "926-111-22-33", "snils": null, "phone2": null, "status": "активен", "cust_id": 14, "marital": "не замужем", "birth_dt": "1998/06/22", "fullname": "Белова К.", "reg_date": "2023-09-10", "loyalty_lvl": "bronze"}	2026-06-07 20:42:54.904709+03
6ed8d7ab-9937-4ab7-a9e4-685bf942859d	c85f67f6-d913-424a-a416-c710bfe3ec5f	partner_bd2	15	97a57ff9-a693-4a11-9f75-726a3be36cac	skipped	deduplicate	\N	\N	\N	{"inn": "7700000000", "sex": "0", "email": "k.tarasov@yandex.ru", "login": "k.tarasov70", "notes": null, "phone": "8(383)999-88-77", "snils": "123 456 789 00", "phone2": null, "status": "активен", "cust_id": 15, "marital": "вдовец", "birth_dt": "25/12/1970", "fullname": "Тарасов Константин Игоревич", "reg_date": "2021-01-11", "loyalty_lvl": "silver"}	2026-06-07 20:42:54.904709+03
589e8301-cca4-4029-bbab-e54ec07bb953	c85f67f6-d913-424a-a416-c710bfe3ec5f	partner_bd2	16	fad46874-5f76-47dd-bcd6-f40b9ee82cef	skipped	deduplicate	\N	\N	\N	{"inn": "5050 1234 56", "sex": "Мужчина", "email": "artem.gromov@gmail.com;a.gromov@work.ru", "login": "artem.gromov93", "notes": null, "phone": "+79151234567", "snils": "88899900011", "phone2": null, "status": "активен", "cust_id": 16, "marital": "не женат", "birth_dt": "12.09.1993", "fullname": "ГРОМОВ АРТЁМ ВИКТОРОВИЧ", "reg_date": "2023-03-05", "loyalty_lvl": "bronze"}	2026-06-07 20:42:54.904709+03
58c678db-9a82-41f2-9687-b66c0f368dc6	c85f67f6-d913-424a-a416-c710bfe3ec5f	partner_bd2	17	bb6e1a4b-9893-4b53-b078-c4861951aa77	skipped	deduplicate	\N	\N	\N	{"inn": null, "sex": "female", "email": "frolova_n@bk.ru", "login": "natasha.frolova91", "notes": null, "phone": "+7 917 777 66 55", "snils": "321-654-987 00", "phone2": null, "status": "активен", "cust_id": 17, "marital": "одинокая", "birth_dt": "March 5, 1991", "fullname": "Фролова Наталья", "reg_date": "2022-04-20", "loyalty_lvl": null}	2026-06-07 20:42:54.904709+03
73047175-1948-45be-b6cf-c54bcaaf629c	c85f67f6-d913-424a-a416-c710bfe3ec5f	partner_bd2	18	fad46874-5f76-47dd-bcd6-f40b9ee82cef	skipped	deduplicate	\N	\N	\N	{"inn": "7714 998877", "sex": "м", "email": "o.zakharov@inbox.ru", "login": "o.zakharov83", "notes": null, "phone": "8 (925) 456 78 90", "snils": "88899900011", "phone2": null, "status": "активен", "cust_id": 18, "marital": "Женат", "birth_dt": "12-09-1983", "fullname": "Захаров Олег Михайлович", "reg_date": "2020-11-30", "loyalty_lvl": "bronze"}	2026-06-07 20:42:54.904709+03
2f9bf44e-5478-4036-bc70-e8f37366ad1d	c85f67f6-d913-424a-a416-c710bfe3ec5f	partner_bd2	19	fad46874-5f76-47dd-bcd6-f40b9ee82cef	skipped	deduplicate	\N	\N	\N	{"inn": "7714998877", "sex": "Ж", "email": "marinakrylova.mail.ru", "login": "marina.krylova79", "notes": "email уточнить", "phone": "+79123456789", "snils": "001 002 003 04", "phone2": null, "status": "активен", "cust_id": 19, "marital": "замужем", "birth_dt": "1979-11-30", "fullname": "Крылова Марина Вячеславовна", "reg_date": "2019-05-15", "loyalty_lvl": "silver"}	2026-06-07 20:42:54.904709+03
49d4a581-554e-4c20-90de-510d49e0efc0	c85f67f6-d913-424a-a416-c710bfe3ec5f	partner_bd2	20	fad46874-5f76-47dd-bcd6-f40b9ee82cef	skipped	deduplicate	\N	\N	\N	{"inn": null, "sex": "M", "email": "v.bogdanov@gmail.com", "login": "v.bogdanov67", "notes": null, "phone": "8 800 333 44 55", "snils": "001 002 003 04", "phone2": null, "status": "активен", "cust_id": 20, "marital": "женат", "birth_dt": "15 августа 1967 года", "fullname": "Богданов Виктор Анатольевич", "reg_date": "2016-06-01", "loyalty_lvl": "gold"}	2026-06-07 20:42:54.904709+03
69822f1e-a131-498d-be48-998ebaea7c56	c85f67f6-d913-424a-a416-c710bfe3ec5f	partner_bd2	21	dae8c362-ab3a-45f8-8ea9-e610ecdc6834	skipped	deduplicate	\N	\N	\N	{"inn": "770100445566", "sex": "Ж", "email": "alina.simonova@yandex.ru", "login": "alina.simonova94", "notes": null, "phone": "+79269998877", "snils": null, "phone2": null, "status": "активен", "cust_id": 21, "marital": "незамужем", "birth_dt": "30.06.1994", "fullname": "Симонова Алина Дмитриевна", "reg_date": "2023-08-12", "loyalty_lvl": "silver"}	2026-06-07 20:42:54.904709+03
ab6e8ac7-16f6-4778-907c-b042520267a5	c85f67f6-d913-424a-a416-c710bfe3ec5f	partner_bd2	22	dae8c362-ab3a-45f8-8ea9-e610ecdc6834	skipped	deduplicate	\N	\N	\N	{"inn": "770100445566", "sex": "М", "email": "kirill_v@hotmail.com", "login": "kirill.v88", "notes": null, "phone": null, "snils": "123-456-789 00", "phone2": null, "status": "активен", "cust_id": 22, "marital": "холостой", "birth_dt": "1988/11/11", "fullname": "Вешняков Кирилл Павлович", "reg_date": "2024-05-03", "loyalty_lvl": "bronze"}	2026-06-07 20:42:54.904709+03
172532a5-2216-4a25-b524-cbb369a3d610	c85f67f6-d913-424a-a416-c710bfe3ec5f	partner_bd2	23	a8b406e8-3108-4af6-a1f5-a7a72610fa77	skipped	deduplicate	\N	\N	\N	{"inn": null, "sex": "Ж", "email": "d.gorbunova@gmail.com", "login": "diana.gorbunova", "notes": "дата рождения неизвестна", "phone": "+74951234567", "snils": null, "phone2": null, "status": "активен", "cust_id": 23, "marital": "Замужем", "birth_dt": "н/д", "fullname": "Горбунова Диана Сергеевна", "reg_date": "2025-03-15", "loyalty_lvl": "bronze"}	2026-06-07 20:42:54.904709+03
bf6b8dfb-0bf3-4bed-b568-0c9eb1f39309	c85f67f6-d913-424a-a416-c710bfe3ec5f	partner_bd2	24	a4ff128d-9934-40f3-a356-e9a2127694b0	skipped	deduplicate	\N	\N	\N	{"inn": null, "sex": "М", "email": "ion.popescu@mail.ru", "login": "ion.popescu87", "notes": "гражданин Молдовы, ИНН отсутствует", "phone": "+37369123456", "snils": null, "phone2": null, "status": "активен", "cust_id": 24, "marital": "женат", "birth_dt": "15.03.1987", "fullname": "Попеску Ион Александрович", "reg_date": "2022-10-10", "loyalty_lvl": "silver"}	2026-06-07 20:42:54.904709+03
9e842c57-c453-4ad5-9ed8-83544c771ca6	c85f67f6-d913-424a-a416-c710bfe3ec5f	partner_bd2	25	dae8c362-ab3a-45f8-8ea9-e610ecdc6834	skipped	deduplicate	\N	\N	\N	{"inn": "7701-00-445566", "sex": "муж.", "email": "ilya.chernov@gmail.com", "login": "ilya.chernov91", "notes": null, "phone": "8 901 234 56 78", "snils": "321-654-987 00", "phone2": null, "status": "активен", "cust_id": 25, "marital": "не женат", "birth_dt": "5 января 1991", "fullname": "Чернов Илья Павлович", "reg_date": "2023-11-20", "loyalty_lvl": "bronze"}	2026-06-07 20:42:54.904709+03
0f5faf36-1606-4d47-9868-dbe43793ce8a	c85f67f6-d913-424a-a416-c710bfe3ec5f	partner_bd2	9001	\N	error	load	P0001	last_name and first_name are required	\N	{"inn": null, "sex": "М", "email": "error.empty.fullname@example.ru", "login": "error_empty_fullname", "notes": "Демонстрационная ошибка: пустое ФИО", "phone": "+79990000001", "snils": null, "phone2": null, "status": "активен", "cust_id": 9001, "marital": null, "birth_dt": "1990-01-01", "fullname": "", "reg_date": "2026-06-07", "loyalty_lvl": "demo"}	2026-06-07 20:42:54.904709+03
1d658d0b-2680-4bdf-ab27-fe9a2e396dc6	c85f67f6-d913-424a-a416-c710bfe3ec5f	partner_bd2	9002	\N	error	load	P0001	login is required	\N	{"inn": null, "sex": "Ж", "email": "error.empty.login@example.ru", "login": null, "notes": "Демонстрационная ошибка: пустой login", "phone": "+79990000002", "snils": null, "phone2": null, "status": "активен", "cust_id": 9002, "marital": null, "birth_dt": "1992-02-02", "fullname": "Ошибка Без Логина", "reg_date": "2026-06-07", "loyalty_lvl": "demo"}	2026-06-07 20:42:54.904709+03
\.


--
-- Data for Name: migration_person_link; Type: TABLE DATA; Schema: map; Owner: yui
--

COPY map.migration_person_link (link_id, migration_run_id, source_system, source_record_id, target_person_id, created_at) FROM stdin;
555a363d-5964-4869-802d-71cb3dfb7674	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	1	841a025c-4b12-41ab-aaad-d88bdff03406	2026-06-07 20:42:54.833905+03
6b38a81f-6b11-435f-99c9-54dddad1966e	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	2	6295c95d-393f-4dc4-822e-b1fb1e14c4e2	2026-06-07 20:42:54.833905+03
8df63fd2-f0d9-4d82-ba33-abf408035244	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	3	46d321ec-69be-4de6-a08e-31b3607a0a78	2026-06-07 20:42:54.833905+03
326b3f2e-1a45-462c-a327-caf19254f1b1	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	4	46d321ec-69be-4de6-a08e-31b3607a0a78	2026-06-07 20:42:54.833905+03
9144fe8d-b05e-4d4d-bb3f-ebe4d8ff9f47	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	5	9fb760a6-3618-4999-8537-bce4c127800e	2026-06-07 20:42:54.833905+03
6bafcb3b-333c-4f08-8a7c-b5364c854b29	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	6	f3b76a50-5950-4a1e-9132-ac769c5b9e97	2026-06-07 20:42:54.833905+03
81a14971-7afe-4637-94e1-0310ebff70f0	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	7	f3b76a50-5950-4a1e-9132-ac769c5b9e97	2026-06-07 20:42:54.833905+03
f9fa8c10-3300-48be-a54f-d8decaeb17ef	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	8	d4c7f619-e8a9-470d-acc0-d1c976cbbf11	2026-06-07 20:42:54.833905+03
2ccdd383-4088-454c-92af-44b20a036b5e	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	9	fce2d6eb-fc55-4d17-bab0-06e159c14686	2026-06-07 20:42:54.833905+03
64817681-7599-411f-802d-4c45db09c5f0	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	10	9fb760a6-3618-4999-8537-bce4c127800e	2026-06-07 20:42:54.833905+03
22486a69-06f0-438f-900c-0f55350a07bb	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	11	7fb42bd1-ad5a-4582-ac10-9e5bcc2dd8e1	2026-06-07 20:42:54.833905+03
eb484c49-1b01-4c20-a1a1-49627b5867a9	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	12	d4c7f619-e8a9-470d-acc0-d1c976cbbf11	2026-06-07 20:42:54.833905+03
adaee91e-1860-4a40-92c8-756ece224cc2	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	13	50fc12d2-3450-4db8-aebe-c1a1a251254a	2026-06-07 20:42:54.833905+03
fb9d51b0-cf24-4633-b68f-08acbb10262c	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	14	2f4be900-91d9-49ed-855f-8ca0fc20b7aa	2026-06-07 20:42:54.833905+03
66a2d026-f362-4ebc-9bd2-8a9872ed319a	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	15	97a57ff9-a693-4a11-9f75-726a3be36cac	2026-06-07 20:42:54.833905+03
40426f98-03a5-4d70-a152-a53f3483b934	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	16	fad46874-5f76-47dd-bcd6-f40b9ee82cef	2026-06-07 20:42:54.833905+03
1effe139-11e4-40de-822b-37f0181af043	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	17	bb6e1a4b-9893-4b53-b078-c4861951aa77	2026-06-07 20:42:54.833905+03
48e159ab-1b7b-42b9-8afe-67b8d9129f19	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	18	fad46874-5f76-47dd-bcd6-f40b9ee82cef	2026-06-07 20:42:54.833905+03
f47d40ec-a823-49b2-9f5d-ac060dff43ae	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	19	fad46874-5f76-47dd-bcd6-f40b9ee82cef	2026-06-07 20:42:54.833905+03
e02a44ce-9af5-44fd-97d7-4a376d550880	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	20	fad46874-5f76-47dd-bcd6-f40b9ee82cef	2026-06-07 20:42:54.833905+03
9e5a44ec-466f-4d20-a0af-c249b55df094	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	21	dae8c362-ab3a-45f8-8ea9-e610ecdc6834	2026-06-07 20:42:54.833905+03
96617461-f45a-438c-b3de-b5ce6cbbfc29	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	22	dae8c362-ab3a-45f8-8ea9-e610ecdc6834	2026-06-07 20:42:54.833905+03
0900afb3-8357-477c-b784-fb23a95bccdf	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	23	a8b406e8-3108-4af6-a1f5-a7a72610fa77	2026-06-07 20:42:54.833905+03
1b3dabc4-3a71-4031-914a-965c39e815a2	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	24	a4ff128d-9934-40f3-a356-e9a2127694b0	2026-06-07 20:42:54.833905+03
9f32a236-df78-4dc4-8a89-cf7b12d52caf	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	25	dae8c362-ab3a-45f8-8ea9-e610ecdc6834	2026-06-07 20:42:54.833905+03
\.


--
-- Data for Name: migration_unmapped_attribute; Type: TABLE DATA; Schema: map; Owner: yui
--

COPY map.migration_unmapped_attribute (unmapped_attribute_id, migration_run_id, source_system, source_record_id, target_person_id, source_field_name, source_field_value, reason, created_at) FROM stdin;
14ad85c7-6787-42fc-950d-71f0dce96df9	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	1	841a025c-4b12-41ab-aaad-d88bdff03406	customers.marital	женат	Target tech marketplace customer model has no marital status field	2026-06-07 20:42:54.833905+03
e32e87b6-bcc6-481f-b1d8-a2e320709b21	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	2	6295c95d-393f-4dc4-822e-b1fb1e14c4e2	customers.marital	не замужем	Target tech marketplace customer model has no marital status field	2026-06-07 20:42:54.833905+03
1ebf28b7-b396-4d27-8b6b-7fc1c3d1fcf7	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	3	46d321ec-69be-4de6-a08e-31b3607a0a78	customers.marital	холост	Target tech marketplace customer model has no marital status field	2026-06-07 20:42:54.833905+03
838fa611-8766-4c0d-82d3-25814b120e87	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	4	46d321ec-69be-4de6-a08e-31b3607a0a78	customers.marital	Разведён	Target tech marketplace customer model has no marital status field	2026-06-07 20:42:54.833905+03
381951b4-ac1f-4f1e-8cf3-dfde9b392bbf	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	5	9fb760a6-3618-4999-8537-bce4c127800e	customers.marital	замужем	Target tech marketplace customer model has no marital status field	2026-06-07 20:42:54.833905+03
95e2c808-5857-4c37-9f61-7abf22b2a7ec	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	7	f3b76a50-5950-4a1e-9132-ac769c5b9e97	customers.marital	женат	Target tech marketplace customer model has no marital status field	2026-06-07 20:42:54.833905+03
84e047b8-0e44-4bfb-b131-1025277d9996	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	8	d4c7f619-e8a9-470d-acc0-d1c976cbbf11	cust_extra.Sony	да	Attribute was not mapped to target business EAV	2026-06-07 20:42:54.833905+03
4aba93ed-1e6e-4ab2-a81e-9244e3f2b285	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	8	d4c7f619-e8a9-470d-acc0-d1c976cbbf11	customers.marital	одинока	Target tech marketplace customer model has no marital status field	2026-06-07 20:42:54.833905+03
5ebea76f-e4b8-40bc-9c05-ad9223d9af1e	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	9	fce2d6eb-fc55-4d17-bab0-06e159c14686	customers.marital	не указано	Target tech marketplace customer model has no marital status field	2026-06-07 20:42:54.833905+03
7f8f6ac5-89d1-4a87-8568-22e55537c8fb	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	10	9fb760a6-3618-4999-8537-bce4c127800e	customers.marital	разведена	Target tech marketplace customer model has no marital status field	2026-06-07 20:42:54.833905+03
0694bf5d-5aee-4984-991c-03cfda9375e0	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	11	7fb42bd1-ad5a-4582-ac10-9e5bcc2dd8e1	customers.marital	женат	Target tech marketplace customer model has no marital status field	2026-06-07 20:42:54.833905+03
6dac8773-73f2-4734-a77a-5907d4001236	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	12	d4c7f619-e8a9-470d-acc0-d1c976cbbf11	customers.marital	замужем	Target tech marketplace customer model has no marital status field	2026-06-07 20:42:54.833905+03
d91df7f4-9dc4-4854-8ef2-689cc4836a7d	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	13	50fc12d2-3450-4db8-aebe-c1a1a251254a	customers.marital	Холост	Target tech marketplace customer model has no marital status field	2026-06-07 20:42:54.833905+03
7fee8b6c-35cc-4c33-835a-57960aa4c578	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	14	2f4be900-91d9-49ed-855f-8ca0fc20b7aa	customers.marital	не замужем	Target tech marketplace customer model has no marital status field	2026-06-07 20:42:54.833905+03
f27fc901-8c41-42cd-9d6f-df96f27ddba8	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	15	97a57ff9-a693-4a11-9f75-726a3be36cac	customers.marital	вдовец	Target tech marketplace customer model has no marital status field	2026-06-07 20:42:54.833905+03
fcaec4df-2df2-44a3-bef4-b3f9275c0820	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	16	fad46874-5f76-47dd-bcd6-f40b9ee82cef	customers.marital	не женат	Target tech marketplace customer model has no marital status field	2026-06-07 20:42:54.833905+03
79a5917e-5187-4d81-8173-763d06bf68ad	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	17	bb6e1a4b-9893-4b53-b078-c4861951aa77	customers.marital	одинокая	Target tech marketplace customer model has no marital status field	2026-06-07 20:42:54.833905+03
5ee056be-7c06-41ca-8ff3-a7c19efe456e	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	18	fad46874-5f76-47dd-bcd6-f40b9ee82cef	customers.marital	Женат	Target tech marketplace customer model has no marital status field	2026-06-07 20:42:54.833905+03
fdb53805-0143-4966-b0ad-ad125019a7e4	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	19	fad46874-5f76-47dd-bcd6-f40b9ee82cef	customers.marital	замужем	Target tech marketplace customer model has no marital status field	2026-06-07 20:42:54.833905+03
a5dbc9d5-ea4b-4de1-9413-1174e8641c2c	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	20	fad46874-5f76-47dd-bcd6-f40b9ee82cef	customers.marital	женат	Target tech marketplace customer model has no marital status field	2026-06-07 20:42:54.833905+03
f93a1909-6a14-41bb-a941-64aeba179d05	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	21	dae8c362-ab3a-45f8-8ea9-e610ecdc6834	customers.marital	незамужем	Target tech marketplace customer model has no marital status field	2026-06-07 20:42:54.833905+03
0f6e7467-8a74-4113-b6f2-8f2ecc0dce29	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	22	dae8c362-ab3a-45f8-8ea9-e610ecdc6834	customers.marital	холостой	Target tech marketplace customer model has no marital status field	2026-06-07 20:42:54.833905+03
6fa9f7bf-56c2-4ad7-8203-18a8e8af0663	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	23	a8b406e8-3108-4af6-a1f5-a7a72610fa77	customers.marital	Замужем	Target tech marketplace customer model has no marital status field	2026-06-07 20:42:54.833905+03
444bdd3b-88c6-4e2e-885b-fcbbfaf21305	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	24	a4ff128d-9934-40f3-a356-e9a2127694b0	customers.marital	женат	Target tech marketplace customer model has no marital status field	2026-06-07 20:42:54.833905+03
02cbd6a5-1e52-4e3b-bebc-6b7195242232	daad456a-3e43-475b-a2c4-876d32a2d799	partner_bd2	25	dae8c362-ab3a-45f8-8ea9-e610ecdc6834	customers.marital	не женат	Target tech marketplace customer model has no marital status field	2026-06-07 20:42:54.833905+03
\.


--
-- Data for Name: dict_account_status; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.dict_account_status (account_status_id, code, name) FROM stdin;
fdeb39f4-8301-439c-a739-2f4df5f1c2f8	ACTIVE	Активен
8b7fb673-d26b-41a7-ab92-e8ab4d2d62bc	BLOCKED	Заблокирован
53dce74c-6280-4345-9c4f-7debd14be36e	DELETED	Удален
b1d10917-c446-49fb-af11-94dafb800177	PENDING	Ожидает подтверждения
\.


--
-- Data for Name: dict_address_type; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.dict_address_type (address_type_id, code, name) FROM stdin;
be0d8bf7-0858-47c7-881a-ccf7d95381fb	DELIVERY	Адрес доставки
5e334cb2-0e9d-4c04-8548-af62637e7311	HOME	Домашний адрес
4a36f001-2879-498f-9f33-374038e6952d	PICKUP	Пункт выдачи
\.


--
-- Data for Name: dict_city; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.dict_city (city_id, region_id, name) FROM stdin;
7993efd6-2702-4665-b640-5b52efe4da2d	4dda60a5-c25a-4b34-b5cc-f724ddcb41e9	Подольск
3e1a25b9-1e7d-4fc1-bb6d-e27e42d93f12	97d07e4b-f046-47c8-b21b-d06287215bde	Не указан
221d3fa1-7657-44cf-b85e-1e29138490fd	dbf65158-16a9-476a-9d34-845e637a7a04	Ростов-На-Дону
02cc4eca-5296-4b32-ab1e-cd0bf36e0c8c	2c7560eb-cf03-4d03-81f2-92b2348b8a14	Екатеринбург
0aa01595-270a-4c70-a00e-152abbdf8d92	fceff581-a3ec-488d-8d7b-13caa86a4b0f	Казань
777b3e97-dc9c-4c76-b7bd-36a0735353e7	989ec105-d35b-49f2-8996-bd54cd53290f	Новосибирск
a2811bb4-d09a-46b5-875c-2999ceaeec77	4dda60a5-c25a-4b34-b5cc-f724ddcb41e9	Химки
a37eba23-a650-4a69-8535-375fe1e78405	fcd63546-d062-49f0-833b-07d41b6729d0	Краснодар
22c0685f-7021-45b0-9c70-6a934532e90b	cf48c65f-6403-44e5-b966-20d1c2138fdd	Москва
a9ebc0ad-fd69-4061-beab-090715e38647	4859eb8e-eec4-4dd4-9b23-6e1c5362a8e0	Санкт-Петербург
\.


--
-- Data for Name: dict_consent_type; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.dict_consent_type (consent_type_id, code, name, description) FROM stdin;
2a8f174d-543c-4e82-baab-72a3eb21ab23	PERSONAL_DATA_PROCESSING	Обработка персональных данных	Согласие на хранение и обработку персональных данных покупателя
4ff8c1af-3921-4c46-8ce5-821bc13c4a51	MARKETING_EMAIL	Email-рассылка	Согласие на рекламные письма
b3d6764a-ea3b-4d58-8c27-dec8904f7791	MARKETING_SMS	SMS-рассылка	Согласие на рекламные SMS
615e20ef-22cc-4dca-9c2c-9819788cade8	DATA_TRANSFER_TO_PARTNERS	Передача данных партнерам	Согласие на передачу данных службам доставки и партнерам
\.


--
-- Data for Name: dict_contact_type; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.dict_contact_type (contact_type_id, code, name) FROM stdin;
39457f53-d8cb-4441-bde1-1fb815cd342b	EMAIL	Email
5a1aeff5-534d-4af0-8628-d4d16e03fc93	PHONE	Телефон
1e8b491c-4e17-4c68-835c-0565d42d7d74	TELEGRAM	Telegram
a0da05f6-cb98-4c6b-a503-4947100618ba	WHATSAPP	WhatsApp
\.


--
-- Data for Name: dict_country; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.dict_country (country_id, iso_code, name) FROM stdin;
81081f7f-8cba-480b-801d-c5be9d434755	\N	Россия
\.


--
-- Data for Name: dict_document_type; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.dict_document_type (document_type_id, code, name) FROM stdin;
138e4cc4-46b7-4036-ad46-bea30038a441	PASSPORT_RF	Паспорт РФ
c72a246b-3cdb-4f2b-97ba-321340ca08b9	DRIVER_LICENSE	Водительское удостоверение
30dcd865-b7b2-47b2-b74a-357ae8b30410	MILITARY_ID	Военный билет
6af8052b-127f-45fa-a544-98a450ed7642	FOREIGN_PASSPORT	Заграничный паспорт
\.


--
-- Data for Name: dict_gender; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.dict_gender (gender_id, code, name) FROM stdin;
2925fdbb-cde4-4fd0-8157-414bce95e48b	MALE	Мужской
f8c577eb-46f5-44ae-a4a0-c7128bc042b8	FEMALE	Женский
16979364-5d23-4678-b91f-c2ff68463797	UNKNOWN	Не указан
\.


--
-- Data for Name: dict_identifier_type; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.dict_identifier_type (identifier_type_id, code, name) FROM stdin;
217445d4-fc9a-4e9f-9e20-382146deb3fd	INN	ИНН
21dce3a5-4f30-4b1e-b6b0-6f9625a7cdda	SNILS	СНИЛС
b9303d76-0a8c-4ae9-a3bc-bcdff6cfb919	LOYALTY_CARD	Карта лояльности
\.


--
-- Data for Name: dict_region; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.dict_region (region_id, country_id, name) FROM stdin;
97d07e4b-f046-47c8-b21b-d06287215bde	81081f7f-8cba-480b-801d-c5be9d434755	Не указан
dbf65158-16a9-476a-9d34-845e637a7a04	81081f7f-8cba-480b-801d-c5be9d434755	Ростовская область
2c7560eb-cf03-4d03-81f2-92b2348b8a14	81081f7f-8cba-480b-801d-c5be9d434755	Свердловская область
fceff581-a3ec-488d-8d7b-13caa86a4b0f	81081f7f-8cba-480b-801d-c5be9d434755	Татарстан
989ec105-d35b-49f2-8996-bd54cd53290f	81081f7f-8cba-480b-801d-c5be9d434755	Новосибирская область
4dda60a5-c25a-4b34-b5cc-f724ddcb41e9	81081f7f-8cba-480b-801d-c5be9d434755	Московская область
fcd63546-d062-49f0-833b-07d41b6729d0	81081f7f-8cba-480b-801d-c5be9d434755	Краснодарский край
cf48c65f-6403-44e5-b966-20d1c2138fdd	81081f7f-8cba-480b-801d-c5be9d434755	Москва
4859eb8e-eec4-4dd4-9b23-6e1c5362a8e0	81081f7f-8cba-480b-801d-c5be9d434755	Санкт-Петербург
\.


--
-- Data for Name: dict_street; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.dict_street (street_id, city_id, name) FROM stdin;
8318ded4-2e1c-4825-9daf-ed38990c60a4	a2811bb4-d09a-46b5-875c-2999ceaeec77	Молодежная
338143c3-a064-4fc2-b31d-cdab158f8599	0aa01595-270a-4c70-a00e-152abbdf8d92	Баумана
e4f73f30-4e0d-4eb4-8dfb-66f16b641803	777b3e97-dc9c-4c76-b7bd-36a0735353e7	Красный проспект
361e269f-9835-4766-abb4-bc90ddc793f6	22c0685f-7021-45b0-9c70-6a934532e90b	Арбат
1c038252-3efb-43a1-bfde-52ae1425f7db	7993efd6-2702-4665-b640-5b52efe4da2d	Садовая
834fb9f6-d056-477d-a2e1-a6ccc83cd69c	a9ebc0ad-fd69-4061-beab-090715e38647	Литейный проспект
a8e26a4c-67d9-4d84-ad89-2ee8df0b8a8a	0aa01595-270a-4c70-a00e-152abbdf8d92	Кремлевская
5c7b4389-facb-4c06-9858-7f87c66cd9e8	777b3e97-dc9c-4c76-b7bd-36a0735353e7	Карла Маркса
d1d2103a-bb73-4d97-b1e5-6c411f511942	22c0685f-7021-45b0-9c70-6a934532e90b	Профсоюзная
8a1dee18-8309-4011-a7f0-8b327bf17dc7	a37eba23-a650-4a69-8535-375fe1e78405	Красная
fb04f09e-3575-4ed9-90fa-fbd52c4b4548	221d3fa1-7657-44cf-b85e-1e29138490fd	Большая Садовая
1f1327f0-2d11-42a4-b420-05576890f472	02cc4eca-5296-4b32-ab1e-cd0bf36e0c8c	Малышева
93eb7464-1485-4506-bd18-838c170e112a	a9ebc0ad-fd69-4061-beab-090715e38647	Невский проспект
3f98d1e7-4946-4a46-be0f-da974244ddb9	a2811bb4-d09a-46b5-875c-2999ceaeec77	Юбилейный проспект
ec14d89b-be08-4354-a273-c4abb23a6c93	22c0685f-7021-45b0-9c70-6a934532e90b	Лесной пер.
05ac72f4-4ad2-4036-a1a8-e648665bf604	a9ebc0ad-fd69-4061-beab-090715e38647	Маршала Жукова
b24fc8d3-daf3-4681-b494-33f6e63fe204	22c0685f-7021-45b0-9c70-6a934532e90b	Коньково
1bae3535-32a9-4bd2-883d-4796b0dfe912	22c0685f-7021-45b0-9c70-6a934532e90b	4-й Лесной пер.
99d7118c-feb5-4042-aefb-fe6d5203f73b	a37eba23-a650-4a69-8535-375fe1e78405	Северная
0d38c32b-b7ed-49d1-98c0-78dd84d2397c	221d3fa1-7657-44cf-b85e-1e29138490fd	Ленина
ab144eee-5c52-4ad5-9ce1-b5d10e5e5e79	a9ebc0ad-fd69-4061-beab-090715e38647	Кронверкский пр-т
e94b124a-a744-4775-89e7-73a9eab64f41	22c0685f-7021-45b0-9c70-6a934532e90b	Тверская
26a8f7cd-6c5a-42d5-9f62-6266c1845725	22c0685f-7021-45b0-9c70-6a934532e90b	шоссе 34
10523473-7709-4c6f-82db-4dc9a4b20886	a9ebc0ad-fd69-4061-beab-090715e38647	пр -т
6321eddf-adb5-49ae-b175-4184beba5b76	777b3e97-dc9c-4c76-b7bd-36a0735353e7	Красный проспект 26/5
2569d86f-284d-4ac4-9be3-81d52f48a0c2	02cc4eca-5296-4b32-ab1e-cd0bf36e0c8c	ул. Ленина 100
41c7cb3c-484c-44d9-8cd6-0cb179fbf4b7	22c0685f-7021-45b0-9c70-6a934532e90b	ул. Пушкина
0a6b2e12-37f7-4d1b-9342-0f3f6b91c1d0	3e1a25b9-1e7d-4fc1-bb6d-e27e42d93f12	ул Садовая 5
55ce6bac-79ed-402f-b481-417019fe3ea1	22c0685f-7021-45b0-9c70-6a934532e90b	пр. Мира 55-А
9cba0e56-e680-47ed-85d9-eef32c70ba41	a9ebc0ad-fd69-4061-beab-090715e38647	пр. 100
8d7aa7f8-72ed-4001-841c-5546371680d9	22c0685f-7021-45b0-9c70-6a934532e90b	ул. Тверская
b223a903-9b98-4c65-afb7-dca66543ed13	221d3fa1-7657-44cf-b85e-1e29138490fd	Пр. Ленина 15 оф. 304
165ee861-eeee-49ae-b5a0-196f77b225c4	02cc4eca-5296-4b32-ab1e-cd0bf36e0c8c	ул. Малышева 51-79
791a6963-3497-4196-a422-1a3137764ce9	22c0685f-7021-45b0-9c70-6a934532e90b	ул. 4-я Тверская-Ямская 5
27c37556-2685-4a41-b7fe-934bd42bd021	0aa01595-270a-4c70-a00e-152abbdf8d92	ул. Баумана 10
3c90ad20-faf2-4ced-a589-8404011b729f	a9ebc0ad-fd69-4061-beab-090715e38647	ул. Маршала Жукова
b221255e-3d48-42ce-92ae-293bb2688eb9	777b3e97-dc9c-4c76-b7bd-36a0735353e7	пр-т Карла Маркса 7 кв 19
66272a9f-14f6-43d3-9a59-8e07229b7b74	a2811bb4-d09a-46b5-875c-2999ceaeec77	пр. 78
5860990f-895a-412c-89fb-84ed842afe0f	a37eba23-a650-4a69-8535-375fe1e78405	Краснодар Красная 135
c6be5bde-64a7-48a5-b737-14aa9c9e1c93	22c0685f-7021-45b0-9c70-6a934532e90b	пер. 4
5dbbeca0-e5e0-4265-8e04-af3323510afe	a9ebc0ad-fd69-4061-beab-090715e38647	проспект 44
\.


--
-- Data for Name: dict_verification_status; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.dict_verification_status (verification_status_id, code, name) FROM stdin;
cb5d0166-d2b0-466e-a948-5c60b6d90522	NOT_CHECKED	Не проверен
1baa0e63-e8ee-408b-a4de-3392d3943d14	PENDING	На проверке
019fba6a-3f09-4274-83f6-cb7dfbc79b14	VERIFIED	Проверен
8c6267b2-c98b-4f9f-8622-56c47ae63e1b	REJECTED	Отклонен
\.


--
-- Data for Name: person_identifier; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.person_identifier (identifier_id, person_id, identifier_type_id, identifier_value, raw_value, is_verified) FROM stdin;
a0138b90-92f6-4d7d-aab3-7c12513e680d	97a57ff9-a693-4a11-9f75-726a3be36cac	217445d4-fc9a-4e9f-9e20-382146deb3fd	770123456789	ИНН: 7701-234567-89	f
bcd8585c-0bbc-4f85-a0fd-09ae4f40c2ee	c4a6968d-5546-4f23-a490-a3d665ad5345	b9303d76-0a8c-4ae9-a3bc-bcdff6cfb919	00077	карта TECH-00077	t
896d2741-135f-49b8-a920-fc9ee55b8847	ae5e8672-b19f-4867-91af-c02611ace804	b9303d76-0a8c-4ae9-a3bc-bcdff6cfb919	00001	карта TECH-00001	t
715cf4e1-9ab0-4462-90e2-6764c20f52f6	1c32e472-5262-46d0-be59-6c2f27e189f4	b9303d76-0a8c-4ae9-a3bc-bcdff6cfb919	00002	карта TECH-00002	t
a217ca1d-ed55-43b4-b218-244985731774	7497918d-bdcf-4431-b365-db195d277432	b9303d76-0a8c-4ae9-a3bc-bcdff6cfb919	00003	карта TECH-00003	t
6f034d6f-44d5-48ab-a690-008df9487063	49582c70-48ce-4e74-8ed9-89b94943aabf	b9303d76-0a8c-4ae9-a3bc-bcdff6cfb919	00004	карта TECH-00004	t
79d1249d-148c-4432-addb-121878be02bc	63c6d99b-46ff-489f-a539-993a6f4d5f2f	b9303d76-0a8c-4ae9-a3bc-bcdff6cfb919	00005	карта TECH-00005	t
cff7582e-917a-4f27-8367-f884b4e59d48	56b3b63c-803d-4da7-ab79-fe95491f18e5	b9303d76-0a8c-4ae9-a3bc-bcdff6cfb919	00006	карта TECH-00006	t
c8a57b8d-4b90-4232-b073-525107904996	76409892-50ee-45f8-b1b6-487129468310	b9303d76-0a8c-4ae9-a3bc-bcdff6cfb919	00007	карта TECH-00007	t
0e8b165c-6cc1-4d5c-b79f-a9b1346e9529	74b11c35-2ca0-424d-888d-b03ead311080	b9303d76-0a8c-4ae9-a3bc-bcdff6cfb919	00008	карта TECH-00008	t
efcbb348-5485-41ea-a114-11462746940d	7f4a4ca6-14f9-4e19-8928-ad5959e53d38	b9303d76-0a8c-4ae9-a3bc-bcdff6cfb919	00009	карта TECH-00009	t
a9b4de81-6c23-4f21-9976-860b4668c4df	7869118c-d5c9-4c96-8332-fffd20599e5a	b9303d76-0a8c-4ae9-a3bc-bcdff6cfb919	00010	карта TECH-00010	t
8a8e8daa-1e70-48d7-a7f8-a57ed124ba72	7fff1799-25cd-4a7a-be97-d50baae6e254	b9303d76-0a8c-4ae9-a3bc-bcdff6cfb919	00011	карта TECH-00011	t
b6e77fed-f4e2-4721-9239-d53b0e065d5d	a86c4ecc-8947-4a30-968f-ff444042e54e	b9303d76-0a8c-4ae9-a3bc-bcdff6cfb919	00012	карта TECH-00012	t
af355709-d200-4006-94fc-74d0433b6f98	22738087-7bfc-488e-88e3-c37f700e689c	b9303d76-0a8c-4ae9-a3bc-bcdff6cfb919	00013	карта TECH-00013	t
78c13c43-8cf8-46c8-8576-db6e14421463	dae8c362-ab3a-45f8-8ea9-e610ecdc6834	b9303d76-0a8c-4ae9-a3bc-bcdff6cfb919	00014	карта TECH-00014	t
b396dcd9-c01e-4419-98be-45d7ad0a8791	545eb50f-a7c3-40c7-9d14-66ee6aea78e3	b9303d76-0a8c-4ae9-a3bc-bcdff6cfb919	00015	карта TECH-00015	t
3e9c706b-24ee-47c1-a84b-64b329fe2aa1	a5c56ab3-74c4-4fb6-8987-6968ad93850c	b9303d76-0a8c-4ae9-a3bc-bcdff6cfb919	00016	карта TECH-00016	t
183880db-7800-42cc-9b53-33e263966885	a8b406e8-3108-4af6-a1f5-a7a72610fa77	b9303d76-0a8c-4ae9-a3bc-bcdff6cfb919	00017	карта TECH-00017	t
76d0c473-a7ca-45d0-abfa-0a9309932b7c	c4072987-8e34-43a3-97c0-1f5543b9597e	b9303d76-0a8c-4ae9-a3bc-bcdff6cfb919	00018	карта TECH-00018	t
fa2deca3-c453-47f4-9bdc-4f26ca259eec	46f18937-fb05-42cf-b002-d9af780492e4	b9303d76-0a8c-4ae9-a3bc-bcdff6cfb919	00019	карта TECH-00019	t
0f3f0492-b780-43f8-81ec-b0296339b8e8	d4c7f619-e8a9-470d-acc0-d1c976cbbf11	b9303d76-0a8c-4ae9-a3bc-bcdff6cfb919	00020	карта TECH-00020	t
87553571-aa8c-4d6a-a5ad-95eea33a128c	841a025c-4b12-41ab-aaad-d88bdff03406	217445d4-fc9a-4e9f-9e20-382146deb3fd	7743001234	7743001234	f
143aaf90-e448-4132-be1b-baa2e8d197fc	841a025c-4b12-41ab-aaad-d88bdff03406	21dce3a5-4f30-4b1e-b6b0-6f9625a7cdda	11223344595	112-233-445 95	f
75036121-df43-4c0b-925f-5b2eb57b3f61	6295c95d-393f-4dc4-822e-b1fb1e14c4e2	217445d4-fc9a-4e9f-9e20-382146deb3fd	770100223344	7701 00 223344	f
5ae82f96-ca6e-4d27-bb39-c1dae44bc974	46d321ec-69be-4de6-a08e-31b3607a0a78	217445d4-fc9a-4e9f-9e20-382146deb3fd	540100998877	540100 998877	f
cdd94451-c708-4e14-b418-be40485d94b8	46d321ec-69be-4de6-a08e-31b3607a0a78	21dce3a5-4f30-4b1e-b6b0-6f9625a7cdda	32145678901	321 456 789 01	f
4fea5993-261e-4a10-9ff4-3ab2219e7226	f3b76a50-5950-4a1e-9132-ac769c5b9e97	217445d4-fc9a-4e9f-9e20-382146deb3fd	6612005544332	6612005544332	f
6cdc6bf2-3b2b-4a41-a1a5-9544220edeee	f3b76a50-5950-4a1e-9132-ac769c5b9e97	21dce3a5-4f30-4b1e-b6b0-6f9625a7cdda	55566677700	55566677700	f
2ed91877-63b2-4e75-b62e-22b1df1a145c	d4c7f619-e8a9-470d-acc0-d1c976cbbf11	21dce3a5-4f30-4b1e-b6b0-6f9625a7cdda	99988877766	999 888 777 66	f
3bdc1549-f931-4add-8f9f-8324d6b178f6	9fb760a6-3618-4999-8537-bce4c127800e	217445d4-fc9a-4e9f-9e20-382146deb3fd	616400112233	6 164 001 122 33	f
31b2e685-e621-479b-b6fd-0bc46c4eeaf8	9fb760a6-3618-4999-8537-bce4c127800e	21dce3a5-4f30-4b1e-b6b0-6f9625a7cdda	10020030040	100.200.300-40	f
b2b5a851-2cbd-4e4c-86a2-80aead6056bd	7fb42bd1-ad5a-4582-ac10-9e5bcc2dd8e1	217445d4-fc9a-4e9f-9e20-382146deb3fd	7743000132	7 743 000 132	f
71b1d2f8-3229-433b-9097-415c43b5aa5a	7fb42bd1-ad5a-4582-ac10-9e5bcc2dd8e1	21dce3a5-4f30-4b1e-b6b0-6f9625a7cdda	77700011200	77700011200	f
5868da8c-d1c6-48e7-9091-330c1a30efdd	d4c7f619-e8a9-470d-acc0-d1c976cbbf11	217445d4-fc9a-4e9f-9e20-382146deb3fd	7701987654	7701987654	f
a58d4ab0-ca1d-4529-9e6f-4ce0fe7c9eec	d4c7f619-e8a9-470d-acc0-d1c976cbbf11	21dce3a5-4f30-4b1e-b6b0-6f9625a7cdda	44556677899	445-566-778 99	f
e67e6a2b-54c4-4719-bf57-c8d338281570	50fc12d2-3450-4db8-aebe-c1a1a251254a	217445d4-fc9a-4e9f-9e20-382146deb3fd	504000123456	5040-001-234-56	f
2be00acf-9eef-4a86-b10b-cf335d85cf05	50fc12d2-3450-4db8-aebe-c1a1a251254a	21dce3a5-4f30-4b1e-b6b0-6f9625a7cdda	98765432100	98765432100	f
efcb3535-7a2a-487e-897d-a50695bfc4b5	2f4be900-91d9-49ed-855f-8ca0fc20b7aa	217445d4-fc9a-4e9f-9e20-382146deb3fd	5030101234	5030101234	f
c52b5a85-2e27-4ae2-9047-efec3ade2515	97a57ff9-a693-4a11-9f75-726a3be36cac	217445d4-fc9a-4e9f-9e20-382146deb3fd	7700000000	7700000000	f
f7736f99-cf17-4eeb-bbf4-a1ae5db26ca2	fad46874-5f76-47dd-bcd6-f40b9ee82cef	217445d4-fc9a-4e9f-9e20-382146deb3fd	5050123456	5050 1234 56	f
f8b8a515-da1e-4a52-a38b-f7d4fb8546c1	fad46874-5f76-47dd-bcd6-f40b9ee82cef	21dce3a5-4f30-4b1e-b6b0-6f9625a7cdda	88899900011	88899900011	f
9632cd0c-b3b1-450a-a939-e158a7114cb5	fad46874-5f76-47dd-bcd6-f40b9ee82cef	217445d4-fc9a-4e9f-9e20-382146deb3fd	7714998877	7714998877	f
00b7169a-d486-4fbb-bacc-0a4bd13d72e3	fad46874-5f76-47dd-bcd6-f40b9ee82cef	21dce3a5-4f30-4b1e-b6b0-6f9625a7cdda	00100200304	001 002 003 04	f
afaad35c-84c0-46b2-b7e2-653130546d3c	97a57ff9-a693-4a11-9f75-726a3be36cac	21dce3a5-4f30-4b1e-b6b0-6f9625a7cdda	12345678900	123-456-789 00	f
ca6751bb-3a0f-4ccd-b3d6-d851ef78055c	dae8c362-ab3a-45f8-8ea9-e610ecdc6834	217445d4-fc9a-4e9f-9e20-382146deb3fd	770100445566	7701-00-445566	f
34766bc8-2a50-488f-854f-ef58333b2fe6	bb6e1a4b-9893-4b53-b078-c4861951aa77	21dce3a5-4f30-4b1e-b6b0-6f9625a7cdda	32165498700	321-654-987 00	f
\.


--
-- Data for Name: person_profile; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.person_profile (person_id, last_name, first_name, middle_name, birth_date, birth_date_raw, gender_id, created_at) FROM stdin;
6c96c88a-10d3-4d86-9ba0-fc66136db266	Петрова	Мария	\N	1990-05-01	01.05.90	f8c577eb-46f5-44ae-a4a0-c7128bc042b8	2026-06-07 20:42:54.71933+03
c4a6968d-5546-4f23-a490-a3d665ad5345	Сидоров	Алексей	Павлович	1995-12-03	1995-12-03	2925fdbb-cde4-4fd0-8157-414bce95e48b	2026-06-07 20:42:54.726685+03
861d02aa-6c7f-4304-b410-2664595578e3	Кузнецова	Елена	\N	\N	31/02/1988	f8c577eb-46f5-44ae-a4a0-c7128bc042b8	2026-06-07 20:42:54.730588+03
eccefedc-537c-4f94-9fa4-521eeaedc5f5	Орлов	Денис	\N	\N	\N	16979364-5d23-4678-b91f-c2ff68463797	2026-06-07 20:42:54.734272+03
ae5e8672-b19f-4867-91af-c02611ace804	Смирнов	Павел	Олегович	1989-04-12	1989/04/12	2925fdbb-cde4-4fd0-8157-414bce95e48b	2026-06-07 20:42:54.738303+03
1c32e472-5262-46d0-be59-6c2f27e189f4	Васильева	Ольга	Игоревна	1991-09-12	12.09.1991	f8c577eb-46f5-44ae-a4a0-c7128bc042b8	2026-06-07 20:42:54.738303+03
7497918d-bdcf-4431-b365-db195d277432	Никитин	Роман	\N	1984-11-07	7 ноября 1984 года	2925fdbb-cde4-4fd0-8157-414bce95e48b	2026-06-07 20:42:54.738303+03
49582c70-48ce-4e74-8ed9-89b94943aabf	Медведева	Ирина	Сергеевна	2003-03-03	03.03.03	f8c577eb-46f5-44ae-a4a0-c7128bc042b8	2026-06-07 20:42:54.738303+03
63c6d99b-46ff-489f-a539-993a6f4d5f2f	Алексеев	Григорий	Андреевич	1978-10-30	1978-10-30	2925fdbb-cde4-4fd0-8157-414bce95e48b	2026-06-07 20:42:54.738303+03
56b3b63c-803d-4da7-ab79-fe95491f18e5	Романова	Дарья	\N	\N	н/д	f8c577eb-46f5-44ae-a4a0-c7128bc042b8	2026-06-07 20:42:54.738303+03
76409892-50ee-45f8-b1b6-487129468310	Гаврилов	Максим	Петрович	1982-02-14	14-02-1982	2925fdbb-cde4-4fd0-8157-414bce95e48b	2026-06-07 20:42:54.738303+03
74b11c35-2ca0-424d-888d-b03ead311080	Егорова	Виктория	Алексеевна	1994-06-30	1994-06-30	f8c577eb-46f5-44ae-a4a0-c7128bc042b8	2026-06-07 20:42:54.738303+03
7f4a4ca6-14f9-4e19-8928-ad5959e53d38	Павлов	Степан	Денисович	1991-03-05	March 5, 1991	2925fdbb-cde4-4fd0-8157-414bce95e48b	2026-06-07 20:42:54.738303+03
7869118c-d5c9-4c96-8332-fffd20599e5a	Фомина	Ксения	\N	1970-12-25	25/12/1970	f8c577eb-46f5-44ae-a4a0-c7128bc042b8	2026-06-07 20:42:54.738303+03
7fff1799-25cd-4a7a-be97-d50baae6e254	Беляев	Матвей	Ильич	2000-01-01	2000-01-01	2925fdbb-cde4-4fd0-8157-414bce95e48b	2026-06-07 20:42:54.738303+03
a86c4ecc-8947-4a30-968f-ff444042e54e	Соловьева	Наталья	Романовна	\N	31/02/1988	f8c577eb-46f5-44ae-a4a0-c7128bc042b8	2026-06-07 20:42:54.738303+03
22738087-7bfc-488e-88e3-c37f700e689c	Титов	Арсений	\N	1991-01-05	5 января 1991	2925fdbb-cde4-4fd0-8157-414bce95e48b	2026-06-07 20:42:54.738303+03
545eb50f-a7c3-40c7-9d14-66ee6aea78e3	Крылов	Федор	Вячеславович	1979-11-30	1979-11-30	2925fdbb-cde4-4fd0-8157-414bce95e48b	2026-06-07 20:42:54.738303+03
a5c56ab3-74c4-4fb6-8987-6968ad93850c	Зуева	Марина	\N	1967-08-15	15 августа 1967 года	f8c577eb-46f5-44ae-a4a0-c7128bc042b8	2026-06-07 20:42:54.738303+03
c4072987-8e34-43a3-97c0-1f5543b9597e	Макарова	Юлия	Олеговна	1985-03-15	1985/03/15	f8c577eb-46f5-44ae-a4a0-c7128bc042b8	2026-06-07 20:42:54.738303+03
46f18937-fb05-42cf-b002-d9af780492e4	Дорофеев	Лев	\N	\N	ноябрь 1979	2925fdbb-cde4-4fd0-8157-414bce95e48b	2026-06-07 20:42:54.738303+03
841a025c-4b12-41ab-aaad-d88bdff03406	Иванов	Иван	Сергеевич	1988-03-15	1988-03-15	2925fdbb-cde4-4fd0-8157-414bce95e48b	2026-06-07 20:42:54.833905+03
6295c95d-393f-4dc4-822e-b1fb1e14c4e2	Петрова	Анна	Михайловна	1992-07-15	15.07.1992	f8c577eb-46f5-44ae-a4a0-c7128bc042b8	2026-06-07 20:42:54.833905+03
46d321ec-69be-4de6-a08e-31b3607a0a78	Сидоров	Борис	Геннадьевич	1985-08-15	15-08-1985	2925fdbb-cde4-4fd0-8157-414bce95e48b	2026-06-07 20:42:54.833905+03
f3b76a50-5950-4a1e-9132-ac769c5b9e97	Лебедев	Сергей	Николаевич	1990-05-01	ноябрь 1979	2925fdbb-cde4-4fd0-8157-414bce95e48b	2026-06-07 20:42:54.833905+03
fce2d6eb-fc55-4d17-bab0-06e159c14686	Михайлов	Андрей	\N	\N	\N	2925fdbb-cde4-4fd0-8157-414bce95e48b	2026-06-07 20:42:54.833905+03
9fb760a6-3618-4999-8537-bce4c127800e	Федорова	Юлия	Олеговна	1985-03-15	1985/03/15	f8c577eb-46f5-44ae-a4a0-c7128bc042b8	2026-06-07 20:42:54.833905+03
7fb42bd1-ad5a-4582-ac10-9e5bcc2dd8e1	Попов	Виктор	Геннадьевич	1972-11-03	03.11.1972	2925fdbb-cde4-4fd0-8157-414bce95e48b	2026-06-07 20:42:54.833905+03
d4c7f619-e8a9-470d-acc0-d1c976cbbf11	Кузнецова	Анна	Максимовна	1993-12-25	25 декабря 1993 года	f8c577eb-46f5-44ae-a4a0-c7128bc042b8	2026-06-07 20:42:54.738303+03
50fc12d2-3450-4db8-aebe-c1a1a251254a	Зайцев	Роман	Евгеньевич	1991-04-07	07-04-1991	2925fdbb-cde4-4fd0-8157-414bce95e48b	2026-06-07 20:42:54.833905+03
2f4be900-91d9-49ed-855f-8ca0fc20b7aa	Белова	К.	\N	1998-06-22	1998/06/22	f8c577eb-46f5-44ae-a4a0-c7128bc042b8	2026-06-07 20:42:54.833905+03
97a57ff9-a693-4a11-9f75-726a3be36cac	Тарасов	Константин	Игоревич	1970-12-25	25/12/1970	16979364-5d23-4678-b91f-c2ff68463797	2026-06-07 20:42:54.701885+03
bb6e1a4b-9893-4b53-b078-c4861951aa77	Фролова	Наталья	\N	1991-03-05	March 5, 1991	f8c577eb-46f5-44ae-a4a0-c7128bc042b8	2026-06-07 20:42:54.833905+03
fad46874-5f76-47dd-bcd6-f40b9ee82cef	Богданов	Виктор	Анатольевич	1967-08-15	15 августа 1967 года	2925fdbb-cde4-4fd0-8157-414bce95e48b	2026-06-07 20:42:54.833905+03
a8b406e8-3108-4af6-a1f5-a7a72610fa77	Горбунова	Диана	Сергеевна	\N	н/д	f8c577eb-46f5-44ae-a4a0-c7128bc042b8	2026-06-07 20:42:54.738303+03
a4ff128d-9934-40f3-a356-e9a2127694b0	Попеску	Ион	Александрович	1987-03-15	15.03.1987	2925fdbb-cde4-4fd0-8157-414bce95e48b	2026-06-07 20:42:54.833905+03
dae8c362-ab3a-45f8-8ea9-e610ecdc6834	Чернов	Илья	Павлович	1991-01-05	5 января 1991	2925fdbb-cde4-4fd0-8157-414bce95e48b	2026-06-07 20:42:54.738303+03
\.


--
-- Data for Name: user_account; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.user_account (account_id, person_id, login, password_hash, account_status_id, registered_at, last_login_at) FROM stdin;
4ea35dc3-7905-4012-ad88-8f19d1d7b69a	6c96c88a-10d3-4d86-9ba0-fc66136db266	m.pet.rova@example.com	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.71933+03	\N
967e7741-6f3d-4855-92fb-c26a1ed94006	c4a6968d-5546-4f23-a490-a3d665ad5345	alexey.sid	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.726685+03	\N
0ab05877-8ae1-4cdd-9644-c49d27190d7c	861d02aa-6c7f-4304-b410-2664595578e3	elena_k	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.730588+03	\N
cd433189-8a7e-4137-85ff-df99e816ffb2	eccefedc-537c-4f94-9fa4-521eeaedc5f5	denis.orlov@example.net	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.734272+03	\N
dbfa305c-b7f8-4f83-8578-dddb967833fa	ae5e8672-b19f-4867-91af-c02611ace804	p.smirnov.tech	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.738303+03	\N
0ed818a0-3dc6-46e9-a1b7-6d78774258ab	1c32e472-5262-46d0-be59-6c2f27e189f4	olga.v.tech	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.738303+03	\N
289a108a-5792-4902-9a14-d94cb9b62746	7497918d-bdcf-4431-b365-db195d277432	roman_nikitin	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.738303+03	\N
3c84bb2b-718c-4fde-aca9-7711a38014f9	49582c70-48ce-4e74-8ed9-89b94943aabf	irina.medvedeva	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.738303+03	\N
dea640de-a3e2-4358-aa11-7411caab6a9a	63c6d99b-46ff-489f-a539-993a6f4d5f2f	g.alekseev	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.738303+03	\N
bf719ceb-7208-4994-b276-5fd0427031f6	56b3b63c-803d-4da7-ab79-fe95491f18e5	d.romanova	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.738303+03	\N
9b3b9482-c53b-406a-8295-e276e53a232c	76409892-50ee-45f8-b1b6-487129468310	max.gavrilov	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.738303+03	\N
0b60109b-5aa9-47a4-898b-12950d65ae4b	74b11c35-2ca0-424d-888d-b03ead311080	v.egorova	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.738303+03	\N
23b1eab6-c9f9-4d61-a5c1-a40cc731775a	7f4a4ca6-14f9-4e19-8928-ad5959e53d38	stepan.pavlov	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.738303+03	\N
f8dde897-525f-4851-a180-36bcce62782d	7869118c-d5c9-4c96-8332-fffd20599e5a	ks.fomina	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.738303+03	\N
ce2a8263-a792-432f-a726-2799da499fb4	7fff1799-25cd-4a7a-be97-d50baae6e254	matvey.belyaev	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.738303+03	\N
ecb58c27-a356-4d61-a952-49651bcf2af9	a86c4ecc-8947-4a30-968f-ff444042e54e	n.solovieva	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.738303+03	\N
771d2801-30b1-4913-82ae-efde39571854	22738087-7bfc-488e-88e3-c37f700e689c	ars.titov	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.738303+03	\N
dcb95ff6-5444-4ed4-9db2-bd02bcbc1c1f	545eb50f-a7c3-40c7-9d14-66ee6aea78e3	fedor.krylov	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.738303+03	\N
b08ef5d3-78e6-4727-adde-fb654600b615	a5c56ab3-74c4-4fb6-8987-6968ad93850c	marina.zueva	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.738303+03	\N
537014aa-8472-4844-8f5c-776ff61da756	c4072987-8e34-43a3-97c0-1f5543b9597e	y.makarova	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.738303+03	\N
8bd5408b-4018-4806-9521-6fca5b8afcaf	46f18937-fb05-42cf-b002-d9af780492e4	lev.dorofeev	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.738303+03	\N
6b3cff6c-429f-4934-b84b-9c42ff8623be	841a025c-4b12-41ab-aaad-d88bdff03406	ivan.ivanov88	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.833905+03	\N
748cd3ed-6ac8-4de9-ac09-9ca4ee2ad065	6295c95d-393f-4dc4-822e-b1fb1e14c4e2	anna.petrova	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.833905+03	\N
9e579863-ce4d-44e7-81f1-04e55ec2748e	46d321ec-69be-4de6-a08e-31b3607a0a78	b.sidorov85	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.833905+03	\N
7d28a719-d0a4-4e54-9a23-e0717c4961c5	f3b76a50-5950-4a1e-9132-ac769c5b9e97	s.lebedev79	\N	8b7fb673-d26b-41a7-ab92-e8ab4d2d62bc	2026-06-07 20:42:54.833905+03	\N
6039a6a1-f55e-4758-adcf-deb73dc59a88	fce2d6eb-fc55-4d17-bab0-06e159c14686	a.mikhaylov	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.833905+03	\N
90f305a8-a247-4cb8-ae84-ea2f2a7c8fe7	9fb760a6-3618-4999-8537-bce4c127800e	yuliya.fedorova85	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.833905+03	\N
b0aab23d-23ed-4471-aaff-7650239fff74	7fb42bd1-ad5a-4582-ac10-9e5bcc2dd8e1	viktor.popov72	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.833905+03	\N
c2ecc4a1-dfea-4692-97ea-c9dde6c05414	d4c7f619-e8a9-470d-acc0-d1c976cbbf11	anna.kuznetsova93	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.738303+03	\N
9848bb5d-8c7d-4677-9759-723747f88431	50fc12d2-3450-4db8-aebe-c1a1a251254a	roman.zaitsev91	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.833905+03	\N
1c7be2cb-ac4a-4527-b072-428b9d8dadc7	2f4be900-91d9-49ed-855f-8ca0fc20b7aa	belova_ks98	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.833905+03	\N
ff11abe9-e85c-4c43-b04c-786af330bc31	97a57ff9-a693-4a11-9f75-726a3be36cac	k.tarasov70	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.701885+03	\N
44c5dfa7-f5ce-447a-a073-c3e8b47e3088	bb6e1a4b-9893-4b53-b078-c4861951aa77	natasha.frolova91	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.833905+03	\N
e4e27de1-f942-45a8-87e9-fd25a13da128	fad46874-5f76-47dd-bcd6-f40b9ee82cef	v.bogdanov67	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.833905+03	\N
52f4909b-40e5-464d-8f6b-e0cbdc7c7710	a8b406e8-3108-4af6-a1f5-a7a72610fa77	diana.gorbunova	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.738303+03	\N
049eae01-fb9d-4165-99d2-ed8b56329ea8	a4ff128d-9934-40f3-a356-e9a2127694b0	ion.popescu87	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.833905+03	\N
e56892f9-2ce3-4269-ab46-c7a6078d9337	dae8c362-ab3a-45f8-8ea9-e610ecdc6834	ilya.chernov91	\N	fdeb39f4-8301-439c-a739-2f4df5f1c2f8	2026-06-07 20:42:54.738303+03	\N
\.


--
-- Data for Name: user_address; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.user_address (address_id, person_id, address_type_id, country_id, region_id, city_id, street_id, house, building, flat, postal_code, raw_address, is_default) FROM stdin;
3d6d5f9a-491c-4de4-a81b-193f1d417e60	97a57ff9-a693-4a11-9f75-726a3be36cac	be0d8bf7-0858-47c7-881a-ccf7d95381fb	81081f7f-8cba-480b-801d-c5be9d434755	cf48c65f-6403-44e5-b966-20d1c2138fdd	22c0685f-7021-45b0-9c70-6a934532e90b	e94b124a-a744-4775-89e7-73a9eab64f41	12	\N	45	125009	Москва, Тверская 12 кв 45, домофон не работает	t
36fae052-427b-4258-bec0-29bd11d7867e	6c96c88a-10d3-4d86-9ba0-fc66136db266	be0d8bf7-0858-47c7-881a-ccf7d95381fb	81081f7f-8cba-480b-801d-c5be9d434755	4dda60a5-c25a-4b34-b5cc-f724ddcb41e9	a2811bb4-d09a-46b5-875c-2999ceaeec77	8318ded4-2e1c-4825-9daf-ed38990c60a4	7	2	101	\N	МО, г Химки, Молодежная 7к2, 101	f
45266713-97ba-4478-aa58-a69c4ddc2f5b	c4a6968d-5546-4f23-a490-a3d665ad5345	be0d8bf7-0858-47c7-881a-ccf7d95381fb	81081f7f-8cba-480b-801d-c5be9d434755	4859eb8e-eec4-4dd4-9b23-6e1c5362a8e0	a9ebc0ad-fd69-4061-beab-090715e38647	93eb7464-1485-4506-bd18-838c170e112a	1	\N	8	\N	СПб Невский 1-8	f
e527e1b2-9d1c-45b6-9d8b-d6b6200cb44c	861d02aa-6c7f-4304-b410-2664595578e3	5e334cb2-0e9d-4c04-8548-af62637e7311	81081f7f-8cba-480b-801d-c5be9d434755	fceff581-a3ec-488d-8d7b-13caa86a4b0f	0aa01595-270a-4c70-a00e-152abbdf8d92	338143c3-a064-4fc2-b31d-cdab158f8599	5	\N	12	420111	Казань, Баумана 5, квартира 12	f
f2443a45-720a-4cce-92a4-fb289bf80a0e	eccefedc-537c-4f94-9fa4-521eeaedc5f5	4a36f001-2879-498f-9f33-374038e6952d	81081f7f-8cba-480b-801d-c5be9d434755	989ec105-d35b-49f2-8996-bd54cd53290f	777b3e97-dc9c-4c76-b7bd-36a0735353e7	e4f73f30-4e0d-4eb4-8dfb-66f16b641803	30	\N	\N	\N	ПВЗ Новосибирск Красный 30	f
a504b46b-e8e2-416d-8905-fbf1dcb33e6d	ae5e8672-b19f-4867-91af-c02611ace804	be0d8bf7-0858-47c7-881a-ccf7d95381fb	81081f7f-8cba-480b-801d-c5be9d434755	cf48c65f-6403-44e5-b966-20d1c2138fdd	22c0685f-7021-45b0-9c70-6a934532e90b	361e269f-9835-4766-abb4-bc90ddc793f6	10	\N	15	\N	Москва, Арбат 10 кв. 15	t
dc477376-94ee-45d6-85e5-b41915df4191	1c32e472-5262-46d0-be59-6c2f27e189f4	be0d8bf7-0858-47c7-881a-ccf7d95381fb	81081f7f-8cba-480b-801d-c5be9d434755	4dda60a5-c25a-4b34-b5cc-f724ddcb41e9	7993efd6-2702-4665-b640-5b52efe4da2d	1c038252-3efb-43a1-bfde-52ae1425f7db	5	\N	7	\N	Подольск, Садовая 5 кв. 7	t
2c468ef7-decb-45ab-b285-c4576ecf5700	7497918d-bdcf-4431-b365-db195d277432	be0d8bf7-0858-47c7-881a-ccf7d95381fb	81081f7f-8cba-480b-801d-c5be9d434755	4859eb8e-eec4-4dd4-9b23-6e1c5362a8e0	a9ebc0ad-fd69-4061-beab-090715e38647	834fb9f6-d056-477d-a2e1-a6ccc83cd69c	44	\N	21	\N	Санкт-Петербург, Литейный проспект 44 кв. 21	t
7a65ac3f-e0e8-410a-bc9d-efaa5a7188e0	49582c70-48ce-4e74-8ed9-89b94943aabf	be0d8bf7-0858-47c7-881a-ccf7d95381fb	81081f7f-8cba-480b-801d-c5be9d434755	fceff581-a3ec-488d-8d7b-13caa86a4b0f	0aa01595-270a-4c70-a00e-152abbdf8d92	a8e26a4c-67d9-4d84-ad89-2ee8df0b8a8a	2	\N	11	\N	Казань, Кремлевская 2 кв. 11	t
2e7a1d0e-7868-4960-acd4-43fd0e03e663	63c6d99b-46ff-489f-a539-993a6f4d5f2f	be0d8bf7-0858-47c7-881a-ccf7d95381fb	81081f7f-8cba-480b-801d-c5be9d434755	989ec105-d35b-49f2-8996-bd54cd53290f	777b3e97-dc9c-4c76-b7bd-36a0735353e7	5c7b4389-facb-4c06-9858-7f87c66cd9e8	7	\N	19	\N	Новосибирск, Карла Маркса 7 кв. 19	t
acafa7a9-a8b7-4d63-90a6-c042d79fc419	56b3b63c-803d-4da7-ab79-fe95491f18e5	be0d8bf7-0858-47c7-881a-ccf7d95381fb	81081f7f-8cba-480b-801d-c5be9d434755	cf48c65f-6403-44e5-b966-20d1c2138fdd	22c0685f-7021-45b0-9c70-6a934532e90b	d1d2103a-bb73-4d97-b1e5-6c411f511942	88	\N	42	\N	Москва, Профсоюзная 88 кв. 42	t
aa561c70-e74c-4781-b609-b3d16e77b791	76409892-50ee-45f8-b1b6-487129468310	be0d8bf7-0858-47c7-881a-ccf7d95381fb	81081f7f-8cba-480b-801d-c5be9d434755	fcd63546-d062-49f0-833b-07d41b6729d0	a37eba23-a650-4a69-8535-375fe1e78405	8a1dee18-8309-4011-a7f0-8b327bf17dc7	135	\N	3	\N	Краснодар, Красная 135 кв. 3	t
7f5a68db-69e6-4134-85a5-a20a906ba1a2	74b11c35-2ca0-424d-888d-b03ead311080	be0d8bf7-0858-47c7-881a-ccf7d95381fb	81081f7f-8cba-480b-801d-c5be9d434755	dbf65158-16a9-476a-9d34-845e637a7a04	221d3fa1-7657-44cf-b85e-1e29138490fd	fb04f09e-3575-4ed9-90fa-fbd52c4b4548	15	\N	304	\N	Ростов-На-Дону, Большая Садовая 15 кв. 304	t
93dc5a68-c75a-4af1-b163-b781edcca05a	7f4a4ca6-14f9-4e19-8928-ad5959e53d38	be0d8bf7-0858-47c7-881a-ccf7d95381fb	81081f7f-8cba-480b-801d-c5be9d434755	2c7560eb-cf03-4d03-81f2-92b2348b8a14	02cc4eca-5296-4b32-ab1e-cd0bf36e0c8c	1f1327f0-2d11-42a4-b420-05576890f472	51	\N	79	\N	Екатеринбург, Малышева 51 кв. 79	t
253094a8-bdf2-4fbd-b641-2b75f5b80aa1	7869118c-d5c9-4c96-8332-fffd20599e5a	be0d8bf7-0858-47c7-881a-ccf7d95381fb	81081f7f-8cba-480b-801d-c5be9d434755	4859eb8e-eec4-4dd4-9b23-6e1c5362a8e0	a9ebc0ad-fd69-4061-beab-090715e38647	93eb7464-1485-4506-bd18-838c170e112a	100	\N	200	\N	Санкт-Петербург, Невский проспект 100 кв. 200	t
6cf8f9b8-13a0-4341-8f10-3794a0109992	7fff1799-25cd-4a7a-be97-d50baae6e254	be0d8bf7-0858-47c7-881a-ccf7d95381fb	81081f7f-8cba-480b-801d-c5be9d434755	cf48c65f-6403-44e5-b966-20d1c2138fdd	22c0685f-7021-45b0-9c70-6a934532e90b	e94b124a-a744-4775-89e7-73a9eab64f41	1	\N	8	\N	Москва, Тверская 1 кв. 8	t
0086a115-b80b-430a-a229-e591f1f76f87	a86c4ecc-8947-4a30-968f-ff444042e54e	be0d8bf7-0858-47c7-881a-ccf7d95381fb	81081f7f-8cba-480b-801d-c5be9d434755	4dda60a5-c25a-4b34-b5cc-f724ddcb41e9	a2811bb4-d09a-46b5-875c-2999ceaeec77	3f98d1e7-4946-4a46-be0f-da974244ddb9	78	\N	55	\N	Химки, Юбилейный проспект 78 кв. 55	t
f77e0dc0-d9a0-4737-9e3a-3cc9cc4d1271	22738087-7bfc-488e-88e3-c37f700e689c	be0d8bf7-0858-47c7-881a-ccf7d95381fb	81081f7f-8cba-480b-801d-c5be9d434755	cf48c65f-6403-44e5-b966-20d1c2138fdd	22c0685f-7021-45b0-9c70-6a934532e90b	ec14d89b-be08-4354-a273-c4abb23a6c93	4	\N	\N	\N	Москва, Лесной пер. 4	t
cdc1fb70-8d64-4306-9159-39b76802824b	dae8c362-ab3a-45f8-8ea9-e610ecdc6834	be0d8bf7-0858-47c7-881a-ccf7d95381fb	81081f7f-8cba-480b-801d-c5be9d434755	4859eb8e-eec4-4dd4-9b23-6e1c5362a8e0	a9ebc0ad-fd69-4061-beab-090715e38647	05ac72f4-4ad2-4036-a1a8-e648665bf604	41	\N	22	\N	Санкт-Петербург, Маршала Жукова 41 кв. 22	t
0750315a-817d-4a7f-8d85-67dee8e1ea21	545eb50f-a7c3-40c7-9d14-66ee6aea78e3	be0d8bf7-0858-47c7-881a-ccf7d95381fb	81081f7f-8cba-480b-801d-c5be9d434755	cf48c65f-6403-44e5-b966-20d1c2138fdd	22c0685f-7021-45b0-9c70-6a934532e90b	b24fc8d3-daf3-4681-b494-33f6e63fe204	9	\N	17	\N	Москва, Коньково 9 кв. 17	t
53143a84-0b37-4772-860c-ec58266b3bdf	a5c56ab3-74c4-4fb6-8987-6968ad93850c	be0d8bf7-0858-47c7-881a-ccf7d95381fb	81081f7f-8cba-480b-801d-c5be9d434755	cf48c65f-6403-44e5-b966-20d1c2138fdd	22c0685f-7021-45b0-9c70-6a934532e90b	1bae3535-32a9-4bd2-883d-4796b0dfe912	4	\N	\N	\N	Москва, 4-й Лесной пер. 4	t
58156cee-fec4-44fd-96e2-9d13d414d347	a8b406e8-3108-4af6-a1f5-a7a72610fa77	be0d8bf7-0858-47c7-881a-ccf7d95381fb	81081f7f-8cba-480b-801d-c5be9d434755	fcd63546-d062-49f0-833b-07d41b6729d0	a37eba23-a650-4a69-8535-375fe1e78405	99d7118c-feb5-4042-aefb-fe6d5203f73b	20	\N	2	\N	Краснодар, Северная 20 кв. 2	t
46de4471-b5ee-4fb9-acfa-4b2abf94bda2	c4072987-8e34-43a3-97c0-1f5543b9597e	be0d8bf7-0858-47c7-881a-ccf7d95381fb	81081f7f-8cba-480b-801d-c5be9d434755	dbf65158-16a9-476a-9d34-845e637a7a04	221d3fa1-7657-44cf-b85e-1e29138490fd	0d38c32b-b7ed-49d1-98c0-78dd84d2397c	15	\N	304	\N	Ростов-На-Дону, Ленина 15 кв. 304	t
9fa21e89-f065-4304-a863-5bb7ef927ce6	46f18937-fb05-42cf-b002-d9af780492e4	be0d8bf7-0858-47c7-881a-ccf7d95381fb	81081f7f-8cba-480b-801d-c5be9d434755	4859eb8e-eec4-4dd4-9b23-6e1c5362a8e0	a9ebc0ad-fd69-4061-beab-090715e38647	ab144eee-5c52-4ad5-9ce1-b5d10e5e5e79	7	\N	14	\N	Санкт-Петербург, Кронверкский пр-т 7 кв. 14	t
50198207-5702-47c7-8427-1f8ddf238003	d4c7f619-e8a9-470d-acc0-d1c976cbbf11	be0d8bf7-0858-47c7-881a-ccf7d95381fb	81081f7f-8cba-480b-801d-c5be9d434755	cf48c65f-6403-44e5-b966-20d1c2138fdd	22c0685f-7021-45b0-9c70-6a934532e90b	e94b124a-a744-4775-89e7-73a9eab64f41	12	\N	45	\N	Москва, Тверская 12 кв. 45	t
9f1948f7-b4f0-4286-a2c9-2dd03b0e4926	841a025c-4b12-41ab-aaad-d88bdff03406	be0d8bf7-0858-47c7-881a-ccf7d95381fb	81081f7f-8cba-480b-801d-c5be9d434755	cf48c65f-6403-44e5-b966-20d1c2138fdd	22c0685f-7021-45b0-9c70-6a934532e90b	26a8f7cd-6c5a-42d5-9f62-6266c1845725	34	\N	128	115533	Каширское шоссе 34 кв. 128	t
6e9987a2-a4a6-4872-ae7d-7c6d2a6d62c8	6295c95d-393f-4dc4-822e-b1fb1e14c4e2	be0d8bf7-0858-47c7-881a-ccf7d95381fb	81081f7f-8cba-480b-801d-c5be9d434755	4859eb8e-eec4-4dd4-9b23-6e1c5362a8e0	a9ebc0ad-fd69-4061-beab-090715e38647	10523473-7709-4c6f-82db-4dc9a4b20886	7	\N	14	197101	Кронверкский пр-т, 7, кв.14	t
59be1d76-4b49-4d6f-8391-9188a2aefffe	46d321ec-69be-4de6-a08e-31b3607a0a78	5e334cb2-0e9d-4c04-8548-af62637e7311	81081f7f-8cba-480b-801d-c5be9d434755	989ec105-d35b-49f2-8996-bd54cd53290f	777b3e97-dc9c-4c76-b7bd-36a0735353e7	6321eddf-adb5-49ae-b175-4184beba5b76	26/5	\N	\N	630099	Красный проспект 26/5	t
9bcf36c7-7173-4f64-a608-9e15e2c5c541	46d321ec-69be-4de6-a08e-31b3607a0a78	5e334cb2-0e9d-4c04-8548-af62637e7311	81081f7f-8cba-480b-801d-c5be9d434755	2c7560eb-cf03-4d03-81f2-92b2348b8a14	02cc4eca-5296-4b32-ab1e-cd0bf36e0c8c	2569d86f-284d-4ac4-9be3-81d52f48a0c2	100	\N	55	620000	ул. Ленина 100, кв 55	t
07922567-55f1-48af-a5a8-981ab5928c83	9fb760a6-3618-4999-8537-bce4c127800e	be0d8bf7-0858-47c7-881a-ccf7d95381fb	81081f7f-8cba-480b-801d-c5be9d434755	cf48c65f-6403-44e5-b966-20d1c2138fdd	22c0685f-7021-45b0-9c70-6a934532e90b	41c7cb3c-484c-44d9-8cd6-0cb179fbf4b7	10	\N	35	125009	ул. Пушкина д. 10 кв. 35	t
d75c54fe-9966-4d01-9644-9a8d6689bdd2	9fb760a6-3618-4999-8537-bce4c127800e	5e334cb2-0e9d-4c04-8548-af62637e7311	81081f7f-8cba-480b-801d-c5be9d434755	97d07e4b-f046-47c8-b21b-d06287215bde	3e1a25b9-1e7d-4fc1-bb6d-e27e42d93f12	0a6b2e12-37f7-4d1b-9342-0f3f6b91c1d0	5	\N	\N	142100	Московская обл г Подольск ул Садовая 5	f
0f88b971-1721-44df-a62f-6449f41d0cf6	f3b76a50-5950-4a1e-9132-ac769c5b9e97	5e334cb2-0e9d-4c04-8548-af62637e7311	81081f7f-8cba-480b-801d-c5be9d434755	cf48c65f-6403-44e5-b966-20d1c2138fdd	22c0685f-7021-45b0-9c70-6a934532e90b	55ce6bac-79ed-402f-b481-417019fe3ea1	55-А	\N	3	129085	пр. Мира 55-А кв.3	t
c3908687-5dc8-4ac2-b811-5e88cbff7d54	f3b76a50-5950-4a1e-9132-ac769c5b9e97	5e334cb2-0e9d-4c04-8548-af62637e7311	81081f7f-8cba-480b-801d-c5be9d434755	4859eb8e-eec4-4dd4-9b23-6e1c5362a8e0	a9ebc0ad-fd69-4061-beab-090715e38647	9cba0e56-e680-47ed-85d9-eef32c70ba41	100	\N	200	191025	Невский пр. 100 кв.200	t
4594bdb9-aafb-4937-bdac-a7e1613f852e	d4c7f619-e8a9-470d-acc0-d1c976cbbf11	be0d8bf7-0858-47c7-881a-ccf7d95381fb	81081f7f-8cba-480b-801d-c5be9d434755	cf48c65f-6403-44e5-b966-20d1c2138fdd	22c0685f-7021-45b0-9c70-6a934532e90b	8d7aa7f8-72ed-4001-841c-5546371680d9	1	\N	\N	125009	Россия, г.Москва, ул.Тверская, дом 1	t
e3ec43a7-e2e6-40eb-9f19-e4b99c916b18	9fb760a6-3618-4999-8537-bce4c127800e	be0d8bf7-0858-47c7-881a-ccf7d95381fb	81081f7f-8cba-480b-801d-c5be9d434755	dbf65158-16a9-476a-9d34-845e637a7a04	221d3fa1-7657-44cf-b85e-1e29138490fd	b223a903-9b98-4c65-afb7-dca66543ed13	15	\N	\N	344000	Пр. Ленина 15 оф. 304	t
98a91bac-7634-49fb-8c44-cf937cc4bfcc	7fb42bd1-ad5a-4582-ac10-9e5bcc2dd8e1	5e334cb2-0e9d-4c04-8548-af62637e7311	81081f7f-8cba-480b-801d-c5be9d434755	2c7560eb-cf03-4d03-81f2-92b2348b8a14	02cc4eca-5296-4b32-ab1e-cd0bf36e0c8c	165ee861-eeee-49ae-b5a0-196f77b225c4	620000	\N	\N	620000	Россия 620000 Свердл.обл г.Екб ул.Малышева 51-79	t
a5bbb648-08d2-49c2-bdaf-63371154dff6	d4c7f619-e8a9-470d-acc0-d1c976cbbf11	be0d8bf7-0858-47c7-881a-ccf7d95381fb	81081f7f-8cba-480b-801d-c5be9d434755	cf48c65f-6403-44e5-b966-20d1c2138fdd	22c0685f-7021-45b0-9c70-6a934532e90b	791a6963-3497-4196-a422-1a3137764ce9	5	\N	\N	125047	Москва ул.4-я Тверская-Ямская 5	t
a36d52a1-10bf-4bf8-b80a-2b529ae38da3	50fc12d2-3450-4db8-aebe-c1a1a251254a	5e334cb2-0e9d-4c04-8548-af62637e7311	81081f7f-8cba-480b-801d-c5be9d434755	fceff581-a3ec-488d-8d7b-13caa86a4b0f	0aa01595-270a-4c70-a00e-152abbdf8d92	27c37556-2685-4a41-b7fe-934bd42bd021	10	\N	\N	420000	Казань ул. Баумана 10	t
dc8a791d-3b5b-4579-9496-2e939bef6aa3	2f4be900-91d9-49ed-855f-8ca0fc20b7aa	be0d8bf7-0858-47c7-881a-ccf7d95381fb	81081f7f-8cba-480b-801d-c5be9d434755	4859eb8e-eec4-4dd4-9b23-6e1c5362a8e0	a9ebc0ad-fd69-4061-beab-090715e38647	3c90ad20-faf2-4ced-a589-8404011b729f	41	\N	22	198328	198328, г. Санкт-Петербург, ул. Маршала Жукова, д.41 к.1 кв.22	t
0f950f5c-c9ae-455a-a3ac-110c20151094	97a57ff9-a693-4a11-9f75-726a3be36cac	5e334cb2-0e9d-4c04-8548-af62637e7311	81081f7f-8cba-480b-801d-c5be9d434755	989ec105-d35b-49f2-8996-bd54cd53290f	777b3e97-dc9c-4c76-b7bd-36a0735353e7	b221255e-3d48-42ce-92ae-293bb2688eb9	7	\N	19	630007	Новосибирск пр-т Карла Маркса 7 кв 19	t
d08247a6-461d-46f7-9a9b-f19da930d6e2	fad46874-5f76-47dd-bcd6-f40b9ee82cef	be0d8bf7-0858-47c7-881a-ccf7d95381fb	81081f7f-8cba-480b-801d-c5be9d434755	4dda60a5-c25a-4b34-b5cc-f724ddcb41e9	a2811bb4-d09a-46b5-875c-2999ceaeec77	66272a9f-14f6-43d3-9a59-8e07229b7b74	78	\N	55	141400	МО, Химки, Юбилейный пр. 78, кв.55	t
75c5802e-e5f2-4b2a-913e-98ba8905bb1e	bb6e1a4b-9893-4b53-b078-c4861951aa77	5e334cb2-0e9d-4c04-8548-af62637e7311	81081f7f-8cba-480b-801d-c5be9d434755	fcd63546-d062-49f0-833b-07d41b6729d0	a37eba23-a650-4a69-8535-375fe1e78405	5860990f-895a-412c-89fb-84ed842afe0f	135	\N	\N	350000	Краснодар Красная 135	t
7319a7d3-eae4-4cd9-8b57-f270080d9529	fad46874-5f76-47dd-bcd6-f40b9ee82cef	5e334cb2-0e9d-4c04-8548-af62637e7311	81081f7f-8cba-480b-801d-c5be9d434755	cf48c65f-6403-44e5-b966-20d1c2138fdd	22c0685f-7021-45b0-9c70-6a934532e90b	c6be5bde-64a7-48a5-b737-14aa9c9e1c93	4-й	\N	\N	125047	г. Москва 4-й Лесной пер. 4	t
e2d5be36-06e9-40b7-89de-b1bbe1f5c54a	dae8c362-ab3a-45f8-8ea9-e610ecdc6834	be0d8bf7-0858-47c7-881a-ccf7d95381fb	81081f7f-8cba-480b-801d-c5be9d434755	4859eb8e-eec4-4dd4-9b23-6e1c5362a8e0	a9ebc0ad-fd69-4061-beab-090715e38647	5dbbeca0-e5e0-4265-8e04-af3323510afe	44	\N	\N	191014	Санкт-Петербург Литейный проспект 44	t
\.


--
-- Data for Name: user_attribute_type; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.user_attribute_type (attribute_type_id, code, name, value_type, description) FROM stdin;
cbd6477e-134d-44fb-aeb8-31abb4736dbc	FAVORITE_TECH_CATEGORY	Любимая категория техники	text	Например смартфоны, ноутбуки, умный дом
beba1148-10f4-451f-8114-f738fe652b73	PREFERRED_BRAND	Предпочитаемый бренд	text	Маркетинговое предпочтение покупателя
1493e011-8a13-4cf4-b127-d3b8603ec572	INSTALLMENT_INTEREST	Интерес к рассрочке	bool	Покупатель интересуется рассрочкой
442964a5-fe19-498b-a4c1-6af1c2157f08	AVG_ORDER_BUDGET	Средний бюджет заказа	number	Примерный бюджет покупки техники
87d0a155-e782-408c-8080-8d405e309d8f	HAS_SMART_HOME	Есть устройства умного дома	bool	Гибкий признак покупателя техники
b55497c7-8443-4016-b416-d9ec56bb9a5c	DEVICE_ECOSYSTEM	Экосистема устройств	text	Apple, Android, Windows, mixed
5f8cf6a3-3fe6-4aa7-9465-f61d9309d8bb	LOYALTY_LEVEL	Уровень лояльности	text	basic, silver, gold
2741217a-8a1a-4b4f-a301-fc0eca62b097	BIOMETRIC_FACE_REF	Ссылка на биометрический шаблон лица	text	Опциональная ссылка на внешний биометрический шаблон
\.


--
-- Data for Name: user_attribute_value; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.user_attribute_value (attribute_value_id, person_id, attribute_type_id, value_text, value_number, value_date, value_bool, value_json, raw_value) FROM stdin;
cfa383f3-8694-41b2-9d86-e8484902d0ab	97a57ff9-a693-4a11-9f75-726a3be36cac	5f8cf6a3-3fe6-4aa7-9465-f61d9309d8bb	gold	\N	\N	\N	\N	"gold"
a050af3b-0029-4d08-8745-1fb91098a2af	97a57ff9-a693-4a11-9f75-726a3be36cac	87d0a155-e782-408c-8080-8d405e309d8f	\N	\N	\N	t	\N	true
58455413-2e8f-4c97-8dc1-08579fd5e044	97a57ff9-a693-4a11-9f75-726a3be36cac	442964a5-fe19-498b-a4c1-6af1c2157f08	\N	65000	\N	\N	\N	65000
5659586e-b7a4-4445-9c1d-046c5c7b3117	97a57ff9-a693-4a11-9f75-726a3be36cac	b55497c7-8443-4016-b416-d9ec56bb9a5c	Android	\N	\N	\N	\N	"Android"
73bc124f-3385-4a63-aa20-f83d95c7f330	97a57ff9-a693-4a11-9f75-726a3be36cac	1493e011-8a13-4cf4-b127-d3b8603ec572	\N	\N	\N	t	\N	true
3daacf1a-c4dd-4023-9df1-3b4606c91b0e	97a57ff9-a693-4a11-9f75-726a3be36cac	cbd6477e-134d-44fb-aeb8-31abb4736dbc	смартфоны	\N	\N	\N	\N	"смартфоны"
34f655dd-b62d-454d-bacd-f7097df47601	6c96c88a-10d3-4d86-9ba0-fc66136db266	5f8cf6a3-3fe6-4aa7-9465-f61d9309d8bb	silver	\N	\N	\N	\N	"silver"
fd6231e5-ee54-4bbd-8232-497a0a58ccad	6c96c88a-10d3-4d86-9ba0-fc66136db266	beba1148-10f4-451f-8114-f738fe652b73	Apple	\N	\N	\N	\N	"Apple"
66597c56-1763-4611-8935-3a0c6b4f25bb	6c96c88a-10d3-4d86-9ba0-fc66136db266	442964a5-fe19-498b-a4c1-6af1c2157f08	\N	120000	\N	\N	\N	120000
7bc9b022-ebaf-4ea2-9492-a016786dcead	6c96c88a-10d3-4d86-9ba0-fc66136db266	b55497c7-8443-4016-b416-d9ec56bb9a5c	Apple	\N	\N	\N	\N	"Apple"
da6a24a0-4c2a-4c39-bc50-7223d2ddc60b	6c96c88a-10d3-4d86-9ba0-fc66136db266	1493e011-8a13-4cf4-b127-d3b8603ec572	\N	\N	\N	f	\N	false
d1a0b58e-af78-42c3-a886-5ce4baf03692	6c96c88a-10d3-4d86-9ba0-fc66136db266	cbd6477e-134d-44fb-aeb8-31abb4736dbc	ноутбуки	\N	\N	\N	\N	"ноутбуки"
3b36bffd-8f9c-4512-ba8b-71c73f8c457a	c4a6968d-5546-4f23-a490-a3d665ad5345	5f8cf6a3-3fe6-4aa7-9465-f61d9309d8bb	basic	\N	\N	\N	\N	"basic"
9bd426a0-c620-49a3-8333-8d946e9505d7	c4a6968d-5546-4f23-a490-a3d665ad5345	87d0a155-e782-408c-8080-8d405e309d8f	\N	\N	\N	f	\N	false
29f22ab7-fa81-4c32-941b-4faf3d63b9ea	c4a6968d-5546-4f23-a490-a3d665ad5345	beba1148-10f4-451f-8114-f738fe652b73	Sony	\N	\N	\N	\N	"Sony"
2fbd59b5-45a1-4423-a099-444131aa7df5	c4a6968d-5546-4f23-a490-a3d665ad5345	442964a5-fe19-498b-a4c1-6af1c2157f08	\N	80000	\N	\N	\N	80000
563b79ad-c4a1-435d-95f8-4ea7e90cc8a4	c4a6968d-5546-4f23-a490-a3d665ad5345	1493e011-8a13-4cf4-b127-d3b8603ec572	\N	\N	\N	t	\N	true
7d03ab11-33f8-4dea-af76-a3898c80f1da	c4a6968d-5546-4f23-a490-a3d665ad5345	cbd6477e-134d-44fb-aeb8-31abb4736dbc	игровые консоли	\N	\N	\N	\N	"игровые консоли"
bb3d474f-ec7c-48ae-b3b7-fa0f7a19ae10	861d02aa-6c7f-4304-b410-2664595578e3	87d0a155-e782-408c-8080-8d405e309d8f	\N	\N	\N	t	\N	true
a1d4f2e4-dc31-4f81-a35d-78b17e0b9849	861d02aa-6c7f-4304-b410-2664595578e3	beba1148-10f4-451f-8114-f738fe652b73	Xiaomi	\N	\N	\N	\N	"Xiaomi"
becf8b46-423e-42dc-9021-ddabed4538e1	861d02aa-6c7f-4304-b410-2664595578e3	442964a5-fe19-498b-a4c1-6af1c2157f08	\N	30000	\N	\N	\N	30000
91a66b1e-e5eb-46cd-9aa9-c8a03bc3ec09	861d02aa-6c7f-4304-b410-2664595578e3	b55497c7-8443-4016-b416-d9ec56bb9a5c	mixed	\N	\N	\N	\N	"mixed"
4043555f-463e-4ce8-ad08-a2d9a5b23b86	861d02aa-6c7f-4304-b410-2664595578e3	2741217a-8a1a-4b4f-a301-fc0eca62b097	face-template://legacy/4451	\N	\N	\N	\N	"face-template://legacy/4451"
e00d511d-7fe8-4c20-8c4c-86e91402e05b	861d02aa-6c7f-4304-b410-2664595578e3	1493e011-8a13-4cf4-b127-d3b8603ec572	\N	\N	\N	t	\N	true
0f62243e-cb2b-4cb7-9765-2fe23b839ef7	861d02aa-6c7f-4304-b410-2664595578e3	cbd6477e-134d-44fb-aeb8-31abb4736dbc	умный дом	\N	\N	\N	\N	"умный дом"
926eb978-acf4-4944-80a6-631e9542f0b5	eccefedc-537c-4f94-9fa4-521eeaedc5f5	5f8cf6a3-3fe6-4aa7-9465-f61d9309d8bb	basic	\N	\N	\N	\N	"basic"
3198523b-3cf4-4ef3-b0ed-c3db937cb1c7	eccefedc-537c-4f94-9fa4-521eeaedc5f5	beba1148-10f4-451f-8114-f738fe652b73	AMD	\N	\N	\N	\N	"AMD"
0f1bb96a-3982-46c6-be8c-f2d778e286f6	eccefedc-537c-4f94-9fa4-521eeaedc5f5	442964a5-fe19-498b-a4c1-6af1c2157f08	\N	45000	\N	\N	\N	45000
6be2fb5e-4c37-47d4-82dd-794b28ca597c	eccefedc-537c-4f94-9fa4-521eeaedc5f5	1493e011-8a13-4cf4-b127-d3b8603ec572	\N	\N	\N	f	\N	false
fe028a62-b79d-4d4b-a285-7617bb6efa2b	eccefedc-537c-4f94-9fa4-521eeaedc5f5	cbd6477e-134d-44fb-aeb8-31abb4736dbc	комплектующие	\N	\N	\N	\N	"комплектующие"
258bb806-303f-4830-95dc-1ee78328157d	ae5e8672-b19f-4867-91af-c02611ace804	5f8cf6a3-3fe6-4aa7-9465-f61d9309d8bb	gold	\N	\N	\N	\N	"gold"
52eaa007-5ce8-4fd8-abc7-f8370b6c3f19	ae5e8672-b19f-4867-91af-c02611ace804	beba1148-10f4-451f-8114-f738fe652b73	Lenovo	\N	\N	\N	\N	"Lenovo"
0bd4e467-43b0-480f-8ce0-eaba7a8f6e99	ae5e8672-b19f-4867-91af-c02611ace804	442964a5-fe19-498b-a4c1-6af1c2157f08	\N	90000	\N	\N	\N	90000
b45a0312-a57e-49f1-b327-6cab74f81fe3	ae5e8672-b19f-4867-91af-c02611ace804	1493e011-8a13-4cf4-b127-d3b8603ec572	\N	\N	\N	t	\N	true
56c71398-1177-4fe0-aa87-ed2d09cd4894	ae5e8672-b19f-4867-91af-c02611ace804	cbd6477e-134d-44fb-aeb8-31abb4736dbc	ноутбуки	\N	\N	\N	\N	"ноутбуки"
2582ce64-3e11-4ca7-93e3-887d49d049e2	1c32e472-5262-46d0-be59-6c2f27e189f4	5f8cf6a3-3fe6-4aa7-9465-f61d9309d8bb	gold	\N	\N	\N	\N	"gold"
37784f72-d49b-4986-9e56-42beabbc158b	1c32e472-5262-46d0-be59-6c2f27e189f4	beba1148-10f4-451f-8114-f738fe652b73	Apple	\N	\N	\N	\N	"Apple"
af8da690-04d6-476f-a0e3-33765364f144	1c32e472-5262-46d0-be59-6c2f27e189f4	442964a5-fe19-498b-a4c1-6af1c2157f08	\N	110000	\N	\N	\N	110000
6af67c13-f3dd-4d70-b429-77f6c29b8ea2	1c32e472-5262-46d0-be59-6c2f27e189f4	1493e011-8a13-4cf4-b127-d3b8603ec572	\N	\N	\N	f	\N	false
b50d0b7c-3baf-4345-aa1d-e230226a26ff	1c32e472-5262-46d0-be59-6c2f27e189f4	cbd6477e-134d-44fb-aeb8-31abb4736dbc	смартфоны	\N	\N	\N	\N	"смартфоны"
52dbb227-35ba-44e9-b761-e89158cecef3	7497918d-bdcf-4431-b365-db195d277432	5f8cf6a3-3fe6-4aa7-9465-f61d9309d8bb	silver	\N	\N	\N	\N	"silver"
a2c58b69-7744-4823-a46e-1697ef74b61e	7497918d-bdcf-4431-b365-db195d277432	beba1148-10f4-451f-8114-f738fe652b73	LG	\N	\N	\N	\N	"LG"
a0f179c0-5d3c-4413-858d-86b4e325c98f	7497918d-bdcf-4431-b365-db195d277432	442964a5-fe19-498b-a4c1-6af1c2157f08	\N	70000	\N	\N	\N	70000
d239def7-41fe-4d2e-8ab1-f8da1ec2544d	7497918d-bdcf-4431-b365-db195d277432	1493e011-8a13-4cf4-b127-d3b8603ec572	\N	\N	\N	t	\N	true
21513aaf-f228-4f31-b494-01555d963c89	7497918d-bdcf-4431-b365-db195d277432	cbd6477e-134d-44fb-aeb8-31abb4736dbc	телевизоры	\N	\N	\N	\N	"телевизоры"
65f22ba5-a6ed-4685-93c7-3d179fa60307	49582c70-48ce-4e74-8ed9-89b94943aabf	5f8cf6a3-3fe6-4aa7-9465-f61d9309d8bb	basic	\N	\N	\N	\N	"basic"
9f953b14-1e26-4a58-87e5-5f7fc9368356	49582c70-48ce-4e74-8ed9-89b94943aabf	beba1148-10f4-451f-8114-f738fe652b73	Xiaomi	\N	\N	\N	\N	"Xiaomi"
afe42567-a331-415b-a9ec-7109b436155c	49582c70-48ce-4e74-8ed9-89b94943aabf	442964a5-fe19-498b-a4c1-6af1c2157f08	\N	35000	\N	\N	\N	35000
a5d3b902-4565-4faf-a231-7fe6b772463b	49582c70-48ce-4e74-8ed9-89b94943aabf	1493e011-8a13-4cf4-b127-d3b8603ec572	\N	\N	\N	t	\N	true
732a613c-cedb-4b2a-9db3-c3ba5376a205	49582c70-48ce-4e74-8ed9-89b94943aabf	cbd6477e-134d-44fb-aeb8-31abb4736dbc	умный дом	\N	\N	\N	\N	"умный дом"
5f203bc4-7652-4586-aca9-a697d9b0b07b	63c6d99b-46ff-489f-a539-993a6f4d5f2f	5f8cf6a3-3fe6-4aa7-9465-f61d9309d8bb	silver	\N	\N	\N	\N	"silver"
bce44e33-a1d8-4eeb-8c01-56a1d5381f5b	63c6d99b-46ff-489f-a539-993a6f4d5f2f	beba1148-10f4-451f-8114-f738fe652b73	AMD	\N	\N	\N	\N	"AMD"
598f1cfb-c187-4c94-a6d6-f711380c973b	63c6d99b-46ff-489f-a539-993a6f4d5f2f	442964a5-fe19-498b-a4c1-6af1c2157f08	\N	55000	\N	\N	\N	55000
a567ff2a-ea4e-43dd-b308-870a007bd769	63c6d99b-46ff-489f-a539-993a6f4d5f2f	1493e011-8a13-4cf4-b127-d3b8603ec572	\N	\N	\N	f	\N	false
0b8264ac-cfd5-4593-bf8d-390c85f208ca	63c6d99b-46ff-489f-a539-993a6f4d5f2f	cbd6477e-134d-44fb-aeb8-31abb4736dbc	комплектующие	\N	\N	\N	\N	"комплектующие"
b5cfc7a2-d873-4968-b87e-40222e4486b7	56b3b63c-803d-4da7-ab79-fe95491f18e5	5f8cf6a3-3fe6-4aa7-9465-f61d9309d8bb	silver	\N	\N	\N	\N	"silver"
f6512268-359e-48e7-acd0-02b8fbd9070a	56b3b63c-803d-4da7-ab79-fe95491f18e5	beba1148-10f4-451f-8114-f738fe652b73	Samsung	\N	\N	\N	\N	"Samsung"
ab8b1dac-2d9b-4847-ac3f-c36d3f6f9ea1	56b3b63c-803d-4da7-ab79-fe95491f18e5	442964a5-fe19-498b-a4c1-6af1c2157f08	\N	50000	\N	\N	\N	50000
99513ae4-4ae2-4c5c-9562-ba3bddcb77b9	56b3b63c-803d-4da7-ab79-fe95491f18e5	1493e011-8a13-4cf4-b127-d3b8603ec572	\N	\N	\N	t	\N	true
ddf648cb-82c9-4c7a-be27-8fdda632e6d1	56b3b63c-803d-4da7-ab79-fe95491f18e5	cbd6477e-134d-44fb-aeb8-31abb4736dbc	планшеты	\N	\N	\N	\N	"планшеты"
a4878a24-ac83-49ec-9403-b18dec0e98bb	76409892-50ee-45f8-b1b6-487129468310	5f8cf6a3-3fe6-4aa7-9465-f61d9309d8bb	silver	\N	\N	\N	\N	"silver"
1e213c80-fbe2-4b46-ac32-e3a1233b4284	76409892-50ee-45f8-b1b6-487129468310	beba1148-10f4-451f-8114-f738fe652b73	Sony	\N	\N	\N	\N	"Sony"
9b02bc05-8d30-4df9-81f8-6fb1d44d47eb	76409892-50ee-45f8-b1b6-487129468310	442964a5-fe19-498b-a4c1-6af1c2157f08	\N	78000	\N	\N	\N	78000
e09ac62f-b459-4b76-ad6e-e8b5d7171adf	76409892-50ee-45f8-b1b6-487129468310	1493e011-8a13-4cf4-b127-d3b8603ec572	\N	\N	\N	t	\N	true
21cc810b-c716-44ff-90f4-de80b040cf9a	76409892-50ee-45f8-b1b6-487129468310	cbd6477e-134d-44fb-aeb8-31abb4736dbc	игровые консоли	\N	\N	\N	\N	"игровые консоли"
a1804bd8-ea29-4f86-bb3f-c7b64c4a4422	74b11c35-2ca0-424d-888d-b03ead311080	5f8cf6a3-3fe6-4aa7-9465-f61d9309d8bb	silver	\N	\N	\N	\N	"silver"
98cb8945-37e8-487d-a9c4-65e25cf98f20	74b11c35-2ca0-424d-888d-b03ead311080	beba1148-10f4-451f-8114-f738fe652b73	Canon	\N	\N	\N	\N	"Canon"
dc765815-6aae-4ac5-9842-b94c0d3bd778	74b11c35-2ca0-424d-888d-b03ead311080	442964a5-fe19-498b-a4c1-6af1c2157f08	\N	65000	\N	\N	\N	65000
4572faa8-b0b1-4559-8fac-6e49574dad1e	74b11c35-2ca0-424d-888d-b03ead311080	1493e011-8a13-4cf4-b127-d3b8603ec572	\N	\N	\N	f	\N	false
44069d67-b6fc-4002-b4a4-975c877baa19	74b11c35-2ca0-424d-888d-b03ead311080	cbd6477e-134d-44fb-aeb8-31abb4736dbc	фото	\N	\N	\N	\N	"фото"
14644533-99b7-4fb2-b6b1-1d06812b9c30	7f4a4ca6-14f9-4e19-8928-ad5959e53d38	5f8cf6a3-3fe6-4aa7-9465-f61d9309d8bb	silver	\N	\N	\N	\N	"silver"
cc483d9a-08d5-4518-955a-31c4331ea2df	7f4a4ca6-14f9-4e19-8928-ad5959e53d38	beba1148-10f4-451f-8114-f738fe652b73	HP	\N	\N	\N	\N	"HP"
fe392a86-a800-436d-acb7-356f7965a641	7f4a4ca6-14f9-4e19-8928-ad5959e53d38	442964a5-fe19-498b-a4c1-6af1c2157f08	\N	60000	\N	\N	\N	60000
445d90e0-9162-4983-8c5e-1c2fd45ef939	7f4a4ca6-14f9-4e19-8928-ad5959e53d38	1493e011-8a13-4cf4-b127-d3b8603ec572	\N	\N	\N	f	\N	false
5e00d97e-3818-4e9c-9880-d8682285b3bb	7f4a4ca6-14f9-4e19-8928-ad5959e53d38	cbd6477e-134d-44fb-aeb8-31abb4736dbc	ноутбуки	\N	\N	\N	\N	"ноутбуки"
2a788b3f-a8e8-471b-8105-e04fa6630750	7869118c-d5c9-4c96-8332-fffd20599e5a	5f8cf6a3-3fe6-4aa7-9465-f61d9309d8bb	basic	\N	\N	\N	\N	"basic"
47d42f5a-eb15-4a18-87c1-4e47452a8727	7869118c-d5c9-4c96-8332-fffd20599e5a	beba1148-10f4-451f-8114-f738fe652b73	Huawei	\N	\N	\N	\N	"Huawei"
445d5345-3ae1-4c26-9de5-2cb7f28b7e03	7869118c-d5c9-4c96-8332-fffd20599e5a	442964a5-fe19-498b-a4c1-6af1c2157f08	\N	42000	\N	\N	\N	42000
6592caae-7d85-4d55-aa19-7059c85c00ae	7869118c-d5c9-4c96-8332-fffd20599e5a	1493e011-8a13-4cf4-b127-d3b8603ec572	\N	\N	\N	t	\N	true
dad8ecda-4275-461c-b325-80277562c29d	7869118c-d5c9-4c96-8332-fffd20599e5a	cbd6477e-134d-44fb-aeb8-31abb4736dbc	смартфоны	\N	\N	\N	\N	"смартфоны"
dd80ff5f-6763-4c06-86dd-d675319a4550	7fff1799-25cd-4a7a-be97-d50baae6e254	5f8cf6a3-3fe6-4aa7-9465-f61d9309d8bb	basic	\N	\N	\N	\N	"basic"
6cd9cc9e-009a-4689-ac67-4d3cf79557bf	7fff1799-25cd-4a7a-be97-d50baae6e254	beba1148-10f4-451f-8114-f738fe652b73	Sony	\N	\N	\N	\N	"Sony"
4bcc139a-0e30-4425-a2c5-6adcbbf789f6	7fff1799-25cd-4a7a-be97-d50baae6e254	442964a5-fe19-498b-a4c1-6af1c2157f08	\N	22000	\N	\N	\N	22000
c62ef843-7119-4992-97df-e5a1ec6c9e29	7fff1799-25cd-4a7a-be97-d50baae6e254	1493e011-8a13-4cf4-b127-d3b8603ec572	\N	\N	\N	f	\N	false
89f73ef3-069f-40c0-9030-78d52c59c955	7fff1799-25cd-4a7a-be97-d50baae6e254	cbd6477e-134d-44fb-aeb8-31abb4736dbc	наушники	\N	\N	\N	\N	"наушники"
3e10b3c4-97cd-43a8-b0d4-a9e5beb005fd	a86c4ecc-8947-4a30-968f-ff444042e54e	5f8cf6a3-3fe6-4aa7-9465-f61d9309d8bb	basic	\N	\N	\N	\N	"basic"
0dbfdb9f-5fde-46f7-b24a-3fa245fe38c0	a86c4ecc-8947-4a30-968f-ff444042e54e	beba1148-10f4-451f-8114-f738fe652b73	Aqara	\N	\N	\N	\N	"Aqara"
59a4a314-8cb4-4339-ba65-bb16f34a4ca5	a86c4ecc-8947-4a30-968f-ff444042e54e	442964a5-fe19-498b-a4c1-6af1c2157f08	\N	28000	\N	\N	\N	28000
2850ce37-a744-425b-b7dc-efae5e32fe10	a86c4ecc-8947-4a30-968f-ff444042e54e	1493e011-8a13-4cf4-b127-d3b8603ec572	\N	\N	\N	t	\N	true
527a382b-9c82-4ffe-a3c9-839fc0f52513	a86c4ecc-8947-4a30-968f-ff444042e54e	cbd6477e-134d-44fb-aeb8-31abb4736dbc	умный дом	\N	\N	\N	\N	"умный дом"
080d2aa8-7e2e-41c0-8ada-847fb9977da3	22738087-7bfc-488e-88e3-c37f700e689c	5f8cf6a3-3fe6-4aa7-9465-f61d9309d8bb	basic	\N	\N	\N	\N	"basic"
e1fcb625-4152-42e6-8f81-f6c67aadda6f	22738087-7bfc-488e-88e3-c37f700e689c	beba1148-10f4-451f-8114-f738fe652b73	Intel	\N	\N	\N	\N	"Intel"
17f00b5b-883b-4fcc-b318-d60585c65cbb	22738087-7bfc-488e-88e3-c37f700e689c	442964a5-fe19-498b-a4c1-6af1c2157f08	\N	47000	\N	\N	\N	47000
41b687ec-493f-4122-86e3-f148b685eebf	22738087-7bfc-488e-88e3-c37f700e689c	1493e011-8a13-4cf4-b127-d3b8603ec572	\N	\N	\N	f	\N	false
d3080e3f-dfde-41ad-a0d7-549d08b67f0e	22738087-7bfc-488e-88e3-c37f700e689c	cbd6477e-134d-44fb-aeb8-31abb4736dbc	комплектующие	\N	\N	\N	\N	"комплектующие"
38cdcf29-9d54-4df6-8924-acdb4545828c	dae8c362-ab3a-45f8-8ea9-e610ecdc6834	5f8cf6a3-3fe6-4aa7-9465-f61d9309d8bb	silver	\N	\N	\N	\N	"silver"
692aee39-41f6-4398-97d9-309c9a4dd61e	dae8c362-ab3a-45f8-8ea9-e610ecdc6834	beba1148-10f4-451f-8114-f738fe652b73	Bosch	\N	\N	\N	\N	"Bosch"
981885a2-d9ea-4903-ab09-703def41f69e	dae8c362-ab3a-45f8-8ea9-e610ecdc6834	442964a5-fe19-498b-a4c1-6af1c2157f08	\N	52000	\N	\N	\N	52000
a121222c-94f6-4bb1-aecf-6e620620784d	dae8c362-ab3a-45f8-8ea9-e610ecdc6834	1493e011-8a13-4cf4-b127-d3b8603ec572	\N	\N	\N	t	\N	true
b70f9a4c-8924-47de-9419-56b9d09fec0b	dae8c362-ab3a-45f8-8ea9-e610ecdc6834	cbd6477e-134d-44fb-aeb8-31abb4736dbc	бытовая техника	\N	\N	\N	\N	"бытовая техника"
e7bec92e-dff5-4a7b-88ca-9c10cc9cf1a6	545eb50f-a7c3-40c7-9d14-66ee6aea78e3	5f8cf6a3-3fe6-4aa7-9465-f61d9309d8bb	basic	\N	\N	\N	\N	"basic"
5fc8c0f6-70a4-40c2-8a5d-e6c3347a9b95	545eb50f-a7c3-40c7-9d14-66ee6aea78e3	beba1148-10f4-451f-8114-f738fe652b73	TCL	\N	\N	\N	\N	"TCL"
7d3bb6d9-4027-4623-86e6-f705beb07926	545eb50f-a7c3-40c7-9d14-66ee6aea78e3	442964a5-fe19-498b-a4c1-6af1c2157f08	\N	33000	\N	\N	\N	33000
bec4cd6c-6976-4794-8ce4-2e8eea3e691a	545eb50f-a7c3-40c7-9d14-66ee6aea78e3	1493e011-8a13-4cf4-b127-d3b8603ec572	\N	\N	\N	f	\N	false
66c874c9-a48b-4c68-bd68-76b25adc1c71	545eb50f-a7c3-40c7-9d14-66ee6aea78e3	cbd6477e-134d-44fb-aeb8-31abb4736dbc	телевизоры	\N	\N	\N	\N	"телевизоры"
bf9929b6-ab34-4595-9c7c-2b61b490cab9	a5c56ab3-74c4-4fb6-8987-6968ad93850c	5f8cf6a3-3fe6-4aa7-9465-f61d9309d8bb	basic	\N	\N	\N	\N	"basic"
e60e8b7a-287a-4099-bd9d-422709c6dcc7	a5c56ab3-74c4-4fb6-8987-6968ad93850c	beba1148-10f4-451f-8114-f738fe652b73	Xiaomi	\N	\N	\N	\N	"Xiaomi"
985e2ada-4572-4b02-b27f-e55aa326181b	a5c56ab3-74c4-4fb6-8987-6968ad93850c	442964a5-fe19-498b-a4c1-6af1c2157f08	\N	39000	\N	\N	\N	39000
58c93dcc-c3bf-44f1-ad94-51d027f30453	a5c56ab3-74c4-4fb6-8987-6968ad93850c	1493e011-8a13-4cf4-b127-d3b8603ec572	\N	\N	\N	t	\N	true
f6dd4af8-b849-42fb-9574-cc7828cbd0bd	a5c56ab3-74c4-4fb6-8987-6968ad93850c	cbd6477e-134d-44fb-aeb8-31abb4736dbc	смартфоны	\N	\N	\N	\N	"смартфоны"
0433c7f9-29e7-4816-8d5f-788e937d957f	a8b406e8-3108-4af6-a1f5-a7a72610fa77	5f8cf6a3-3fe6-4aa7-9465-f61d9309d8bb	gold	\N	\N	\N	\N	"gold"
b75e1fce-0a9c-4018-ad46-0b4a8c91ee96	a8b406e8-3108-4af6-a1f5-a7a72610fa77	beba1148-10f4-451f-8114-f738fe652b73	Microsoft	\N	\N	\N	\N	"Microsoft"
d09085fd-9cd1-4697-8950-aa597116a405	a8b406e8-3108-4af6-a1f5-a7a72610fa77	442964a5-fe19-498b-a4c1-6af1c2157f08	\N	85000	\N	\N	\N	85000
2e623882-95f2-44d4-bcf9-e113b793fdf1	a8b406e8-3108-4af6-a1f5-a7a72610fa77	1493e011-8a13-4cf4-b127-d3b8603ec572	\N	\N	\N	t	\N	true
fbf8eb03-6561-4ca2-9540-9e28b94ee63b	a8b406e8-3108-4af6-a1f5-a7a72610fa77	cbd6477e-134d-44fb-aeb8-31abb4736dbc	игровые консоли	\N	\N	\N	\N	"игровые консоли"
4eac56a7-3992-4a25-a219-c472185f54ab	c4072987-8e34-43a3-97c0-1f5543b9597e	5f8cf6a3-3fe6-4aa7-9465-f61d9309d8bb	gold	\N	\N	\N	\N	"gold"
61c84d7e-45ba-4cf3-9237-f45513a845dd	c4072987-8e34-43a3-97c0-1f5543b9597e	beba1148-10f4-451f-8114-f738fe652b73	Asus	\N	\N	\N	\N	"Asus"
2b1680fb-4a82-4d96-841c-8f2b5001e901	c4072987-8e34-43a3-97c0-1f5543b9597e	442964a5-fe19-498b-a4c1-6af1c2157f08	\N	95000	\N	\N	\N	95000
99e28a1b-53af-45e8-8ca9-7aa1c6ecd172	c4072987-8e34-43a3-97c0-1f5543b9597e	1493e011-8a13-4cf4-b127-d3b8603ec572	\N	\N	\N	f	\N	false
06658135-8b96-485c-aa8d-f940745af741	c4072987-8e34-43a3-97c0-1f5543b9597e	cbd6477e-134d-44fb-aeb8-31abb4736dbc	ноутбуки	\N	\N	\N	\N	"ноутбуки"
c27f18b4-d6fc-49db-987a-2514aaba0900	46f18937-fb05-42cf-b002-d9af780492e4	5f8cf6a3-3fe6-4aa7-9465-f61d9309d8bb	silver	\N	\N	\N	\N	"silver"
420a840d-b0f5-45b2-b161-2a2826f31b95	46f18937-fb05-42cf-b002-d9af780492e4	beba1148-10f4-451f-8114-f738fe652b73	Nikon	\N	\N	\N	\N	"Nikon"
813a7645-3eec-4036-89af-747c8eacc45f	46f18937-fb05-42cf-b002-d9af780492e4	442964a5-fe19-498b-a4c1-6af1c2157f08	\N	73000	\N	\N	\N	73000
93f7fd07-d0f4-4fd1-8705-7000c26654da	46f18937-fb05-42cf-b002-d9af780492e4	1493e011-8a13-4cf4-b127-d3b8603ec572	\N	\N	\N	t	\N	true
1d36b301-934c-4562-aadb-9d0d53469260	46f18937-fb05-42cf-b002-d9af780492e4	cbd6477e-134d-44fb-aeb8-31abb4736dbc	фото	\N	\N	\N	\N	"фото"
27acd3e4-18c1-4920-9e77-68fcf0a0dbab	d4c7f619-e8a9-470d-acc0-d1c976cbbf11	5f8cf6a3-3fe6-4aa7-9465-f61d9309d8bb	basic	\N	\N	\N	\N	"basic"
fdefe589-6d7f-414b-9c88-d49786359b20	d4c7f619-e8a9-470d-acc0-d1c976cbbf11	442964a5-fe19-498b-a4c1-6af1c2157f08	\N	25000	\N	\N	\N	25000
7c4114cd-50aa-46b5-8aad-8278c3bee7e1	d4c7f619-e8a9-470d-acc0-d1c976cbbf11	1493e011-8a13-4cf4-b127-d3b8603ec572	\N	\N	\N	f	\N	false
808b80f3-321c-428d-94ca-011b23d6ae13	841a025c-4b12-41ab-aaad-d88bdff03406	beba1148-10f4-451f-8114-f738fe652b73	Apple	\N	\N	\N	\N	"Apple"
92dfb9b7-9f10-46f7-b751-e012a0b5702c	841a025c-4b12-41ab-aaad-d88bdff03406	442964a5-fe19-498b-a4c1-6af1c2157f08	\N	150000	\N	\N	\N	150000
4de260e2-0efe-457a-8a8f-08290636d0b8	841a025c-4b12-41ab-aaad-d88bdff03406	cbd6477e-134d-44fb-aeb8-31abb4736dbc	ноутбуки	\N	\N	\N	\N	"ноутбуки"
15d72c92-a5d3-405b-8c00-798730b8f89a	6295c95d-393f-4dc4-822e-b1fb1e14c4e2	beba1148-10f4-451f-8114-f738fe652b73	Samsung	\N	\N	\N	\N	"Samsung"
2818bec9-e8b3-4a4a-bdc0-fb79e20348c1	6295c95d-393f-4dc4-822e-b1fb1e14c4e2	1493e011-8a13-4cf4-b127-d3b8603ec572	\N	\N	\N	t	\N	true
945f6421-c27d-4861-a364-c1d3f630f3b2	6295c95d-393f-4dc4-822e-b1fb1e14c4e2	cbd6477e-134d-44fb-aeb8-31abb4736dbc	смартфоны	\N	\N	\N	\N	"смартфоны"
4857bc67-ef7f-4e54-8c4a-28e04affa638	46d321ec-69be-4de6-a08e-31b3607a0a78	442964a5-fe19-498b-a4c1-6af1c2157f08	\N	80000	\N	\N	\N	80000
b1539ccd-c11c-4031-b434-836db38c571f	46d321ec-69be-4de6-a08e-31b3607a0a78	cbd6477e-134d-44fb-aeb8-31abb4736dbc	gaming	\N	\N	\N	\N	"gaming"
f9745977-11c8-4c4f-825f-67f7e762e6b7	46d321ec-69be-4de6-a08e-31b3607a0a78	beba1148-10f4-451f-8114-f738fe652b73	Lenovo	\N	\N	\N	\N	"Lenovo"
42febfff-9b77-4d42-abfc-e480890cc47c	9fb760a6-3618-4999-8537-bce4c127800e	87d0a155-e782-408c-8080-8d405e309d8f	\N	\N	\N	t	\N	true
b092af12-5956-4463-a8df-aef065326471	9fb760a6-3618-4999-8537-bce4c127800e	442964a5-fe19-498b-a4c1-6af1c2157f08	\N	300	\N	\N	\N	300
03e9455c-d8a9-4830-bddc-9b280827e933	9fb760a6-3618-4999-8537-bce4c127800e	cbd6477e-134d-44fb-aeb8-31abb4736dbc	умный дом	\N	\N	\N	\N	"умный дом"
758e47ab-cd2a-4f45-98a5-ac2a7684d06b	f3b76a50-5950-4a1e-9132-ac769c5b9e97	beba1148-10f4-451f-8114-f738fe652b73	LG	\N	\N	\N	\N	"LG"
c20fb3fe-929f-4956-bab4-c1d28040b3ac	f3b76a50-5950-4a1e-9132-ac769c5b9e97	cbd6477e-134d-44fb-aeb8-31abb4736dbc	TV	\N	\N	\N	\N	"TV"
498f28d1-c97b-4499-a010-735255048e25	d4c7f619-e8a9-470d-acc0-d1c976cbbf11	cbd6477e-134d-44fb-aeb8-31abb4736dbc	фото	\N	\N	\N	\N	"фото"
a37a2442-6e5b-4ed8-a9bd-95930c2f6b51	9fb760a6-3618-4999-8537-bce4c127800e	beba1148-10f4-451f-8114-f738fe652b73	нет предпочтений	\N	\N	\N	\N	"нет предпочтений"
96ec64c4-d631-4258-b023-e6e38944a655	7fb42bd1-ad5a-4582-ac10-9e5bcc2dd8e1	cbd6477e-134d-44fb-aeb8-31abb4736dbc	Ноутбуки	\N	\N	\N	\N	"Ноутбуки"
e7e36fcd-032f-4257-b642-850cc3359261	d4c7f619-e8a9-470d-acc0-d1c976cbbf11	87d0a155-e782-408c-8080-8d405e309d8f	\N	\N	\N	t	\N	true
fdbe7d46-baa8-4e9d-8150-2be20d56cdcc	d4c7f619-e8a9-470d-acc0-d1c976cbbf11	beba1148-10f4-451f-8114-f738fe652b73	iPhone	\N	\N	\N	\N	"iPhone"
ef13beb3-3a65-4c89-a985-c0575cf537f2	97a57ff9-a693-4a11-9f75-726a3be36cac	beba1148-10f4-451f-8114-f738fe652b73	HP	\N	\N	\N	\N	"HP"
8455eff3-a08e-4e48-8165-80642f328eaf	bb6e1a4b-9893-4b53-b078-c4861951aa77	cbd6477e-134d-44fb-aeb8-31abb4736dbc	смартфоны	\N	\N	\N	\N	"смартфоны"
10439265-7355-468d-99f8-c969b144f32f	fad46874-5f76-47dd-bcd6-f40b9ee82cef	beba1148-10f4-451f-8114-f738fe652b73	Apple	\N	\N	\N	\N	"Apple"
f6e659be-5894-41d8-8135-2c0e1f777965	fad46874-5f76-47dd-bcd6-f40b9ee82cef	b55497c7-8443-4016-b416-d9ec56bb9a5c	Apple	\N	\N	\N	\N	"Apple"
\.


--
-- Data for Name: user_consent; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.user_consent (consent_id, person_id, consent_type_id, is_granted, granted_at, revoked_at, source, raw_value) FROM stdin;
fd43a8fa-005b-4483-8c55-7e49d287b75f	97a57ff9-a693-4a11-9f75-726a3be36cac	4ff8c1af-3921-4c46-8ce5-821bc13c4a51	t	2026-05-06 10:00:00+03	\N	web_form	да, хочу скидки
df12f5f0-c068-4a81-b1e3-104ecd4c3a39	6c96c88a-10d3-4d86-9ba0-fc66136db266	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	2026-05-07 12:20:00+03	\N	mobile_app	+
e7856a5f-8c41-43c1-a862-f4327cc75f62	6c96c88a-10d3-4d86-9ba0-fc66136db266	b3d6764a-ea3b-4d58-8c27-dec8904f7791	f	\N	\N	mobile_app	sms: нет
6713e690-7234-42d9-971e-8863c066fa9c	c4a6968d-5546-4f23-a490-a3d665ad5345	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	2026-05-08 09:00:00+03	\N	call_center	оператор отметил согласие
d14aab70-b070-4ab6-9c89-dce9a7bac238	861d02aa-6c7f-4304-b410-2664595578e3	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	\N	\N	paper_form	бумажная анкета: да
a697765b-d587-4822-90d0-e845ac53c4f7	861d02aa-6c7f-4304-b410-2664595578e3	615e20ef-22cc-4dca-9c2c-9819788cade8	t	\N	\N	paper_form	передача партнерам: согласна
03911ab2-4a38-4a01-8db0-6f4160ce7cf4	eccefedc-537c-4f94-9fa4-521eeaedc5f5	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	2026-05-09 17:45:00+03	\N	web_form	accepted
e69e4d63-4ae3-4078-9241-e0af2587a326	ae5e8672-b19f-4867-91af-c02611ace804	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
97199065-c668-46fc-9805-03c4459f4f9b	ae5e8672-b19f-4867-91af-c02611ace804	4ff8c1af-3921-4c46-8ce5-821bc13c4a51	f	\N	\N	seed_bulk	email no
13be920a-536d-4e60-a98c-cb1a8abc3357	1c32e472-5262-46d0-be59-6c2f27e189f4	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
57f3c002-b107-4493-8a21-db361cf96be5	1c32e472-5262-46d0-be59-6c2f27e189f4	4ff8c1af-3921-4c46-8ce5-821bc13c4a51	t	\N	\N	seed_bulk	email yes
8bf3e894-a2f5-439f-8a28-834c14f0a060	7497918d-bdcf-4431-b365-db195d277432	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
ed09080b-8619-4ba6-80be-8091b0f1a308	7497918d-bdcf-4431-b365-db195d277432	4ff8c1af-3921-4c46-8ce5-821bc13c4a51	f	\N	\N	seed_bulk	email no
5a96e520-7a11-4a4e-8543-0025663dca4a	49582c70-48ce-4e74-8ed9-89b94943aabf	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
5b3ab141-3e32-483d-96d6-08d56e33efa5	49582c70-48ce-4e74-8ed9-89b94943aabf	4ff8c1af-3921-4c46-8ce5-821bc13c4a51	t	\N	\N	seed_bulk	email yes
8175bf9b-cdd8-4421-8e46-5426e666c154	63c6d99b-46ff-489f-a539-993a6f4d5f2f	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
9cb75fd1-b361-4d7e-8497-d837c7a46235	63c6d99b-46ff-489f-a539-993a6f4d5f2f	4ff8c1af-3921-4c46-8ce5-821bc13c4a51	f	\N	\N	seed_bulk	email no
4b23504a-5700-4a36-b5bd-7acf42062c2e	56b3b63c-803d-4da7-ab79-fe95491f18e5	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
1d6d64be-f982-4366-8406-f665178037ff	56b3b63c-803d-4da7-ab79-fe95491f18e5	4ff8c1af-3921-4c46-8ce5-821bc13c4a51	t	\N	\N	seed_bulk	email yes
e099237d-40d0-4a28-9590-27b443b683c5	76409892-50ee-45f8-b1b6-487129468310	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
681a6b5a-157a-498e-8f07-1aa83693639b	76409892-50ee-45f8-b1b6-487129468310	4ff8c1af-3921-4c46-8ce5-821bc13c4a51	f	\N	\N	seed_bulk	email no
c892ef9c-9bec-4f4b-bc78-2c4894dad8d7	74b11c35-2ca0-424d-888d-b03ead311080	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
c27cc8b8-ab6e-4e19-9460-69a063f8cef4	74b11c35-2ca0-424d-888d-b03ead311080	4ff8c1af-3921-4c46-8ce5-821bc13c4a51	t	\N	\N	seed_bulk	email yes
d712a415-bc8b-4108-b9d5-45df4be4bb75	7f4a4ca6-14f9-4e19-8928-ad5959e53d38	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
ca883efa-b757-4d42-92f3-f046276efce8	7f4a4ca6-14f9-4e19-8928-ad5959e53d38	4ff8c1af-3921-4c46-8ce5-821bc13c4a51	f	\N	\N	seed_bulk	email no
6e374021-2e66-44b2-8d48-82f0fe09ec5e	7869118c-d5c9-4c96-8332-fffd20599e5a	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
b932e916-c89a-4977-940b-cf2e155f86b3	7869118c-d5c9-4c96-8332-fffd20599e5a	4ff8c1af-3921-4c46-8ce5-821bc13c4a51	t	\N	\N	seed_bulk	email yes
6e9cd6d7-bae1-4035-955a-c7b8625bcf48	7fff1799-25cd-4a7a-be97-d50baae6e254	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
661ae332-7c44-4e7a-bee5-0f95610d2297	7fff1799-25cd-4a7a-be97-d50baae6e254	4ff8c1af-3921-4c46-8ce5-821bc13c4a51	f	\N	\N	seed_bulk	email no
4ead7b72-9852-496b-8730-68da0667b4fc	a86c4ecc-8947-4a30-968f-ff444042e54e	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
e682748e-26ca-45e3-8fe5-eae243076e6f	a86c4ecc-8947-4a30-968f-ff444042e54e	4ff8c1af-3921-4c46-8ce5-821bc13c4a51	t	\N	\N	seed_bulk	email yes
f8bc9aaa-83db-4340-9ffc-551bfb3e2e7b	22738087-7bfc-488e-88e3-c37f700e689c	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
f73d3d66-6725-4a7a-b9f8-4e3390cbd038	22738087-7bfc-488e-88e3-c37f700e689c	4ff8c1af-3921-4c46-8ce5-821bc13c4a51	f	\N	\N	seed_bulk	email no
6addf3be-59ec-4338-934a-bc0a063ea2e4	dae8c362-ab3a-45f8-8ea9-e610ecdc6834	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
8ce681da-d10c-49ec-948a-6b08a2aa4432	dae8c362-ab3a-45f8-8ea9-e610ecdc6834	4ff8c1af-3921-4c46-8ce5-821bc13c4a51	t	\N	\N	seed_bulk	email yes
a7eba562-3adb-4fbd-bea7-3b07a2f9965c	545eb50f-a7c3-40c7-9d14-66ee6aea78e3	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
2aba889b-c329-4aef-9bbc-13c653fe2847	545eb50f-a7c3-40c7-9d14-66ee6aea78e3	4ff8c1af-3921-4c46-8ce5-821bc13c4a51	f	\N	\N	seed_bulk	email no
d55c7f9a-8d60-4ea2-a053-12adc0f60e9b	a5c56ab3-74c4-4fb6-8987-6968ad93850c	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
5b3c2ddc-d14c-4996-a144-0a5b2a745552	a5c56ab3-74c4-4fb6-8987-6968ad93850c	4ff8c1af-3921-4c46-8ce5-821bc13c4a51	t	\N	\N	seed_bulk	email yes
65f61f8b-4919-4f3c-b5bc-17b0f7becffe	a8b406e8-3108-4af6-a1f5-a7a72610fa77	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
bc2668e4-6070-4443-af7b-86a4b7e5d2a5	a8b406e8-3108-4af6-a1f5-a7a72610fa77	4ff8c1af-3921-4c46-8ce5-821bc13c4a51	f	\N	\N	seed_bulk	email no
1e7f622a-4fe3-4a6a-b495-5d8b2ece57e6	c4072987-8e34-43a3-97c0-1f5543b9597e	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
4fce19d7-ed81-43b0-9c19-e5fa93ff7897	c4072987-8e34-43a3-97c0-1f5543b9597e	4ff8c1af-3921-4c46-8ce5-821bc13c4a51	t	\N	\N	seed_bulk	email yes
c1e1434d-a317-4555-80b4-dddce35209f2	46f18937-fb05-42cf-b002-d9af780492e4	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
e63723af-aeaf-4f54-b944-8d6f01940c1c	46f18937-fb05-42cf-b002-d9af780492e4	4ff8c1af-3921-4c46-8ce5-821bc13c4a51	f	\N	\N	seed_bulk	email no
e2d80c79-6169-4ce0-84f9-64941d51c2d0	841a025c-4b12-41ab-aaad-d88bdff03406	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	2021-05-10 00:00:00+03	\N	partner_source	обработка персональных данных=да
41f038fa-6d2f-4772-8443-1c6d46807dae	841a025c-4b12-41ab-aaad-d88bdff03406	4ff8c1af-3921-4c46-8ce5-821bc13c4a51	t	2021-05-10 00:00:00+03	\N	partner_source	рекламные рассылки=да
cd7b173b-a14f-4f24-9ed0-78fa817ea871	841a025c-4b12-41ab-aaad-d88bdff03406	615e20ef-22cc-4dca-9c2c-9819788cade8	f	\N	2021-05-10 00:00:00+03	partner_source	передача данных партнёрам=нет
7de1c45f-8f31-4796-acdc-13a8d8168108	6295c95d-393f-4dc4-822e-b1fb1e14c4e2	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	2022-11-03 00:00:00+03	\N	partner_source	персональные данные=1
1ddc0ee8-4e31-4cfa-8ad9-c893e903dadb	6295c95d-393f-4dc4-822e-b1fb1e14c4e2	4ff8c1af-3921-4c46-8ce5-821bc13c4a51	f	\N	2022-11-03 00:00:00+03	partner_source	маркетинг=0
bee95e12-8931-45b3-a0d8-30aad92b6bdc	46d321ec-69be-4de6-a08e-31b3607a0a78	4ff8c1af-3921-4c46-8ce5-821bc13c4a51	f	\N	2020-02-14 00:00:00+03	partner_source	реклама=no
56cca2ff-6d6a-4c74-a661-9e0b79ef1f36	46d321ec-69be-4de6-a08e-31b3607a0a78	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	2023-04-01 00:00:00+03	\N	partner_source	ПД=+
f75df144-af1b-4e0b-a5bb-e8c672e829f2	9fb760a6-3618-4999-8537-bce4c127800e	615e20ef-22cc-4dca-9c2c-9819788cade8	f	\N	2019-08-20 00:00:00+03	partner_source	передача партнёрам=НЕТ
28a6896a-1c25-4744-8f53-e393a800aa8b	f3b76a50-5950-4a1e-9132-ac769c5b9e97	4ff8c1af-3921-4c46-8ce5-821bc13c4a51	f	\N	2018-06-05 00:00:00+03	partner_source	маркетинг=false
d5151e48-a7a3-494d-af97-b73c36f5e684	f3b76a50-5950-4a1e-9132-ac769c5b9e97	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	2017-03-22 00:00:00+03	\N	partner_source	ПД=+
526f966a-a44f-48aa-9a12-be7a5c706488	fce2d6eb-fc55-4d17-bab0-06e159c14686	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	2025-01-10 00:00:00+03	\N	partner_source	персональные данные=1
e80be1d6-92c5-4669-9801-4b0f1c520a28	9fb760a6-3618-4999-8537-bce4c127800e	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	2020-09-01 00:00:00+03	\N	partner_source	ПД=да
6be64663-f734-4aae-a806-c3d6a2b4cdb3	9fb760a6-3618-4999-8537-bce4c127800e	4ff8c1af-3921-4c46-8ce5-821bc13c4a51	f	\N	2020-09-01 00:00:00+03	partner_source	реклама=-
957db55c-9ee1-4478-aad3-5e163bbb2075	7fb42bd1-ad5a-4582-ac10-9e5bcc2dd8e1	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	2016-12-01 00:00:00+03	\N	partner_source	обработка персональных данных=yes
4317d3e8-7c30-4610-9218-415b5ce6f7df	d4c7f619-e8a9-470d-acc0-d1c976cbbf11	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	2021-07-07 00:00:00+03	\N	partner_source	ПД=да
8610d22d-052d-4df8-8a94-07188ba565f9	d4c7f619-e8a9-470d-acc0-d1c976cbbf11	4ff8c1af-3921-4c46-8ce5-821bc13c4a51	t	2021-07-07 00:00:00+03	\N	partner_source	маркетинг=да
ddbd118e-3859-47b5-b530-b87767f96e06	50fc12d2-3450-4db8-aebe-c1a1a251254a	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	2022-07-15 00:00:00+03	\N	partner_source	персональные данные=TRUE
3a640432-3e43-416d-8940-f94a931f8ddd	2f4be900-91d9-49ed-855f-8ca0fc20b7aa	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	2023-09-10 00:00:00+03	\N	partner_source	ПД=1
24fc064c-7601-4d68-b7f8-53be1b4e38c0	97a57ff9-a693-4a11-9f75-726a3be36cac	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	2021-01-11 00:00:00+03	\N	partner_source	обработка ПД=да
4b58573d-e17f-4756-b846-9ab6435b0591	fad46874-5f76-47dd-bcd6-f40b9ee82cef	2a8f174d-543c-4e82-baab-72a3eb21ab23	t	2023-03-05 00:00:00+03	\N	partner_source	персональные данные=+
\.


--
-- Data for Name: user_contact; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.user_contact (contact_id, person_id, contact_type_id, contact_value, raw_value, is_primary, is_verified, created_at) FROM stdin;
aa69bba8-3c89-4f28-8185-6d82bdba8118	97a57ff9-a693-4a11-9f75-726a3be36cac	39457f53-d8cb-4441-bde1-1fb815cd342b	ivanov@example.ru	ivanov@example.ru, i.ivanov@oldmail.ru	t	t	2026-06-07 20:42:54.701885+03
5d31e596-2f20-42e7-b754-f16e7fc461d1	97a57ff9-a693-4a11-9f75-726a3be36cac	5a1aeff5-534d-4af0-8628-d4d16e03fc93	+79991234567	+7 (999) 123-45-67 / tg: @ivan_tech	t	f	2026-06-07 20:42:54.701885+03
73d3cd2b-4b1e-4eba-8265-5e33e9efd1d3	97a57ff9-a693-4a11-9f75-726a3be36cac	1e8b491c-4e17-4c68-835c-0565d42d7d74	@ivan_tech	+7 (999) 123-45-67 / tg: @ivan_tech	f	f	2026-06-07 20:42:54.701885+03
07759566-6de9-4796-bdbc-8cd8e2b6cc05	6c96c88a-10d3-4d86-9ba0-fc66136db266	39457f53-d8cb-4441-bde1-1fb815cd342b	m.pet.rova@example.com	m.pet.rova@example.com; petrova.work@example.org	t	f	2026-06-07 20:42:54.71933+03
b07882ee-7913-4dfc-b636-418d8020c63c	6c96c88a-10d3-4d86-9ba0-fc66136db266	39457f53-d8cb-4441-bde1-1fb815cd342b	petrova.work@example.org	m.pet.rova@example.com; petrova.work@example.org	f	f	2026-06-07 20:42:54.71933+03
cb76013f-5fbc-468d-a96b-8859aa000241	6c96c88a-10d3-4d86-9ba0-fc66136db266	5a1aeff5-534d-4af0-8628-d4d16e03fc93	+79161230000	8-916-123-00-00	f	f	2026-06-07 20:42:54.71933+03
37d39ecf-a8da-4d37-8a72-cc1e293313c6	c4a6968d-5546-4f23-a490-a3d665ad5345	39457f53-d8cb-4441-bde1-1fb815cd342b	bad-email-without-at	bad-email-without-at, alexey.sid@mail.ru	t	f	2026-06-07 20:42:54.726685+03
feebc118-79dd-4f84-a7f8-fc25a1edb5af	c4a6968d-5546-4f23-a490-a3d665ad5345	39457f53-d8cb-4441-bde1-1fb815cd342b	alexey.sid@mail.ru	bad-email-without-at, alexey.sid@mail.ru	f	f	2026-06-07 20:42:54.726685+03
70477aa9-c3f2-47d6-be4a-6cee5f6049dd	c4a6968d-5546-4f23-a490-a3d665ad5345	a0da05f6-cb98-4c6b-a503-4947100618ba	+79260001122	whatsapp +7 926 000 11 22	f	f	2026-06-07 20:42:54.726685+03
97726129-5576-48b3-b169-f2a8f77f2e70	861d02aa-6c7f-4304-b410-2664595578e3	5a1aeff5-534d-4af0-8628-d4d16e03fc93	+79035556677	тел. 9035556677	f	f	2026-06-07 20:42:54.730588+03
8fddfb98-57a6-45a0-9dde-114b1723e9f5	861d02aa-6c7f-4304-b410-2664595578e3	1e8b491c-4e17-4c68-835c-0565d42d7d74	@elena_devices	telegram: @elena_devices	f	f	2026-06-07 20:42:54.730588+03
56cc8fb4-22f4-4111-96e7-0a737ae3760d	eccefedc-537c-4f94-9fa4-521eeaedc5f5	39457f53-d8cb-4441-bde1-1fb815cd342b	denis.orlov@example.net	\N	t	t	2026-06-07 20:42:54.734272+03
9506c6a0-40e8-4a00-bb9f-6041cd77b0ba	ae5e8672-b19f-4867-91af-c02611ace804	39457f53-d8cb-4441-bde1-1fb815cd342b	p.smirnov@example.ru	p.smirnov@example.ru, smirnov.old@mail.ru	t	t	2026-06-07 20:42:54.738303+03
ee40e73c-e88a-4761-8a79-416c345f3201	ae5e8672-b19f-4867-91af-c02611ace804	5a1aeff5-534d-4af0-8628-d4d16e03fc93	+7 (916) 100-20-30	+7 (916) 100-20-30	f	f	2026-06-07 20:42:54.738303+03
d87f29d3-331b-4f34-8272-59f6bb05d255	1c32e472-5262-46d0-be59-6c2f27e189f4	39457f53-d8cb-4441-bde1-1fb815cd342b	olga.v@example.ru	olga.v@example.ru	t	t	2026-06-07 20:42:54.738303+03
5b376fa3-7b33-4813-a73b-4908c9f9d3c7	1c32e472-5262-46d0-be59-6c2f27e189f4	5a1aeff5-534d-4af0-8628-d4d16e03fc93	8-926-222-33-44	8-926-222-33-44	f	f	2026-06-07 20:42:54.738303+03
4398d3a6-1109-4f19-9c17-964f036dd5b8	7497918d-bdcf-4431-b365-db195d277432	39457f53-d8cb-4441-bde1-1fb815cd342b	roman.n@example.ru	roman.n@example.ru; r.nikitin@work.ru	t	t	2026-06-07 20:42:54.738303+03
a9645672-060e-45c4-be7d-3742dd28d2fb	7497918d-bdcf-4431-b365-db195d277432	5a1aeff5-534d-4af0-8628-d4d16e03fc93	+7 812 333 44 55	+7 812 333 44 55	f	f	2026-06-07 20:42:54.738303+03
d6a708af-2034-4b58-b5ab-9227c4df9bde	49582c70-48ce-4e74-8ed9-89b94943aabf	39457f53-d8cb-4441-bde1-1fb815cd342b	irina.m@example.ru	irina.m@example.ru	t	t	2026-06-07 20:42:54.738303+03
c413fb8b-269f-4976-be91-a078da479458	49582c70-48ce-4e74-8ed9-89b94943aabf	5a1aeff5-534d-4af0-8628-d4d16e03fc93	9035556677	9035556677	f	f	2026-06-07 20:42:54.738303+03
4322d97c-3e65-4230-8ba3-701676e890bc	63c6d99b-46ff-489f-a539-993a6f4d5f2f	39457f53-d8cb-4441-bde1-1fb815cd342b	g.alekseev@example.ru	g.alekseev@example.ru	t	t	2026-06-07 20:42:54.738303+03
0e8d547b-f1d2-47ab-9268-304c4cc0cbfa	63c6d99b-46ff-489f-a539-993a6f4d5f2f	5a1aeff5-534d-4af0-8628-d4d16e03fc93	+7(383)123-45-67	+7(383)123-45-67	f	f	2026-06-07 20:42:54.738303+03
ad1651f5-0e54-4612-b40c-d31404a6dd71	56b3b63c-803d-4da7-ab79-fe95491f18e5	39457f53-d8cb-4441-bde1-1fb815cd342b	d.romanova.example.ru	d.romanova.example.ru	t	f	2026-06-07 20:42:54.738303+03
9d9c7a2d-f61e-49e3-b884-c4701880f7e5	56b3b63c-803d-4da7-ab79-fe95491f18e5	5a1aeff5-534d-4af0-8628-d4d16e03fc93	+7 495 777 88 99	+7 495 777 88 99	f	f	2026-06-07 20:42:54.738303+03
89de31bc-c847-43ef-a1b6-761bce16efe5	76409892-50ee-45f8-b1b6-487129468310	39457f53-d8cb-4441-bde1-1fb815cd342b	max.g@example.ru	max.g@example.ru, gavrilov.max@mail.ru	t	t	2026-06-07 20:42:54.738303+03
2e629640-95a7-458e-b59d-5538bdb8a05d	76409892-50ee-45f8-b1b6-487129468310	5a1aeff5-534d-4af0-8628-d4d16e03fc93	8 800 555 35 35	8 800 555 35 35	f	f	2026-06-07 20:42:54.738303+03
d7098f86-99d7-4881-b470-b79e7829206f	74b11c35-2ca0-424d-888d-b03ead311080	39457f53-d8cb-4441-bde1-1fb815cd342b	v.egorova@example.ru	v.egorova@example.ru	t	t	2026-06-07 20:42:54.738303+03
fe0d091f-4c12-41e3-a769-b08529fe5dbb	74b11c35-2ca0-424d-888d-b03ead311080	5a1aeff5-534d-4af0-8628-d4d16e03fc93	+7-917-111-22-33	+7-917-111-22-33	f	f	2026-06-07 20:42:54.738303+03
ddd3ff11-7c38-44b3-a752-39efe116fc71	7f4a4ca6-14f9-4e19-8928-ad5959e53d38	39457f53-d8cb-4441-bde1-1fb815cd342b	s.pavlov@example.ru	s.pavlov@example.ru	t	t	2026-06-07 20:42:54.738303+03
d834c432-2d63-4a50-8658-e361213d87cf	7f4a4ca6-14f9-4e19-8928-ad5959e53d38	5a1aeff5-534d-4af0-8628-d4d16e03fc93	89161231212	89161231212	f	f	2026-06-07 20:42:54.738303+03
3c7de4cb-1f66-4304-8971-97d1f274541a	7869118c-d5c9-4c96-8332-fffd20599e5a	39457f53-d8cb-4441-bde1-1fb815cd342b	ks.fomina@example.ru	ks.fomina@example.ru; k.fomina@old.ru	t	t	2026-06-07 20:42:54.738303+03
f5c8aed4-ec8a-4227-b7b8-772cd3739164	7869118c-d5c9-4c96-8332-fffd20599e5a	5a1aeff5-534d-4af0-8628-d4d16e03fc93	+7 921 000 11 22	+7 921 000 11 22	f	f	2026-06-07 20:42:54.738303+03
b0cd9d4e-75ae-4a91-918e-0e49a963a456	7fff1799-25cd-4a7a-be97-d50baae6e254	39457f53-d8cb-4441-bde1-1fb815cd342b	matvey.b@example.ru	matvey.b@example.ru	t	t	2026-06-07 20:42:54.738303+03
6a3dca0e-b879-4def-adb3-f446dc4f0660	7fff1799-25cd-4a7a-be97-d50baae6e254	5a1aeff5-534d-4af0-8628-d4d16e03fc93	+7 999 010 20 30	+7 999 010 20 30	f	f	2026-06-07 20:42:54.738303+03
6eb46cc0-5468-45c8-a850-cd741bb482e7	a86c4ecc-8947-4a30-968f-ff444042e54e	39457f53-d8cb-4441-bde1-1fb815cd342b	n.solovieva@example.ru	n.solovieva@example.ru	t	t	2026-06-07 20:42:54.738303+03
cf27f654-f2a2-4325-a53b-1787af66be5f	a86c4ecc-8947-4a30-968f-ff444042e54e	5a1aeff5-534d-4af0-8628-d4d16e03fc93	+7 903 444 55 66	+7 903 444 55 66	f	f	2026-06-07 20:42:54.738303+03
2b984e25-a2f9-4182-9b40-54627caf96db	22738087-7bfc-488e-88e3-c37f700e689c	39457f53-d8cb-4441-bde1-1fb815cd342b	ars.titov@example.ru	ars.titov@example.ru	t	t	2026-06-07 20:42:54.738303+03
3a0e4901-3f82-4525-965f-92d71555faf3	22738087-7bfc-488e-88e3-c37f700e689c	5a1aeff5-534d-4af0-8628-d4d16e03fc93	8(901)234-56-78	8(901)234-56-78	f	f	2026-06-07 20:42:54.738303+03
66b284db-8410-4932-8db6-501895da1c36	dae8c362-ab3a-45f8-8ea9-e610ecdc6834	39457f53-d8cb-4441-bde1-1fb815cd342b	alina.m@example.ru	alina.m@example.ru	t	t	2026-06-07 20:42:54.738303+03
e96f5197-7db5-4b7c-9e92-7204bbd8f082	dae8c362-ab3a-45f8-8ea9-e610ecdc6834	5a1aeff5-534d-4af0-8628-d4d16e03fc93	+79269998877	+79269998877	f	f	2026-06-07 20:42:54.738303+03
19a7dfb9-b6e9-4b52-834d-bbb8700959a0	545eb50f-a7c3-40c7-9d14-66ee6aea78e3	39457f53-d8cb-4441-bde1-1fb815cd342b	fedorkrylov.mail.ru	fedorkrylov.mail.ru	t	f	2026-06-07 20:42:54.738303+03
4bed3db9-ff4a-4fcc-83a3-c83faefda46e	545eb50f-a7c3-40c7-9d14-66ee6aea78e3	5a1aeff5-534d-4af0-8628-d4d16e03fc93	+79123456789	+79123456789	f	f	2026-06-07 20:42:54.738303+03
757d9d24-c04e-4afb-9361-c4b9a1b47b8b	a5c56ab3-74c4-4fb6-8987-6968ad93850c	39457f53-d8cb-4441-bde1-1fb815cd342b	m.zueva@example.ru	m.zueva@example.ru, marina.zueva@work.ru	t	t	2026-06-07 20:42:54.738303+03
bcf02330-99b3-44c4-bb5f-089519507035	a5c56ab3-74c4-4fb6-8987-6968ad93850c	5a1aeff5-534d-4af0-8628-d4d16e03fc93	8 800 333 44 55	8 800 333 44 55	f	f	2026-06-07 20:42:54.738303+03
aa23b141-50c3-4f40-8728-69ba45bfc0be	a8b406e8-3108-4af6-a1f5-a7a72610fa77	39457f53-d8cb-4441-bde1-1fb815cd342b	anton.k@example.ru	anton.k@example.ru	t	t	2026-06-07 20:42:54.738303+03
68b9142e-cc2f-407d-a114-8279c6e79151	a8b406e8-3108-4af6-a1f5-a7a72610fa77	5a1aeff5-534d-4af0-8628-d4d16e03fc93	+74951234567	+74951234567	f	f	2026-06-07 20:42:54.738303+03
8c29e25b-bf39-49ca-8000-c291b809f9c6	c4072987-8e34-43a3-97c0-1f5543b9597e	39457f53-d8cb-4441-bde1-1fb815cd342b	y.makarova@example.ru	y.makarova@example.ru	t	t	2026-06-07 20:42:54.738303+03
c5b92709-2232-4be1-921f-b87114ee2007	c4072987-8e34-43a3-97c0-1f5543b9597e	5a1aeff5-534d-4af0-8628-d4d16e03fc93	+7(863)222-33-44	+7(863)222-33-44	f	f	2026-06-07 20:42:54.738303+03
cf2d133f-78b3-4d79-b7a3-e7d30cc68940	46f18937-fb05-42cf-b002-d9af780492e4	39457f53-d8cb-4441-bde1-1fb815cd342b	lev.d@example.ru	lev.d@example.ru	t	t	2026-06-07 20:42:54.738303+03
a004538c-b82e-44a0-ad8b-a4e7f347ae90	46f18937-fb05-42cf-b002-d9af780492e4	5a1aeff5-534d-4af0-8628-d4d16e03fc93	+7 812 333 44 56	+7 812 333 44 56	f	f	2026-06-07 20:42:54.738303+03
e5099f56-4994-4d4f-91a6-ea3ab14a8e55	d4c7f619-e8a9-470d-acc0-d1c976cbbf11	39457f53-d8cb-4441-bde1-1fb815cd342b	s.borisova@example.ru	s.borisova@example.ru	t	t	2026-06-07 20:42:54.738303+03
55b3bdae-ed69-4fb5-bd4c-466169258308	d4c7f619-e8a9-470d-acc0-d1c976cbbf11	5a1aeff5-534d-4af0-8628-d4d16e03fc93	8-926-123-45-67	8-926-123-45-67	f	f	2026-06-07 20:42:54.738303+03
9f39b48e-ac0f-4b08-9573-55695aeff626	841a025c-4b12-41ab-aaad-d88bdff03406	39457f53-d8cb-4441-bde1-1fb815cd342b	ivan.ivanov@gmail.com	ivan.ivanov@gmail.com	t	f	2026-06-07 20:42:54.833905+03
f0db0b91-639b-46ee-9e94-9c58f400770f	841a025c-4b12-41ab-aaad-d88bdff03406	5a1aeff5-534d-4af0-8628-d4d16e03fc93	79261234567	+79261234567	t	f	2026-06-07 20:42:54.833905+03
e6b241e4-36ed-46e4-bc78-fd6bf87af5e5	6295c95d-393f-4dc4-822e-b1fb1e14c4e2	39457f53-d8cb-4441-bde1-1fb815cd342b	anna.petrova@mail.ru	ANNA.PETROVA@MAIL.RU, a.petrova@yandex.ru	t	f	2026-06-07 20:42:54.833905+03
492d0e1f-7c9c-4511-b98a-c9a6921997d4	6295c95d-393f-4dc4-822e-b1fb1e14c4e2	39457f53-d8cb-4441-bde1-1fb815cd342b	a.petrova@yandex.ru	ANNA.PETROVA@MAIL.RU, a.petrova@yandex.ru	f	f	2026-06-07 20:42:54.833905+03
0aa2fe63-c957-465b-a152-d7926343419b	6295c95d-393f-4dc4-822e-b1fb1e14c4e2	5a1aeff5-534d-4af0-8628-d4d16e03fc93	89165551122	8(916)555-11-22	t	f	2026-06-07 20:42:54.833905+03
2a14516d-666e-43cb-9c6e-55bb1dbc812b	46d321ec-69be-4de6-a08e-31b3607a0a78	39457f53-d8cb-4441-bde1-1fb815cd342b	kozlov.ae@bk.ru	kozlov.ae@bk.ru	t	f	2026-06-07 20:42:54.833905+03
2afdaba7-17a6-4782-a72f-eb573a620652	46d321ec-69be-4de6-a08e-31b3607a0a78	5a1aeff5-534d-4af0-8628-d4d16e03fc93	83834445566	8 383 444 55 66	t	f	2026-06-07 20:42:54.833905+03
9a2729ef-a9e5-4275-882c-ef14e4467d3e	46d321ec-69be-4de6-a08e-31b3607a0a78	39457f53-d8cb-4441-bde1-1fb815cd342b	b.sidorov@inbox.ru	b.sidorov@inbox.ru	t	f	2026-06-07 20:42:54.833905+03
2ed995ac-6ab1-434e-a59a-56951207b9f5	46d321ec-69be-4de6-a08e-31b3607a0a78	5a1aeff5-534d-4af0-8628-d4d16e03fc93	89161112233	89161112233	t	f	2026-06-07 20:42:54.833905+03
30fdc528-86d9-4979-b8fa-e2ef087d44d4	9fb760a6-3618-4999-8537-bce4c127800e	39457f53-d8cb-4441-bde1-1fb815cd342b	e.novikova@work.ru	e.novikova@work.ru,novikova85@mail.ru ,ea_nov@yandex.ru	t	f	2026-06-07 20:42:54.833905+03
b6204821-838d-4bd6-acc6-2755e94bd0ec	9fb760a6-3618-4999-8537-bce4c127800e	39457f53-d8cb-4441-bde1-1fb815cd342b	novikova85@mail.ru	e.novikova@work.ru,novikova85@mail.ru ,ea_nov@yandex.ru	f	f	2026-06-07 20:42:54.833905+03
1fd466ba-bd16-46f8-b12c-b6911afcb53b	9fb760a6-3618-4999-8537-bce4c127800e	39457f53-d8cb-4441-bde1-1fb815cd342b	ea_nov@yandex.ru	e.novikova@work.ru,novikova85@mail.ru ,ea_nov@yandex.ru	f	f	2026-06-07 20:42:54.833905+03
57b31e18-8ffb-49b5-93de-28209d8d4c60	9fb760a6-3618-4999-8537-bce4c127800e	5a1aeff5-534d-4af0-8628-d4d16e03fc93	74956001122	+7-495-600-11-22	t	f	2026-06-07 20:42:54.833905+03
0fcc7745-cebd-4db6-9616-b70a1b29e88e	f3b76a50-5950-4a1e-9132-ac769c5b9e97	39457f53-d8cb-4441-bde1-1fb815cd342b	morozov_da@gmail.com	morozov_da@gmail.com	t	f	2026-06-07 20:42:54.833905+03
732b3223-99c2-4e19-91f7-8367a812e639	f3b76a50-5950-4a1e-9132-ac769c5b9e97	5a1aeff5-534d-4af0-8628-d4d16e03fc93	89267778899	8 926 777 88 99	t	f	2026-06-07 20:42:54.833905+03
ae42c814-2891-4a36-80c7-2cdacaec7640	f3b76a50-5950-4a1e-9132-ac769c5b9e97	39457f53-d8cb-4441-bde1-1fb815cd342b	lebedev.sergey@list.ru	lebedev.sergey@list.ru	t	f	2026-06-07 20:42:54.833905+03
7090ccfa-fde7-447c-a24f-70bdad8eb222	f3b76a50-5950-4a1e-9132-ac769c5b9e97	5a1aeff5-534d-4af0-8628-d4d16e03fc93	78123334455	+7 812 333 44 55	t	f	2026-06-07 20:42:54.833905+03
b3d5797e-ff69-4d1f-8aba-973555ed50ae	d4c7f619-e8a9-470d-acc0-d1c976cbbf11	39457f53-d8cb-4441-bde1-1fb815cd342b	nat.sokolova@gmail.com	nat.sokolova@gmail.com	t	f	2026-06-07 20:42:54.833905+03
12a9245f-d484-4c12-b22b-35bfe576c880	d4c7f619-e8a9-470d-acc0-d1c976cbbf11	5a1aeff5-534d-4af0-8628-d4d16e03fc93	89261234567	8-926-123-45-67	t	f	2026-06-07 20:42:54.833905+03
1b50fe2b-f642-4626-95b8-6143f7b9df69	fce2d6eb-fc55-4d17-bab0-06e159c14686	39457f53-d8cb-4441-bde1-1fb815cd342b	andreym_2000@inbox.ru	andreyM_2000@inbox.ru  andr.mikhaylov@corp.ru	t	f	2026-06-07 20:42:54.833905+03
390decbc-fc2a-4e8a-be14-4254ecbe19c5	fce2d6eb-fc55-4d17-bab0-06e159c14686	39457f53-d8cb-4441-bde1-1fb815cd342b	andr.mikhaylov@corp.ru	andreyM_2000@inbox.ru  andr.mikhaylov@corp.ru	f	f	2026-06-07 20:42:54.833905+03
5115cd2f-022d-4c26-a23b-585be2917c5c	9fb760a6-3618-4999-8537-bce4c127800e	39457f53-d8cb-4441-bde1-1fb815cd342b	fedorova_y@yandex.ru	fedorova_y@yandex.ru	t	f	2026-06-07 20:42:54.833905+03
bcd32da3-de3c-4eea-8f80-54b28e5eca82	9fb760a6-3618-4999-8537-bce4c127800e	5a1aeff5-534d-4af0-8628-d4d16e03fc93	78632223344	+7(863)222-33-44	t	f	2026-06-07 20:42:54.833905+03
bd86f7dd-b6f6-4577-9279-543ba5da592b	7fb42bd1-ad5a-4582-ac10-9e5bcc2dd8e1	39457f53-d8cb-4441-bde1-1fb815cd342b	v.popov@corp.ru	v.popov@corp.ru	t	f	2026-06-07 20:42:54.833905+03
865325a6-cb11-48ec-b741-d7587f9369cd	7fb42bd1-ad5a-4582-ac10-9e5bcc2dd8e1	5a1aeff5-534d-4af0-8628-d4d16e03fc93	74951112233	+7 495 111 22 33	t	f	2026-06-07 20:42:54.833905+03
11af821a-ea3a-4d54-8eee-900a7be98f88	d4c7f619-e8a9-470d-acc0-d1c976cbbf11	39457f53-d8cb-4441-bde1-1fb815cd342b	anna.k@gmail.com	anna.k@gmail.com	t	f	2026-06-07 20:42:54.833905+03
0a92a8f3-b66d-4d8d-b988-b41725bade8e	d4c7f619-e8a9-470d-acc0-d1c976cbbf11	5a1aeff5-534d-4af0-8628-d4d16e03fc93	74951234567	+7(495) 123-45-67	t	f	2026-06-07 20:42:54.833905+03
5864423e-c9cc-4688-b373-58caffad705b	d4c7f619-e8a9-470d-acc0-d1c976cbbf11	5a1aeff5-534d-4af0-8628-d4d16e03fc93	89268889900	8-926-888-99-00	f	f	2026-06-07 20:42:54.833905+03
9458e775-99ee-4ed1-9c68-de5b61dafe28	50fc12d2-3450-4db8-aebe-c1a1a251254a	39457f53-d8cb-4441-bde1-1fb815cd342b	roman.zaitsev@rambler.ru	roman.zaitsev@rambler.ru	t	f	2026-06-07 20:42:54.833905+03
d555ac33-f777-4ca1-bd48-fc28dc3df83f	50fc12d2-3450-4db8-aebe-c1a1a251254a	5a1aeff5-534d-4af0-8628-d4d16e03fc93	89031234567	89031234567	t	f	2026-06-07 20:42:54.833905+03
e7f09e6b-9c50-466f-af26-ce9481ee3a52	2f4be900-91d9-49ed-855f-8ca0fc20b7aa	39457f53-d8cb-4441-bde1-1fb815cd342b	belova_ks@mail.ru	belova_ks@mail.ru, belova.kseniya@gmail.com	t	f	2026-06-07 20:42:54.833905+03
76a9d0a5-1962-4214-b0f1-bf116a648cc2	2f4be900-91d9-49ed-855f-8ca0fc20b7aa	39457f53-d8cb-4441-bde1-1fb815cd342b	belova.kseniya@gmail.com	belova_ks@mail.ru, belova.kseniya@gmail.com	f	f	2026-06-07 20:42:54.833905+03
4c7cd5b5-a21c-4b48-9fea-9de70234b75d	2f4be900-91d9-49ed-855f-8ca0fc20b7aa	5a1aeff5-534d-4af0-8628-d4d16e03fc93	9261112233	926-111-22-33	t	f	2026-06-07 20:42:54.833905+03
f10d1005-a7b9-42e6-bd44-b569fedfe13f	97a57ff9-a693-4a11-9f75-726a3be36cac	39457f53-d8cb-4441-bde1-1fb815cd342b	k.tarasov@yandex.ru	k.tarasov@yandex.ru	t	f	2026-06-07 20:42:54.833905+03
a4fcf9a7-2d37-4be0-a4e2-a3f3950d85f5	97a57ff9-a693-4a11-9f75-726a3be36cac	5a1aeff5-534d-4af0-8628-d4d16e03fc93	83839998877	8(383)999-88-77	t	f	2026-06-07 20:42:54.833905+03
2742f959-e168-4591-a6e5-080f7afb371c	fad46874-5f76-47dd-bcd6-f40b9ee82cef	39457f53-d8cb-4441-bde1-1fb815cd342b	artem.gromov@gmail.com	artem.gromov@gmail.com;a.gromov@work.ru	t	f	2026-06-07 20:42:54.833905+03
ecbeb49a-b4e7-4639-b3ca-692554f3d932	fad46874-5f76-47dd-bcd6-f40b9ee82cef	39457f53-d8cb-4441-bde1-1fb815cd342b	a.gromov@work.ru	artem.gromov@gmail.com;a.gromov@work.ru	f	f	2026-06-07 20:42:54.833905+03
175ac22a-d989-4da8-8690-d41637d918e9	fad46874-5f76-47dd-bcd6-f40b9ee82cef	5a1aeff5-534d-4af0-8628-d4d16e03fc93	79151234567	+79151234567	t	f	2026-06-07 20:42:54.833905+03
6b637e29-f293-489c-91e3-4612eee52689	bb6e1a4b-9893-4b53-b078-c4861951aa77	39457f53-d8cb-4441-bde1-1fb815cd342b	frolova_n@bk.ru	frolova_n@bk.ru	t	f	2026-06-07 20:42:54.833905+03
b42f550f-d14e-4293-9e39-dfc20a619c0f	bb6e1a4b-9893-4b53-b078-c4861951aa77	5a1aeff5-534d-4af0-8628-d4d16e03fc93	79177776655	+7 917 777 66 55	t	f	2026-06-07 20:42:54.833905+03
6c5c103e-a968-4e1e-88ac-7048f7243e7c	fad46874-5f76-47dd-bcd6-f40b9ee82cef	39457f53-d8cb-4441-bde1-1fb815cd342b	o.zakharov@inbox.ru	o.zakharov@inbox.ru	t	f	2026-06-07 20:42:54.833905+03
4a1ab831-23ce-4b36-b0b5-5f9a3ad26953	fad46874-5f76-47dd-bcd6-f40b9ee82cef	5a1aeff5-534d-4af0-8628-d4d16e03fc93	89254567890	8 (925) 456 78 90	t	f	2026-06-07 20:42:54.833905+03
ab892c2c-1d36-41cd-b9c5-310892d9ddb0	fad46874-5f76-47dd-bcd6-f40b9ee82cef	39457f53-d8cb-4441-bde1-1fb815cd342b	marinakrylova.mail.ru	marinakrylova.mail.ru	t	f	2026-06-07 20:42:54.833905+03
ff09b8ff-f6ce-4d9a-b19a-fe8483d6a821	fad46874-5f76-47dd-bcd6-f40b9ee82cef	5a1aeff5-534d-4af0-8628-d4d16e03fc93	79123456789	+79123456789	t	f	2026-06-07 20:42:54.833905+03
afb95770-ade0-490a-94d8-d430806530bd	fad46874-5f76-47dd-bcd6-f40b9ee82cef	39457f53-d8cb-4441-bde1-1fb815cd342b	v.bogdanov@gmail.com	v.bogdanov@gmail.com	t	f	2026-06-07 20:42:54.833905+03
2968010a-f3d2-4d60-a41d-52da7891f482	fad46874-5f76-47dd-bcd6-f40b9ee82cef	5a1aeff5-534d-4af0-8628-d4d16e03fc93	88003334455	8 800 333 44 55	t	f	2026-06-07 20:42:54.833905+03
c0d5cfc0-98f0-403c-b810-34766f62fbb4	dae8c362-ab3a-45f8-8ea9-e610ecdc6834	39457f53-d8cb-4441-bde1-1fb815cd342b	alina.simonova@yandex.ru	alina.simonova@yandex.ru	t	f	2026-06-07 20:42:54.833905+03
6f142a06-b3ca-49a1-9dbc-f610065160ec	dae8c362-ab3a-45f8-8ea9-e610ecdc6834	5a1aeff5-534d-4af0-8628-d4d16e03fc93	79269998877	+79269998877	t	f	2026-06-07 20:42:54.833905+03
2e695783-efac-43d6-acb4-ecca8b9699fc	dae8c362-ab3a-45f8-8ea9-e610ecdc6834	39457f53-d8cb-4441-bde1-1fb815cd342b	kirill_v@hotmail.com	kirill_v@hotmail.com	t	f	2026-06-07 20:42:54.833905+03
50e53281-1695-48dd-a5e6-bb4716c89c19	a8b406e8-3108-4af6-a1f5-a7a72610fa77	39457f53-d8cb-4441-bde1-1fb815cd342b	d.gorbunova@gmail.com	d.gorbunova@gmail.com	t	f	2026-06-07 20:42:54.833905+03
f167dedc-a945-41eb-abb6-26f50484ef96	a8b406e8-3108-4af6-a1f5-a7a72610fa77	5a1aeff5-534d-4af0-8628-d4d16e03fc93	74951234567	+74951234567	t	f	2026-06-07 20:42:54.833905+03
ca08c852-9f4e-40b3-999b-17514a779477	a4ff128d-9934-40f3-a356-e9a2127694b0	39457f53-d8cb-4441-bde1-1fb815cd342b	ion.popescu@mail.ru	ion.popescu@mail.ru	t	f	2026-06-07 20:42:54.833905+03
5fe9fe99-6861-49cc-bef8-fca2043ab83f	a4ff128d-9934-40f3-a356-e9a2127694b0	5a1aeff5-534d-4af0-8628-d4d16e03fc93	37369123456	+37369123456	t	f	2026-06-07 20:42:54.833905+03
aabd1e37-3f6b-4336-8cda-4a6a05ec5779	dae8c362-ab3a-45f8-8ea9-e610ecdc6834	39457f53-d8cb-4441-bde1-1fb815cd342b	ilya.chernov@gmail.com	ilya.chernov@gmail.com	t	f	2026-06-07 20:42:54.833905+03
d9ea2aa8-ea35-4a04-a3c1-d40522aac8ec	dae8c362-ab3a-45f8-8ea9-e610ecdc6834	5a1aeff5-534d-4af0-8628-d4d16e03fc93	89012345678	8 901 234 56 78	t	f	2026-06-07 20:42:54.833905+03
\.


--
-- Data for Name: user_verification_document; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.user_verification_document (document_id, person_id, document_type_id, series, number, issue_date, issue_date_raw, issued_by, raw_document_text, verification_status_id) FROM stdin;
7eaa1a0f-658c-4be1-81cf-f31a3543afd8	97a57ff9-a693-4a11-9f75-726a3be36cac	138e4cc4-46b7-4036-ad46-bea30038a441	4510	123456	2018-02-10	10.02.2018	ОВД Тверского района	4510 123456 выдан ОВД Тверского района 10.02.2018	019fba6a-3f09-4274-83f6-cb7dfbc79b14
38f69427-b074-4c2d-b46c-aa2c3dd06cd0	6c96c88a-10d3-4d86-9ba0-fc66136db266	c72a246b-3cdb-4f2b-97ba-321340ca08b9	77AA	654321	2019-03-15	2019-03-15	ГИБДД Москва	ВУ 77AA 654321 от 2019-03-15	1baa0e63-e8ee-408b-a4de-3392d3943d14
539e82c0-6eb0-4729-8425-b9fabc4516fc	c4a6968d-5546-4f23-a490-a3d665ad5345	138e4cc4-46b7-4036-ad46-bea30038a441	4012	777888	2016-03-20	20 марта 2016 года	ТП №1	паспорт 4012 777888 кем и когда выдан: ТП №1 20 марта 2016 года	cb5d0166-d2b0-466e-a948-5c60b6d90522
3ac32514-bc91-47a9-8d55-5fb2ad53233d	861d02aa-6c7f-4304-b410-2664595578e3	30dcd865-b7b2-47b2-b74a-357ae8b30410	МК	009988	2020-01-01	01.01.20	военкомат	МК 009988 военкомат 01.01.20	8c6267b2-c98b-4f9f-8622-56c47ae63e1b
68059409-4e83-47b8-8108-958507ca32c0	7497918d-bdcf-4431-b365-db195d277432	138e4cc4-46b7-4036-ad46-bea30038a441	4513	500111	2013-04-10	10.04.2013	ОВД района	паспорт одной строкой: серия 4513 номер 500111	cb5d0166-d2b0-466e-a948-5c60b6d90522
32e29b26-187b-4991-9e4e-912fadc3e799	56b3b63c-803d-4da7-ab79-fe95491f18e5	138e4cc4-46b7-4036-ad46-bea30038a441	4516	500222	2016-07-10	10.07.2016	ОВД района	паспорт одной строкой: серия 4516 номер 500222	cb5d0166-d2b0-466e-a948-5c60b6d90522
5ead2ac9-552c-4717-919e-8f37f7344849	7f4a4ca6-14f9-4e19-8928-ad5959e53d38	138e4cc4-46b7-4036-ad46-bea30038a441	4519	500333	2019-02-10	10.02.2019	ОВД района	паспорт одной строкой: серия 4519 номер 500333	cb5d0166-d2b0-466e-a948-5c60b6d90522
41c53cc7-e3f9-4d94-8447-73bbc5914f22	a86c4ecc-8947-4a30-968f-ff444042e54e	138e4cc4-46b7-4036-ad46-bea30038a441	4522	500444	2012-05-10	10.05.2012	ОВД района	паспорт одной строкой: серия 4522 номер 500444	cb5d0166-d2b0-466e-a948-5c60b6d90522
92473ec7-fd1e-4f56-82ab-c8dac28cdb42	545eb50f-a7c3-40c7-9d14-66ee6aea78e3	138e4cc4-46b7-4036-ad46-bea30038a441	4525	500555	2015-08-10	10.08.2015	ОВД района	паспорт одной строкой: серия 4525 номер 500555	cb5d0166-d2b0-466e-a948-5c60b6d90522
3c55d939-db03-4856-9aef-cfab739e3d6e	c4072987-8e34-43a3-97c0-1f5543b9597e	138e4cc4-46b7-4036-ad46-bea30038a441	4528	500666	2018-03-10	10.03.2018	ОВД района	паспорт одной строкой: серия 4528 номер 500666	cb5d0166-d2b0-466e-a948-5c60b6d90522
d8d47fc2-4e06-4eed-b8ce-9754832bf4b3	841a025c-4b12-41ab-aaad-d88bdff03406	138e4cc4-46b7-4036-ad46-bea30038a441	4516	654321	2016-04-01	01.04.2016	4516 654321 выдан ОУФМС России по р-ну Печатники г.Москвы 01.04.2016 к/п 770-007	4516 654321 выдан ОУФМС России по р-ну Печатники г.Москвы 01.04.2016 к/п 770-007	cb5d0166-d2b0-466e-a948-5c60b6d90522
b646fe3e-3b42-4803-82ff-917c05e29ef8	6295c95d-393f-4dc4-822e-b1fb1e14c4e2	138e4cc4-46b7-4036-ad46-bea30038a441	4513	123789	2012-08-20	20.08.2012	серия 4513 № 123789, ОВД Академический г.Москвы, дата 20.08.2012	серия 4513 № 123789, ОВД Академический г.Москвы, дата 20.08.2012	cb5d0166-d2b0-466e-a948-5c60b6d90522
fefc6308-7894-4c04-85e9-09754ea0d955	46d321ec-69be-4de6-a08e-31b3607a0a78	138e4cc4-46b7-4036-ad46-bea30038a441	4512	998877	2012-09-12	12.09.2012	45 12 998877 ОВД района Бибирево г.Москвы 12.09.2012	45 12 998877 ОВД района Бибирево г.Москвы 12.09.2012	cb5d0166-d2b0-466e-a948-5c60b6d90522
4e0a5783-d4af-447a-82b8-3f95099a904e	46d321ec-69be-4de6-a08e-31b3607a0a78	138e4cc4-46b7-4036-ad46-bea30038a441	4508	789012	2008-06-01	01.06.2008	Серия:45 08 Номер:789012, Кем выдан: ОФМС района Измайлово г.Москвы, Дата:01.06.2008	Серия:45 08 Номер:789012, Кем выдан: ОФМС района Измайлово г.Москвы, Дата:01.06.2008	cb5d0166-d2b0-466e-a948-5c60b6d90522
c7407b1a-c95a-411f-8dd6-9843001df2cf	9fb760a6-3618-4999-8537-bce4c127800e	138e4cc4-46b7-4036-ad46-bea30038a441	4509	112233	2009-04-20	20.04.2009	4509 112233 ОУФМС России 77 рег. 20.04.2009 770-043	4509 112233 ОУФМС России 77 рег. 20.04.2009 770-043	cb5d0166-d2b0-466e-a948-5c60b6d90522
b4276481-3626-4429-8376-9eb3b7ec5188	f3b76a50-5950-4a1e-9132-ac769c5b9e97	138e4cc4-46b7-4036-ad46-bea30038a441	4014	876543	2014-03-15	15-03-2014	40 14 876543 / ОУФМС Тверской / 15-03-2014 / к/п 770-013	40 14 876543 / ОУФМС Тверской / 15-03-2014 / к/п 770-013	cb5d0166-d2b0-466e-a948-5c60b6d90522
4bf4b6b8-bd14-4bac-8e0b-e05dc4a715ca	f3b76a50-5950-4a1e-9132-ac769c5b9e97	138e4cc4-46b7-4036-ad46-bea30038a441	4515	567890	2015-12-15	15.12.2015	с.4515 н.567890 выд.15.12.2015 УФМС по г.СПб и ЛО по Адмиралтейскому р-ну	с.4515 н.567890 выд.15.12.2015 УФМС по г.СПб и ЛО по Адмиралтейскому р-ну	cb5d0166-d2b0-466e-a948-5c60b6d90522
a4781bc7-8491-4058-9b43-fbb300e1c745	d4c7f619-e8a9-470d-acc0-d1c976cbbf11	138e4cc4-46b7-4036-ad46-bea30038a441	4516	4516123	2016-07-15	2016-07-15	4516123456,ОУФМС по ЗАО г.Москвы,2016-07-15	4516123456,ОУФМС по ЗАО г.Москвы,2016-07-15	cb5d0166-d2b0-466e-a948-5c60b6d90522
26d209ba-54fc-4600-af65-19ffed45424e	9fb760a6-3618-4999-8537-bce4c127800e	c72a246b-3cdb-4f2b-97ba-321340ca08b9	УТ	445566	2019-05-15	15.05.2019	77УТ 445566 выд. 15.05.2019 ГИБДД УМВД России по г.Ростов-на-Дону кат. B,C	77УТ 445566 выд. 15.05.2019 ГИБДД УМВД России по г.Ростов-на-Дону кат. B,C	cb5d0166-d2b0-466e-a948-5c60b6d90522
197a0bc5-85b8-475f-bcc7-e34208ee2b31	7fb42bd1-ad5a-4582-ac10-9e5bcc2dd8e1	138e4cc4-46b7-4036-ad46-bea30038a441	4510	334455	\N	10 номер 3344	серия 4510 номер 334455 ОУФМС СВАО Москвы 20.03.2010	серия 4510 номер 334455 ОУФМС СВАО Москвы 20.03.2010	cb5d0166-d2b0-466e-a948-5c60b6d90522
f7575df7-f456-4230-872d-0b7df9e5d68a	d4c7f619-e8a9-470d-acc0-d1c976cbbf11	138e4cc4-46b7-4036-ad46-bea30038a441	4514	223344	2014-06-10	10.06.2014	45 14 223344 ФКУ ГИАЦ МВД России 10.06.2014	45 14 223344 ФКУ ГИАЦ МВД России 10.06.2014	cb5d0166-d2b0-466e-a948-5c60b6d90522
b00d1ccb-2ad2-49c9-a653-8548d9346529	50fc12d2-3450-4db8-aebe-c1a1a251254a	138e4cc4-46b7-4036-ad46-bea30038a441	4512	887766	2012-08-01	01.08.2012	4512 887766 УФМС ПО Г.КАЗАНИ 01.08.2012	4512 887766 УФМС ПО Г.КАЗАНИ 01.08.2012	cb5d0166-d2b0-466e-a948-5c60b6d90522
44ba011e-dcf5-4373-9d19-8eada267d2e3	97a57ff9-a693-4a11-9f75-726a3be36cac	c72a246b-3cdb-4f2b-97ba-321340ca08b9	ХА	123456	\N	77 ХА 1234	77 ХА 123456 2005-11-01 УГИБДД ГУВД г.Москвы A,B	77 ХА 123456 2005-11-01 УГИБДД ГУВД г.Москвы A,B	cb5d0166-d2b0-466e-a948-5c60b6d90522
c8696087-69fe-4708-9b53-ff8b739ff184	fad46874-5f76-47dd-bcd6-f40b9ee82cef	138e4cc4-46b7-4036-ad46-bea30038a441	4509	556677	2009-06-15	15.06.2009	4509 556677, ОУФМС по р-ну Коньково г.Москвы, 15.06.2009, к/п 770-091	4509 556677, ОУФМС по р-ну Коньково г.Москвы, 15.06.2009, к/п 770-091	cb5d0166-d2b0-466e-a948-5c60b6d90522
1ef0ecd2-48ac-466a-979f-0f8b4b8aa286	a4ff128d-9934-40f3-a356-e9a2127694b0	6af8052b-127f-45fa-a544-98a450ed7642	MD	1234567	2019-03-01	01.03.2019	MD серия MS номер 1234567 выдан 01.03.2019 истекает 01.03.2029 Кишинёв	MD серия MS номер 1234567 выдан 01.03.2019 истекает 01.03.2029 Кишинёв	cb5d0166-d2b0-466e-a948-5c60b6d90522
\.


--
-- Name: cust_addresses_addr_id_seq; Type: SEQUENCE SET; Schema: map; Owner: yui
--

SELECT pg_catalog.setval('map.cust_addresses_addr_id_seq', 20, true);


--
-- Name: cust_consents_consent_id_seq; Type: SEQUENCE SET; Schema: map; Owner: yui
--

SELECT pg_catalog.setval('map.cust_consents_consent_id_seq', 25, true);


--
-- Name: cust_docs_doc_id_seq; Type: SEQUENCE SET; Schema: map; Owner: yui
--

SELECT pg_catalog.setval('map.cust_docs_doc_id_seq', 15, true);


--
-- Name: cust_extra_extra_id_seq; Type: SEQUENCE SET; Schema: map; Owner: yui
--

SELECT pg_catalog.setval('map.cust_extra_extra_id_seq', 25, true);


--
-- Name: customers_cust_id_seq; Type: SEQUENCE SET; Schema: map; Owner: yui
--

SELECT pg_catalog.setval('map.customers_cust_id_seq', 25, true);


--
-- Name: cust_addresses cust_addresses_pkey; Type: CONSTRAINT; Schema: map; Owner: yui
--

ALTER TABLE ONLY map.cust_addresses
    ADD CONSTRAINT cust_addresses_pkey PRIMARY KEY (addr_id);


--
-- Name: cust_consents cust_consents_pkey; Type: CONSTRAINT; Schema: map; Owner: yui
--

ALTER TABLE ONLY map.cust_consents
    ADD CONSTRAINT cust_consents_pkey PRIMARY KEY (consent_id);


--
-- Name: cust_docs cust_docs_pkey; Type: CONSTRAINT; Schema: map; Owner: yui
--

ALTER TABLE ONLY map.cust_docs
    ADD CONSTRAINT cust_docs_pkey PRIMARY KEY (doc_id);


--
-- Name: cust_extra cust_extra_pkey; Type: CONSTRAINT; Schema: map; Owner: yui
--

ALTER TABLE ONLY map.cust_extra
    ADD CONSTRAINT cust_extra_pkey PRIMARY KEY (extra_id);


--
-- Name: customers customers_login_key; Type: CONSTRAINT; Schema: map; Owner: yui
--

ALTER TABLE ONLY map.customers
    ADD CONSTRAINT customers_login_key UNIQUE (login);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: map; Owner: yui
--

ALTER TABLE ONLY map.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (cust_id);


--
-- Name: migration_log migration_log_pkey; Type: CONSTRAINT; Schema: map; Owner: yui
--

ALTER TABLE ONLY map.migration_log
    ADD CONSTRAINT migration_log_pkey PRIMARY KEY (log_id);


--
-- Name: migration_person_link migration_person_link_pkey; Type: CONSTRAINT; Schema: map; Owner: yui
--

ALTER TABLE ONLY map.migration_person_link
    ADD CONSTRAINT migration_person_link_pkey PRIMARY KEY (link_id);


--
-- Name: migration_person_link migration_person_link_source_system_source_record_id_key; Type: CONSTRAINT; Schema: map; Owner: yui
--

ALTER TABLE ONLY map.migration_person_link
    ADD CONSTRAINT migration_person_link_source_system_source_record_id_key UNIQUE (source_system, source_record_id);


--
-- Name: migration_unmapped_attribute migration_unmapped_attribute_pkey; Type: CONSTRAINT; Schema: map; Owner: yui
--

ALTER TABLE ONLY map.migration_unmapped_attribute
    ADD CONSTRAINT migration_unmapped_attribute_pkey PRIMARY KEY (unmapped_attribute_id);


--
-- Name: dict_account_status dict_account_status_code_key; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.dict_account_status
    ADD CONSTRAINT dict_account_status_code_key UNIQUE (code);


--
-- Name: dict_account_status dict_account_status_pkey; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.dict_account_status
    ADD CONSTRAINT dict_account_status_pkey PRIMARY KEY (account_status_id);


--
-- Name: dict_address_type dict_address_type_code_key; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.dict_address_type
    ADD CONSTRAINT dict_address_type_code_key UNIQUE (code);


--
-- Name: dict_address_type dict_address_type_pkey; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.dict_address_type
    ADD CONSTRAINT dict_address_type_pkey PRIMARY KEY (address_type_id);


--
-- Name: dict_city dict_city_pkey; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.dict_city
    ADD CONSTRAINT dict_city_pkey PRIMARY KEY (city_id);


--
-- Name: dict_city dict_city_region_id_name_key; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.dict_city
    ADD CONSTRAINT dict_city_region_id_name_key UNIQUE (region_id, name);


--
-- Name: dict_consent_type dict_consent_type_code_key; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.dict_consent_type
    ADD CONSTRAINT dict_consent_type_code_key UNIQUE (code);


--
-- Name: dict_consent_type dict_consent_type_pkey; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.dict_consent_type
    ADD CONSTRAINT dict_consent_type_pkey PRIMARY KEY (consent_type_id);


--
-- Name: dict_contact_type dict_contact_type_code_key; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.dict_contact_type
    ADD CONSTRAINT dict_contact_type_code_key UNIQUE (code);


--
-- Name: dict_contact_type dict_contact_type_pkey; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.dict_contact_type
    ADD CONSTRAINT dict_contact_type_pkey PRIMARY KEY (contact_type_id);


--
-- Name: dict_country dict_country_iso_code_key; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.dict_country
    ADD CONSTRAINT dict_country_iso_code_key UNIQUE (iso_code);


--
-- Name: dict_country dict_country_name_key; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.dict_country
    ADD CONSTRAINT dict_country_name_key UNIQUE (name);


--
-- Name: dict_country dict_country_pkey; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.dict_country
    ADD CONSTRAINT dict_country_pkey PRIMARY KEY (country_id);


--
-- Name: dict_document_type dict_document_type_code_key; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.dict_document_type
    ADD CONSTRAINT dict_document_type_code_key UNIQUE (code);


--
-- Name: dict_document_type dict_document_type_pkey; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.dict_document_type
    ADD CONSTRAINT dict_document_type_pkey PRIMARY KEY (document_type_id);


--
-- Name: dict_gender dict_gender_code_key; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.dict_gender
    ADD CONSTRAINT dict_gender_code_key UNIQUE (code);


--
-- Name: dict_gender dict_gender_pkey; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.dict_gender
    ADD CONSTRAINT dict_gender_pkey PRIMARY KEY (gender_id);


--
-- Name: dict_identifier_type dict_identifier_type_code_key; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.dict_identifier_type
    ADD CONSTRAINT dict_identifier_type_code_key UNIQUE (code);


--
-- Name: dict_identifier_type dict_identifier_type_pkey; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.dict_identifier_type
    ADD CONSTRAINT dict_identifier_type_pkey PRIMARY KEY (identifier_type_id);


--
-- Name: dict_region dict_region_country_id_name_key; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.dict_region
    ADD CONSTRAINT dict_region_country_id_name_key UNIQUE (country_id, name);


--
-- Name: dict_region dict_region_pkey; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.dict_region
    ADD CONSTRAINT dict_region_pkey PRIMARY KEY (region_id);


--
-- Name: dict_street dict_street_city_id_name_key; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.dict_street
    ADD CONSTRAINT dict_street_city_id_name_key UNIQUE (city_id, name);


--
-- Name: dict_street dict_street_pkey; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.dict_street
    ADD CONSTRAINT dict_street_pkey PRIMARY KEY (street_id);


--
-- Name: dict_verification_status dict_verification_status_code_key; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.dict_verification_status
    ADD CONSTRAINT dict_verification_status_code_key UNIQUE (code);


--
-- Name: dict_verification_status dict_verification_status_pkey; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.dict_verification_status
    ADD CONSTRAINT dict_verification_status_pkey PRIMARY KEY (verification_status_id);


--
-- Name: person_identifier person_identifier_identifier_type_id_identifier_value_key; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.person_identifier
    ADD CONSTRAINT person_identifier_identifier_type_id_identifier_value_key UNIQUE (identifier_type_id, identifier_value);


--
-- Name: person_identifier person_identifier_pkey; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.person_identifier
    ADD CONSTRAINT person_identifier_pkey PRIMARY KEY (identifier_id);


--
-- Name: person_profile person_profile_last_name_first_name_middle_name_birth_date_key; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.person_profile
    ADD CONSTRAINT person_profile_last_name_first_name_middle_name_birth_date_key UNIQUE (last_name, first_name, middle_name, birth_date);


--
-- Name: person_profile person_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.person_profile
    ADD CONSTRAINT person_profile_pkey PRIMARY KEY (person_id);


--
-- Name: user_account user_account_login_key; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.user_account
    ADD CONSTRAINT user_account_login_key UNIQUE (login);


--
-- Name: user_account user_account_person_id_key; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.user_account
    ADD CONSTRAINT user_account_person_id_key UNIQUE (person_id);


--
-- Name: user_account user_account_pkey; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.user_account
    ADD CONSTRAINT user_account_pkey PRIMARY KEY (account_id);


--
-- Name: user_address user_address_pkey; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.user_address
    ADD CONSTRAINT user_address_pkey PRIMARY KEY (address_id);


--
-- Name: user_attribute_type user_attribute_type_code_key; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.user_attribute_type
    ADD CONSTRAINT user_attribute_type_code_key UNIQUE (code);


--
-- Name: user_attribute_type user_attribute_type_pkey; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.user_attribute_type
    ADD CONSTRAINT user_attribute_type_pkey PRIMARY KEY (attribute_type_id);


--
-- Name: user_attribute_value user_attribute_value_person_id_attribute_type_id_key; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.user_attribute_value
    ADD CONSTRAINT user_attribute_value_person_id_attribute_type_id_key UNIQUE (person_id, attribute_type_id);


--
-- Name: user_attribute_value user_attribute_value_pkey; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.user_attribute_value
    ADD CONSTRAINT user_attribute_value_pkey PRIMARY KEY (attribute_value_id);


--
-- Name: user_consent user_consent_person_id_consent_type_id_key; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.user_consent
    ADD CONSTRAINT user_consent_person_id_consent_type_id_key UNIQUE (person_id, consent_type_id);


--
-- Name: user_consent user_consent_pkey; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.user_consent
    ADD CONSTRAINT user_consent_pkey PRIMARY KEY (consent_id);


--
-- Name: user_contact user_contact_person_id_contact_type_id_contact_value_key; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.user_contact
    ADD CONSTRAINT user_contact_person_id_contact_type_id_contact_value_key UNIQUE (person_id, contact_type_id, contact_value);


--
-- Name: user_contact user_contact_pkey; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.user_contact
    ADD CONSTRAINT user_contact_pkey PRIMARY KEY (contact_id);


--
-- Name: user_verification_document user_verification_document_pkey; Type: CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.user_verification_document
    ADD CONSTRAINT user_verification_document_pkey PRIMARY KEY (document_id);


--
-- Name: person_profile_natural_uidx; Type: INDEX; Schema: public; Owner: yui
--

CREATE UNIQUE INDEX person_profile_natural_uidx ON public.person_profile USING btree (lower(last_name), lower(first_name), COALESCE(lower(middle_name), ''::text), birth_date) WHERE (birth_date IS NOT NULL);


--
-- Name: user_address_dedupe_uidx; Type: INDEX; Schema: public; Owner: yui
--

CREATE UNIQUE INDEX user_address_dedupe_uidx ON public.user_address USING btree (person_id, address_type_id, COALESCE(country_id, '00000000-0000-0000-0000-000000000000'::uuid), COALESCE(region_id, '00000000-0000-0000-0000-000000000000'::uuid), COALESCE(city_id, '00000000-0000-0000-0000-000000000000'::uuid), COALESCE(street_id, '00000000-0000-0000-0000-000000000000'::uuid), COALESCE(house, ''::text), COALESCE(building, ''::text), COALESCE(flat, ''::text), COALESCE(postal_code, ''::text), COALESCE(raw_address, ''::text));


--
-- Name: user_verification_document_dedupe_uidx; Type: INDEX; Schema: public; Owner: yui
--

CREATE UNIQUE INDEX user_verification_document_dedupe_uidx ON public.user_verification_document USING btree (person_id, document_type_id, COALESCE(series, ''::text), COALESCE(number, ''::text), COALESCE(raw_document_text, ''::text));


--
-- Name: cust_addresses cust_addresses_cust_id_fkey; Type: FK CONSTRAINT; Schema: map; Owner: yui
--

ALTER TABLE ONLY map.cust_addresses
    ADD CONSTRAINT cust_addresses_cust_id_fkey FOREIGN KEY (cust_id) REFERENCES map.customers(cust_id);


--
-- Name: cust_consents cust_consents_cust_id_fkey; Type: FK CONSTRAINT; Schema: map; Owner: yui
--

ALTER TABLE ONLY map.cust_consents
    ADD CONSTRAINT cust_consents_cust_id_fkey FOREIGN KEY (cust_id) REFERENCES map.customers(cust_id);


--
-- Name: cust_docs cust_docs_cust_id_fkey; Type: FK CONSTRAINT; Schema: map; Owner: yui
--

ALTER TABLE ONLY map.cust_docs
    ADD CONSTRAINT cust_docs_cust_id_fkey FOREIGN KEY (cust_id) REFERENCES map.customers(cust_id);


--
-- Name: cust_extra cust_extra_cust_id_fkey; Type: FK CONSTRAINT; Schema: map; Owner: yui
--

ALTER TABLE ONLY map.cust_extra
    ADD CONSTRAINT cust_extra_cust_id_fkey FOREIGN KEY (cust_id) REFERENCES map.customers(cust_id);


--
-- Name: migration_person_link migration_person_link_target_person_id_fkey; Type: FK CONSTRAINT; Schema: map; Owner: yui
--

ALTER TABLE ONLY map.migration_person_link
    ADD CONSTRAINT migration_person_link_target_person_id_fkey FOREIGN KEY (target_person_id) REFERENCES public.person_profile(person_id);


--
-- Name: migration_unmapped_attribute migration_unmapped_attribute_target_person_id_fkey; Type: FK CONSTRAINT; Schema: map; Owner: yui
--

ALTER TABLE ONLY map.migration_unmapped_attribute
    ADD CONSTRAINT migration_unmapped_attribute_target_person_id_fkey FOREIGN KEY (target_person_id) REFERENCES public.person_profile(person_id);


--
-- Name: dict_city dict_city_region_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.dict_city
    ADD CONSTRAINT dict_city_region_id_fkey FOREIGN KEY (region_id) REFERENCES public.dict_region(region_id);


--
-- Name: dict_region dict_region_country_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.dict_region
    ADD CONSTRAINT dict_region_country_id_fkey FOREIGN KEY (country_id) REFERENCES public.dict_country(country_id);


--
-- Name: dict_street dict_street_city_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.dict_street
    ADD CONSTRAINT dict_street_city_id_fkey FOREIGN KEY (city_id) REFERENCES public.dict_city(city_id);


--
-- Name: person_identifier person_identifier_identifier_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.person_identifier
    ADD CONSTRAINT person_identifier_identifier_type_id_fkey FOREIGN KEY (identifier_type_id) REFERENCES public.dict_identifier_type(identifier_type_id);


--
-- Name: person_identifier person_identifier_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.person_identifier
    ADD CONSTRAINT person_identifier_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person_profile(person_id) ON DELETE CASCADE;


--
-- Name: person_profile person_profile_gender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.person_profile
    ADD CONSTRAINT person_profile_gender_id_fkey FOREIGN KEY (gender_id) REFERENCES public.dict_gender(gender_id);


--
-- Name: user_account user_account_account_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.user_account
    ADD CONSTRAINT user_account_account_status_id_fkey FOREIGN KEY (account_status_id) REFERENCES public.dict_account_status(account_status_id);


--
-- Name: user_account user_account_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.user_account
    ADD CONSTRAINT user_account_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person_profile(person_id) ON DELETE CASCADE;


--
-- Name: user_address user_address_address_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.user_address
    ADD CONSTRAINT user_address_address_type_id_fkey FOREIGN KEY (address_type_id) REFERENCES public.dict_address_type(address_type_id);


--
-- Name: user_address user_address_city_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.user_address
    ADD CONSTRAINT user_address_city_id_fkey FOREIGN KEY (city_id) REFERENCES public.dict_city(city_id);


--
-- Name: user_address user_address_country_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.user_address
    ADD CONSTRAINT user_address_country_id_fkey FOREIGN KEY (country_id) REFERENCES public.dict_country(country_id);


--
-- Name: user_address user_address_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.user_address
    ADD CONSTRAINT user_address_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person_profile(person_id) ON DELETE CASCADE;


--
-- Name: user_address user_address_region_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.user_address
    ADD CONSTRAINT user_address_region_id_fkey FOREIGN KEY (region_id) REFERENCES public.dict_region(region_id);


--
-- Name: user_address user_address_street_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.user_address
    ADD CONSTRAINT user_address_street_id_fkey FOREIGN KEY (street_id) REFERENCES public.dict_street(street_id);


--
-- Name: user_attribute_value user_attribute_value_attribute_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.user_attribute_value
    ADD CONSTRAINT user_attribute_value_attribute_type_id_fkey FOREIGN KEY (attribute_type_id) REFERENCES public.user_attribute_type(attribute_type_id);


--
-- Name: user_attribute_value user_attribute_value_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.user_attribute_value
    ADD CONSTRAINT user_attribute_value_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person_profile(person_id) ON DELETE CASCADE;


--
-- Name: user_consent user_consent_consent_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.user_consent
    ADD CONSTRAINT user_consent_consent_type_id_fkey FOREIGN KEY (consent_type_id) REFERENCES public.dict_consent_type(consent_type_id);


--
-- Name: user_consent user_consent_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.user_consent
    ADD CONSTRAINT user_consent_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person_profile(person_id) ON DELETE CASCADE;


--
-- Name: user_contact user_contact_contact_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.user_contact
    ADD CONSTRAINT user_contact_contact_type_id_fkey FOREIGN KEY (contact_type_id) REFERENCES public.dict_contact_type(contact_type_id);


--
-- Name: user_contact user_contact_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.user_contact
    ADD CONSTRAINT user_contact_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person_profile(person_id) ON DELETE CASCADE;


--
-- Name: user_verification_document user_verification_document_document_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.user_verification_document
    ADD CONSTRAINT user_verification_document_document_type_id_fkey FOREIGN KEY (document_type_id) REFERENCES public.dict_document_type(document_type_id);


--
-- Name: user_verification_document user_verification_document_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.user_verification_document
    ADD CONSTRAINT user_verification_document_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person_profile(person_id) ON DELETE CASCADE;


--
-- Name: user_verification_document user_verification_document_verification_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: yui
--

ALTER TABLE ONLY public.user_verification_document
    ADD CONSTRAINT user_verification_document_verification_status_id_fkey FOREIGN KEY (verification_status_id) REFERENCES public.dict_verification_status(verification_status_id);


--
-- PostgreSQL database dump complete
--

\unrestrict yRAjiEEqBb7LDDcPTb2hBxD3ddt9cG6VlOQDPsgkMzmSva802HVRcgkzWNfW2vI

