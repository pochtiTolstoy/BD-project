--
-- PostgreSQL database dump
--

\restrict tsvBsatE254EclAJvf0DnmdBFqXrOpdPCNUoG2jskMnTui1d5lgCoSIh7bNbwJS

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

DROP DATABASE IF EXISTS migration_test_after_partner;
--
-- Name: migration_test_after_partner; Type: DATABASE; Schema: -; Owner: yui
--

CREATE DATABASE migration_test_after_partner WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'C.UTF-8';


ALTER DATABASE migration_test_after_partner OWNER TO yui;

\unrestrict tsvBsatE254EclAJvf0DnmdBFqXrOpdPCNUoG2jskMnTui1d5lgCoSIh7bNbwJS
\connect migration_test_after_partner
\restrict tsvBsatE254EclAJvf0DnmdBFqXrOpdPCNUoG2jskMnTui1d5lgCoSIh7bNbwJS

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
\.


--
-- Data for Name: migration_log; Type: TABLE DATA; Schema: map; Owner: yui
--

COPY map.migration_log (log_id, migration_run_id, source_system, source_record_id, target_person_id, status, stage, error_code, error_message, warning_messages, source_data, created_at) FROM stdin;
713a8dc0-88a3-463d-aadc-f567e5210e9b	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	1	06ac479a-edda-4596-9bb0-9deb06e869a8	success	load	\N	\N	\N	{"inn": "7743001234", "sex": "M", "email": "ivan.ivanov@gmail.com", "login": "ivan.ivanov88", "notes": null, "phone": "+79261234567", "snils": "112-233-445 95", "phone2": null, "status": "активен", "cust_id": 1, "marital": "женат", "birth_dt": "1988-03-15", "fullname": "Иванов Иван Сергеевич", "reg_date": "2021-05-10", "loyalty_lvl": "gold"}	2026-06-07 18:44:11.023358+03
6cb1b26b-eda1-4e8e-a01a-3ea193ee81b3	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	2	ea3eb759-6095-4565-98d0-0fd031f58fcb	success	load	\N	\N	\N	{"inn": "7701 00 223344", "sex": "Ж", "email": "ANNA.PETROVA@MAIL.RU, a.petrova@yandex.ru", "login": "anna.petrova", "notes": null, "phone": "8(916)555-11-22", "snils": null, "phone2": null, "status": "активен", "cust_id": 2, "marital": "не замужем", "birth_dt": "15.07.1992", "fullname": "ПЕТРОВА АННА МИХАЙЛОВНА", "reg_date": "2022-11-03", "loyalty_lvl": "Серебряный"}	2026-06-07 18:44:11.023358+03
fac4ee53-86f8-4b66-9b1b-44d1e6e96e5d	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	3	0ad7b981-2af7-472f-99f9-69ce294b9abd	warning	load	\N	\N	{"ФИО содержит инициалы или неполное имя: Козлов А.Е."}	{"inn": null, "sex": "муж", "email": "kozlov.ae@bk.ru", "login": "a.kozlov1990", "notes": null, "phone": "8 383 444 55 66", "snils": "32145678901", "phone2": null, "status": "активен", "cust_id": 3, "marital": "холост", "birth_dt": "5 января 1990 года", "fullname": "Козлов А.Е.", "reg_date": "2020-02-14", "loyalty_lvl": "bronze"}	2026-06-07 18:44:11.023358+03
5f4be7dc-bf7e-443c-b93c-9fda3579f45e	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	4	0ad7b981-2af7-472f-99f9-69ce294b9abd	success	load	\N	\N	\N	{"inn": "540100 998877", "sex": "МУЖСКОЙ", "email": "b.sidorov@inbox.ru", "login": "b.sidorov85", "notes": null, "phone": "89161112233", "snils": "321 456 789 01", "phone2": null, "status": "активен", "cust_id": 4, "marital": "Разведён", "birth_dt": "15-08-1985", "fullname": "Сидоров Борис Геннадьевич", "reg_date": "2023-04-01", "loyalty_lvl": "bronze"}	2026-06-07 18:44:11.023358+03
6d416aa3-2496-43c7-8f8e-89f4568e60da	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	5	19980952-8d8b-4cc1-9358-72a785bd48e2	success	load	\N	\N	\N	{"inn": null, "sex": "Женский", "email": "e.novikova@work.ru,novikova85@mail.ru ,ea_nov@yandex.ru", "login": "novikova_ea", "notes": null, "phone": "+7-495-600-11-22", "snils": "100-200-300 40", "phone2": null, "status": "активен", "cust_id": 5, "marital": "замужем", "birth_dt": "01.05.1985", "fullname": "новикова елена александровна", "reg_date": "2019-08-20", "loyalty_lvl": "platinum"}	2026-06-07 18:44:11.023358+03
9839b95d-b6f8-4c14-80cf-7c4648901dcb	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	6	fd592784-4d39-47d2-b247-a4a557add4d7	warning	load	\N	\N	{"ФИО содержит инициалы или неполное имя: Морозов Д.А."}	{"inn": "6612005544332", "sex": "1", "email": "morozov_da@gmail.com", "login": "morozov_da", "notes": "ИНН — уточнить", "phone": "8 926 777 88 99", "snils": "55566677700", "phone2": null, "status": "активен", "cust_id": 6, "marital": null, "birth_dt": "01.05.90", "fullname": "Морозов Д.А.", "reg_date": "2018-06-05", "loyalty_lvl": "silver"}	2026-06-07 18:44:11.023358+03
7d8fb5c7-4404-4248-900b-41e80af1efd0	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	7	fd592784-4d39-47d2-b247-a4a557add4d7	warning	load	\N	\N	{"Дата рождения не распознана: ноябрь 1979"}	{"inn": null, "sex": "М", "email": "lebedev.sergey@list.ru", "login": "s.lebedev79", "notes": "VIP до 2023", "phone": "+7 812 333 44 55", "snils": "55566677700", "phone2": null, "status": "заблокирован", "cust_id": 7, "marital": "женат", "birth_dt": "ноябрь 1979", "fullname": "Лебедев Сергей Николаевич", "reg_date": "2017-03-22", "loyalty_lvl": "gold"}	2026-06-07 18:44:11.023358+03
9816a303-2b84-47a9-ab8f-4dac2a0d8c63	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	8	6e107408-70b2-4de9-8205-f5af46476a63	warning	load	\N	\N	{"ФИО содержит инициалы или неполное имя: СОКОЛОВА Н.А."}	{"inn": "7 701 987 654", "sex": "ж", "email": "nat.sokolova@gmail.com", "login": "natalia.sokolova96", "notes": null, "phone": "8-926-123-45-67", "snils": "999 888 777 66", "phone2": null, "status": "активен", "cust_id": 8, "marital": "одинока", "birth_dt": "4 июля 1996", "fullname": "СОКОЛОВА Н.А.", "reg_date": "2024-02-29", "loyalty_lvl": "bronze"}	2026-06-07 18:44:11.023358+03
9bbbce2a-b5d4-4646-9b9d-35b5858e679b	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	9	314f1da4-b6ba-41a3-88f4-ffd61e8ba47f	warning	load	\N	\N	{"Адрес отсутствует или пустой"}	{"inn": null, "sex": "male", "email": "andreyM_2000@inbox.ru  andr.mikhaylov@corp.ru", "login": "a.mikhaylov", "notes": "дублирующийся аккаунт — проверить", "phone": null, "snils": null, "phone2": null, "status": "активен", "cust_id": 9, "marital": "не указано", "birth_dt": null, "fullname": "Михайлов Андрей", "reg_date": "2025-01-10", "loyalty_lvl": "bronze"}	2026-06-07 18:44:11.023358+03
034bc63d-81be-4536-af37-3570675b17dc	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	10	19980952-8d8b-4cc1-9358-72a785bd48e2	success	load	\N	\N	\N	{"inn": "6 164 001 122 33", "sex": "Ж", "email": "fedorova_y@yandex.ru", "login": "yuliya.fedorova85", "notes": null, "phone": "+7(863)222-33-44", "snils": "100.200.300-40", "phone2": null, "status": "активен", "cust_id": 10, "marital": "разведена", "birth_dt": "1985/03/15", "fullname": "Федорова Юлия Олеговна", "reg_date": "2020-09-01", "loyalty_lvl": "silver"}	2026-06-07 18:44:11.023358+03
c0e7bbf7-ce11-4a53-8a06-738a71e58c3c	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	11	b1c3dde5-9ccc-4b5f-891c-57ebeece11c8	success	load	\N	\N	\N	{"inn": "7 743 000 132", "sex": "М", "email": "v.popov@corp.ru", "login": "viktor.popov72", "notes": null, "phone": "+7 495 111 22 33", "snils": "77700011200", "phone2": null, "status": "активен", "cust_id": 11, "marital": "женат", "birth_dt": "03.11.1972", "fullname": "Попов Виктор Геннадьевич", "reg_date": "2016-12-01", "loyalty_lvl": "gold"}	2026-06-07 18:44:11.023358+03
6794be56-650f-4416-a62e-61cfb88f27e4	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	12	6e107408-70b2-4de9-8205-f5af46476a63	success	load	\N	\N	\N	{"inn": "7701987654", "sex": "F", "email": "anna.k@gmail.com", "login": "anna.kuznetsova93", "notes": null, "phone": "+7(495) 123-45-67", "snils": "445-566-778 99", "phone2": "8-926-888-99-00", "status": "активен", "cust_id": 12, "marital": "замужем", "birth_dt": "25 декабря 1993 года", "fullname": "Кузнецова Анна Максимовна", "reg_date": "2021-07-07", "loyalty_lvl": "platinum"}	2026-06-07 18:44:11.023358+03
7cd359e8-112c-4e6e-8f58-eeb8a59f1a0d	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	13	162f794a-bac5-490a-acf5-160eb22fa716	success	load	\N	\N	\N	{"inn": "5040-001-234-56", "sex": "М", "email": "roman.zaitsev@rambler.ru", "login": "roman.zaitsev91", "notes": null, "phone": "89031234567", "snils": "98765432100", "phone2": null, "status": "активен", "cust_id": 13, "marital": "Холост", "birth_dt": "07-04-1991", "fullname": "ЗАЙЦЕВ РОМАН ЕВГЕНЬЕВИЧ", "reg_date": "2022-07-15", "loyalty_lvl": "silver"}	2026-06-07 18:44:11.023358+03
d85bbb90-c311-4d8e-9f65-0282208f1477	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	14	cffa55ae-4de8-4c9a-b8be-9a55292fe7b1	warning	load	\N	\N	{"ФИО содержит инициалы или неполное имя: Белова К."}	{"inn": "5030101234", "sex": "female", "email": "belova_ks@mail.ru, belova.kseniya@gmail.com", "login": "belova_ks98", "notes": null, "phone": "926-111-22-33", "snils": null, "phone2": null, "status": "активен", "cust_id": 14, "marital": "не замужем", "birth_dt": "1998/06/22", "fullname": "Белова К.", "reg_date": "2023-09-10", "loyalty_lvl": "bronze"}	2026-06-07 18:44:11.023358+03
922e3f03-ea8d-44fb-b077-7382f538a300	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	15	995c7b75-4104-41cc-8946-fe53c81de20c	success	load	\N	\N	\N	{"inn": "7700000000", "sex": "0", "email": "k.tarasov@yandex.ru", "login": "k.tarasov70", "notes": null, "phone": "8(383)999-88-77", "snils": "123 456 789 00", "phone2": null, "status": "активен", "cust_id": 15, "marital": "вдовец", "birth_dt": "25/12/1970", "fullname": "Тарасов Константин Игоревич", "reg_date": "2021-01-11", "loyalty_lvl": "silver"}	2026-06-07 18:44:11.023358+03
103d68c4-b5d6-43e5-b66a-8ad0c263b097	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	16	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	success	load	\N	\N	\N	{"inn": "5050 1234 56", "sex": "Мужчина", "email": "artem.gromov@gmail.com;a.gromov@work.ru", "login": "artem.gromov93", "notes": null, "phone": "+79151234567", "snils": "88899900011", "phone2": null, "status": "активен", "cust_id": 16, "marital": "не женат", "birth_dt": "12.09.1993", "fullname": "ГРОМОВ АРТЁМ ВИКТОРОВИЧ", "reg_date": "2023-03-05", "loyalty_lvl": "bronze"}	2026-06-07 18:44:11.023358+03
4efcfc74-1628-4d12-98ec-493eb208021a	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	17	9ea569e8-ea5b-40c1-99ca-ea03c68bbe4d	success	load	\N	\N	\N	{"inn": null, "sex": "female", "email": "frolova_n@bk.ru", "login": "natasha.frolova91", "notes": null, "phone": "+7 917 777 66 55", "snils": "321-654-987 00", "phone2": null, "status": "активен", "cust_id": 17, "marital": "одинокая", "birth_dt": "March 5, 1991", "fullname": "Фролова Наталья", "reg_date": "2022-04-20", "loyalty_lvl": null}	2026-06-07 18:44:11.023358+03
cdfbc856-046d-4d1f-90e7-9f020640fe32	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	18	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	warning	load	\N	\N	{"Адрес отсутствует или пустой"}	{"inn": "7714 998877", "sex": "м", "email": "o.zakharov@inbox.ru", "login": "o.zakharov83", "notes": null, "phone": "8 (925) 456 78 90", "snils": "88899900011", "phone2": null, "status": "активен", "cust_id": 18, "marital": "Женат", "birth_dt": "12-09-1983", "fullname": "Захаров Олег Михайлович", "reg_date": "2020-11-30", "loyalty_lvl": "bronze"}	2026-06-07 18:44:11.023358+03
b168ec12-1d01-4eb6-886d-846073af13e6	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	19	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	warning	load	\N	\N	{"Подозрительный контакт: marinakrylova.mail.ru","Адрес отсутствует или пустой"}	{"inn": "7714998877", "sex": "Ж", "email": "marinakrylova.mail.ru", "login": "marina.krylova79", "notes": "email уточнить", "phone": "+79123456789", "snils": "001 002 003 04", "phone2": null, "status": "активен", "cust_id": 19, "marital": "замужем", "birth_dt": "1979-11-30", "fullname": "Крылова Марина Вячеславовна", "reg_date": "2019-05-15", "loyalty_lvl": "silver"}	2026-06-07 18:44:11.023358+03
a365facd-3870-45cc-a1a7-b68c1c82c3c3	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	20	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	success	load	\N	\N	\N	{"inn": null, "sex": "M", "email": "v.bogdanov@gmail.com", "login": "v.bogdanov67", "notes": null, "phone": "8 800 333 44 55", "snils": "001 002 003 04", "phone2": null, "status": "активен", "cust_id": 20, "marital": "женат", "birth_dt": "15 августа 1967 года", "fullname": "Богданов Виктор Анатольевич", "reg_date": "2016-06-01", "loyalty_lvl": "gold"}	2026-06-07 18:44:11.023358+03
bb000190-882a-4863-9332-9099a5a4f15a	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	21	b4eaf12e-13a9-488c-81a9-460e39524950	success	load	\N	\N	\N	{"inn": "770100445566", "sex": "Ж", "email": "alina.simonova@yandex.ru", "login": "alina.simonova94", "notes": null, "phone": "+79269998877", "snils": null, "phone2": null, "status": "активен", "cust_id": 21, "marital": "незамужем", "birth_dt": "30.06.1994", "fullname": "Симонова Алина Дмитриевна", "reg_date": "2023-08-12", "loyalty_lvl": "silver"}	2026-06-07 18:44:11.023358+03
03b8aa4d-0a5b-473d-a4ec-cfe6d13b4bf1	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	22	b4eaf12e-13a9-488c-81a9-460e39524950	warning	load	\N	\N	{"Адрес отсутствует или пустой"}	{"inn": "770100445566", "sex": "М", "email": "kirill_v@hotmail.com", "login": "kirill.v88", "notes": null, "phone": null, "snils": "123-456-789 00", "phone2": null, "status": "активен", "cust_id": 22, "marital": "холостой", "birth_dt": "1988/11/11", "fullname": "Вешняков Кирилл Павлович", "reg_date": "2024-05-03", "loyalty_lvl": "bronze"}	2026-06-07 18:44:11.023358+03
56d7af0b-8416-4965-8b33-01623c17d63b	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	23	65e1d23b-dfa8-44a3-bb40-15bee23ade75	warning	load	\N	\N	{"Дата рождения не распознана: н/д","Адрес отсутствует или пустой"}	{"inn": null, "sex": "Ж", "email": "d.gorbunova@gmail.com", "login": "diana.gorbunova", "notes": "дата рождения неизвестна", "phone": "+74951234567", "snils": null, "phone2": null, "status": "активен", "cust_id": 23, "marital": "Замужем", "birth_dt": "н/д", "fullname": "Горбунова Диана Сергеевна", "reg_date": "2025-03-15", "loyalty_lvl": "bronze"}	2026-06-07 18:44:11.023358+03
d30cdb8c-c75c-4f81-b0f2-403a39c79ae9	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	24	3fde298b-7536-4b09-a828-87223b009b1c	warning	load	\N	\N	{"Адрес отсутствует или пустой"}	{"inn": null, "sex": "М", "email": "ion.popescu@mail.ru", "login": "ion.popescu87", "notes": "гражданин Молдовы, ИНН отсутствует", "phone": "+37369123456", "snils": null, "phone2": null, "status": "активен", "cust_id": 24, "marital": "женат", "birth_dt": "15.03.1987", "fullname": "Попеску Ион Александрович", "reg_date": "2022-10-10", "loyalty_lvl": "silver"}	2026-06-07 18:44:11.023358+03
506865ab-d86d-4bec-b6d6-c1a18d7a42b4	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	25	b4eaf12e-13a9-488c-81a9-460e39524950	warning	load	\N	\N	{"Адрес отсутствует или пустой"}	{"inn": "7701-00-445566", "sex": "муж.", "email": "ilya.chernov@gmail.com", "login": "ilya.chernov91", "notes": null, "phone": "8 901 234 56 78", "snils": "321-654-987 00", "phone2": null, "status": "активен", "cust_id": 25, "marital": "не женат", "birth_dt": "5 января 1991", "fullname": "Чернов Илья Павлович", "reg_date": "2023-11-20", "loyalty_lvl": "bronze"}	2026-06-07 18:44:11.023358+03
b6428363-f4f0-424e-a1ad-37e715865ed8	628acff9-25fb-45a8-b4db-24fe075aebdd	partner_bd2	1	06ac479a-edda-4596-9bb0-9deb06e869a8	skipped	deduplicate	\N	\N	\N	{"inn": "7743001234", "sex": "M", "email": "ivan.ivanov@gmail.com", "login": "ivan.ivanov88", "notes": null, "phone": "+79261234567", "snils": "112-233-445 95", "phone2": null, "status": "активен", "cust_id": 1, "marital": "женат", "birth_dt": "1988-03-15", "fullname": "Иванов Иван Сергеевич", "reg_date": "2021-05-10", "loyalty_lvl": "gold"}	2026-06-07 18:44:11.131351+03
50ff69b3-bc78-4abc-80cb-de92733d85a8	628acff9-25fb-45a8-b4db-24fe075aebdd	partner_bd2	2	ea3eb759-6095-4565-98d0-0fd031f58fcb	skipped	deduplicate	\N	\N	\N	{"inn": "7701 00 223344", "sex": "Ж", "email": "ANNA.PETROVA@MAIL.RU, a.petrova@yandex.ru", "login": "anna.petrova", "notes": null, "phone": "8(916)555-11-22", "snils": null, "phone2": null, "status": "активен", "cust_id": 2, "marital": "не замужем", "birth_dt": "15.07.1992", "fullname": "ПЕТРОВА АННА МИХАЙЛОВНА", "reg_date": "2022-11-03", "loyalty_lvl": "Серебряный"}	2026-06-07 18:44:11.131351+03
ddc278e5-b804-41d7-97d6-022d1c69ecd1	628acff9-25fb-45a8-b4db-24fe075aebdd	partner_bd2	3	0ad7b981-2af7-472f-99f9-69ce294b9abd	skipped	deduplicate	\N	\N	\N	{"inn": null, "sex": "муж", "email": "kozlov.ae@bk.ru", "login": "a.kozlov1990", "notes": null, "phone": "8 383 444 55 66", "snils": "32145678901", "phone2": null, "status": "активен", "cust_id": 3, "marital": "холост", "birth_dt": "5 января 1990 года", "fullname": "Козлов А.Е.", "reg_date": "2020-02-14", "loyalty_lvl": "bronze"}	2026-06-07 18:44:11.131351+03
3dc7ceab-67ef-4a8b-b64b-27bf010cc744	628acff9-25fb-45a8-b4db-24fe075aebdd	partner_bd2	4	0ad7b981-2af7-472f-99f9-69ce294b9abd	skipped	deduplicate	\N	\N	\N	{"inn": "540100 998877", "sex": "МУЖСКОЙ", "email": "b.sidorov@inbox.ru", "login": "b.sidorov85", "notes": null, "phone": "89161112233", "snils": "321 456 789 01", "phone2": null, "status": "активен", "cust_id": 4, "marital": "Разведён", "birth_dt": "15-08-1985", "fullname": "Сидоров Борис Геннадьевич", "reg_date": "2023-04-01", "loyalty_lvl": "bronze"}	2026-06-07 18:44:11.131351+03
a072dd98-6ee1-42c9-a2b3-96ba538418e4	628acff9-25fb-45a8-b4db-24fe075aebdd	partner_bd2	5	19980952-8d8b-4cc1-9358-72a785bd48e2	skipped	deduplicate	\N	\N	\N	{"inn": null, "sex": "Женский", "email": "e.novikova@work.ru,novikova85@mail.ru ,ea_nov@yandex.ru", "login": "novikova_ea", "notes": null, "phone": "+7-495-600-11-22", "snils": "100-200-300 40", "phone2": null, "status": "активен", "cust_id": 5, "marital": "замужем", "birth_dt": "01.05.1985", "fullname": "новикова елена александровна", "reg_date": "2019-08-20", "loyalty_lvl": "platinum"}	2026-06-07 18:44:11.131351+03
fe01972d-9252-4162-accc-933d811ce54e	628acff9-25fb-45a8-b4db-24fe075aebdd	partner_bd2	6	fd592784-4d39-47d2-b247-a4a557add4d7	skipped	deduplicate	\N	\N	\N	{"inn": "6612005544332", "sex": "1", "email": "morozov_da@gmail.com", "login": "morozov_da", "notes": "ИНН — уточнить", "phone": "8 926 777 88 99", "snils": "55566677700", "phone2": null, "status": "активен", "cust_id": 6, "marital": null, "birth_dt": "01.05.90", "fullname": "Морозов Д.А.", "reg_date": "2018-06-05", "loyalty_lvl": "silver"}	2026-06-07 18:44:11.131351+03
53ed0f22-3c83-45f8-88cf-cc798562b03e	628acff9-25fb-45a8-b4db-24fe075aebdd	partner_bd2	7	fd592784-4d39-47d2-b247-a4a557add4d7	skipped	deduplicate	\N	\N	\N	{"inn": null, "sex": "М", "email": "lebedev.sergey@list.ru", "login": "s.lebedev79", "notes": "VIP до 2023", "phone": "+7 812 333 44 55", "snils": "55566677700", "phone2": null, "status": "заблокирован", "cust_id": 7, "marital": "женат", "birth_dt": "ноябрь 1979", "fullname": "Лебедев Сергей Николаевич", "reg_date": "2017-03-22", "loyalty_lvl": "gold"}	2026-06-07 18:44:11.131351+03
35fc813c-3a53-49c8-be22-64941fbcc784	628acff9-25fb-45a8-b4db-24fe075aebdd	partner_bd2	8	6e107408-70b2-4de9-8205-f5af46476a63	skipped	deduplicate	\N	\N	\N	{"inn": "7 701 987 654", "sex": "ж", "email": "nat.sokolova@gmail.com", "login": "natalia.sokolova96", "notes": null, "phone": "8-926-123-45-67", "snils": "999 888 777 66", "phone2": null, "status": "активен", "cust_id": 8, "marital": "одинока", "birth_dt": "4 июля 1996", "fullname": "СОКОЛОВА Н.А.", "reg_date": "2024-02-29", "loyalty_lvl": "bronze"}	2026-06-07 18:44:11.131351+03
bf7a448e-1a61-4089-8d6b-5d0482fab249	628acff9-25fb-45a8-b4db-24fe075aebdd	partner_bd2	9	314f1da4-b6ba-41a3-88f4-ffd61e8ba47f	skipped	deduplicate	\N	\N	\N	{"inn": null, "sex": "male", "email": "andreyM_2000@inbox.ru  andr.mikhaylov@corp.ru", "login": "a.mikhaylov", "notes": "дублирующийся аккаунт — проверить", "phone": null, "snils": null, "phone2": null, "status": "активен", "cust_id": 9, "marital": "не указано", "birth_dt": null, "fullname": "Михайлов Андрей", "reg_date": "2025-01-10", "loyalty_lvl": "bronze"}	2026-06-07 18:44:11.131351+03
e689ebf3-0755-48fa-8cfa-8acdd5e51abe	628acff9-25fb-45a8-b4db-24fe075aebdd	partner_bd2	10	19980952-8d8b-4cc1-9358-72a785bd48e2	skipped	deduplicate	\N	\N	\N	{"inn": "6 164 001 122 33", "sex": "Ж", "email": "fedorova_y@yandex.ru", "login": "yuliya.fedorova85", "notes": null, "phone": "+7(863)222-33-44", "snils": "100.200.300-40", "phone2": null, "status": "активен", "cust_id": 10, "marital": "разведена", "birth_dt": "1985/03/15", "fullname": "Федорова Юлия Олеговна", "reg_date": "2020-09-01", "loyalty_lvl": "silver"}	2026-06-07 18:44:11.131351+03
2de873b3-f9d5-43a2-b123-d177ee1554af	628acff9-25fb-45a8-b4db-24fe075aebdd	partner_bd2	11	b1c3dde5-9ccc-4b5f-891c-57ebeece11c8	skipped	deduplicate	\N	\N	\N	{"inn": "7 743 000 132", "sex": "М", "email": "v.popov@corp.ru", "login": "viktor.popov72", "notes": null, "phone": "+7 495 111 22 33", "snils": "77700011200", "phone2": null, "status": "активен", "cust_id": 11, "marital": "женат", "birth_dt": "03.11.1972", "fullname": "Попов Виктор Геннадьевич", "reg_date": "2016-12-01", "loyalty_lvl": "gold"}	2026-06-07 18:44:11.131351+03
74965ede-1452-47f6-bf6f-a833aa7c4816	628acff9-25fb-45a8-b4db-24fe075aebdd	partner_bd2	12	6e107408-70b2-4de9-8205-f5af46476a63	skipped	deduplicate	\N	\N	\N	{"inn": "7701987654", "sex": "F", "email": "anna.k@gmail.com", "login": "anna.kuznetsova93", "notes": null, "phone": "+7(495) 123-45-67", "snils": "445-566-778 99", "phone2": "8-926-888-99-00", "status": "активен", "cust_id": 12, "marital": "замужем", "birth_dt": "25 декабря 1993 года", "fullname": "Кузнецова Анна Максимовна", "reg_date": "2021-07-07", "loyalty_lvl": "platinum"}	2026-06-07 18:44:11.131351+03
809d915a-6c48-4cf7-8a5a-a48f0496633d	628acff9-25fb-45a8-b4db-24fe075aebdd	partner_bd2	13	162f794a-bac5-490a-acf5-160eb22fa716	skipped	deduplicate	\N	\N	\N	{"inn": "5040-001-234-56", "sex": "М", "email": "roman.zaitsev@rambler.ru", "login": "roman.zaitsev91", "notes": null, "phone": "89031234567", "snils": "98765432100", "phone2": null, "status": "активен", "cust_id": 13, "marital": "Холост", "birth_dt": "07-04-1991", "fullname": "ЗАЙЦЕВ РОМАН ЕВГЕНЬЕВИЧ", "reg_date": "2022-07-15", "loyalty_lvl": "silver"}	2026-06-07 18:44:11.131351+03
e53885c6-5a66-453f-879f-54ebebf891c4	628acff9-25fb-45a8-b4db-24fe075aebdd	partner_bd2	14	cffa55ae-4de8-4c9a-b8be-9a55292fe7b1	skipped	deduplicate	\N	\N	\N	{"inn": "5030101234", "sex": "female", "email": "belova_ks@mail.ru, belova.kseniya@gmail.com", "login": "belova_ks98", "notes": null, "phone": "926-111-22-33", "snils": null, "phone2": null, "status": "активен", "cust_id": 14, "marital": "не замужем", "birth_dt": "1998/06/22", "fullname": "Белова К.", "reg_date": "2023-09-10", "loyalty_lvl": "bronze"}	2026-06-07 18:44:11.131351+03
c933d5be-6126-4a41-a423-f3b3d905e66b	628acff9-25fb-45a8-b4db-24fe075aebdd	partner_bd2	15	995c7b75-4104-41cc-8946-fe53c81de20c	skipped	deduplicate	\N	\N	\N	{"inn": "7700000000", "sex": "0", "email": "k.tarasov@yandex.ru", "login": "k.tarasov70", "notes": null, "phone": "8(383)999-88-77", "snils": "123 456 789 00", "phone2": null, "status": "активен", "cust_id": 15, "marital": "вдовец", "birth_dt": "25/12/1970", "fullname": "Тарасов Константин Игоревич", "reg_date": "2021-01-11", "loyalty_lvl": "silver"}	2026-06-07 18:44:11.131351+03
334ed286-e502-472e-9737-68c1b78ad827	628acff9-25fb-45a8-b4db-24fe075aebdd	partner_bd2	16	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	skipped	deduplicate	\N	\N	\N	{"inn": "5050 1234 56", "sex": "Мужчина", "email": "artem.gromov@gmail.com;a.gromov@work.ru", "login": "artem.gromov93", "notes": null, "phone": "+79151234567", "snils": "88899900011", "phone2": null, "status": "активен", "cust_id": 16, "marital": "не женат", "birth_dt": "12.09.1993", "fullname": "ГРОМОВ АРТЁМ ВИКТОРОВИЧ", "reg_date": "2023-03-05", "loyalty_lvl": "bronze"}	2026-06-07 18:44:11.131351+03
26a12fa5-3208-47ea-86f5-92dc323efd2b	628acff9-25fb-45a8-b4db-24fe075aebdd	partner_bd2	17	9ea569e8-ea5b-40c1-99ca-ea03c68bbe4d	skipped	deduplicate	\N	\N	\N	{"inn": null, "sex": "female", "email": "frolova_n@bk.ru", "login": "natasha.frolova91", "notes": null, "phone": "+7 917 777 66 55", "snils": "321-654-987 00", "phone2": null, "status": "активен", "cust_id": 17, "marital": "одинокая", "birth_dt": "March 5, 1991", "fullname": "Фролова Наталья", "reg_date": "2022-04-20", "loyalty_lvl": null}	2026-06-07 18:44:11.131351+03
fc2eb0eb-329e-4d85-916e-0337bcdb4ebe	628acff9-25fb-45a8-b4db-24fe075aebdd	partner_bd2	18	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	skipped	deduplicate	\N	\N	\N	{"inn": "7714 998877", "sex": "м", "email": "o.zakharov@inbox.ru", "login": "o.zakharov83", "notes": null, "phone": "8 (925) 456 78 90", "snils": "88899900011", "phone2": null, "status": "активен", "cust_id": 18, "marital": "Женат", "birth_dt": "12-09-1983", "fullname": "Захаров Олег Михайлович", "reg_date": "2020-11-30", "loyalty_lvl": "bronze"}	2026-06-07 18:44:11.131351+03
8973ba21-88b3-4a3f-b8d5-583d4696838d	628acff9-25fb-45a8-b4db-24fe075aebdd	partner_bd2	19	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	skipped	deduplicate	\N	\N	\N	{"inn": "7714998877", "sex": "Ж", "email": "marinakrylova.mail.ru", "login": "marina.krylova79", "notes": "email уточнить", "phone": "+79123456789", "snils": "001 002 003 04", "phone2": null, "status": "активен", "cust_id": 19, "marital": "замужем", "birth_dt": "1979-11-30", "fullname": "Крылова Марина Вячеславовна", "reg_date": "2019-05-15", "loyalty_lvl": "silver"}	2026-06-07 18:44:11.131351+03
30eab98d-ef55-409b-a7fd-1ea41847e3b0	628acff9-25fb-45a8-b4db-24fe075aebdd	partner_bd2	20	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	skipped	deduplicate	\N	\N	\N	{"inn": null, "sex": "M", "email": "v.bogdanov@gmail.com", "login": "v.bogdanov67", "notes": null, "phone": "8 800 333 44 55", "snils": "001 002 003 04", "phone2": null, "status": "активен", "cust_id": 20, "marital": "женат", "birth_dt": "15 августа 1967 года", "fullname": "Богданов Виктор Анатольевич", "reg_date": "2016-06-01", "loyalty_lvl": "gold"}	2026-06-07 18:44:11.131351+03
effad67c-8ae2-479c-bbf9-97848552dcd7	628acff9-25fb-45a8-b4db-24fe075aebdd	partner_bd2	21	b4eaf12e-13a9-488c-81a9-460e39524950	skipped	deduplicate	\N	\N	\N	{"inn": "770100445566", "sex": "Ж", "email": "alina.simonova@yandex.ru", "login": "alina.simonova94", "notes": null, "phone": "+79269998877", "snils": null, "phone2": null, "status": "активен", "cust_id": 21, "marital": "незамужем", "birth_dt": "30.06.1994", "fullname": "Симонова Алина Дмитриевна", "reg_date": "2023-08-12", "loyalty_lvl": "silver"}	2026-06-07 18:44:11.131351+03
6996c58f-b65f-4c11-9ca3-170b4288af9c	628acff9-25fb-45a8-b4db-24fe075aebdd	partner_bd2	22	b4eaf12e-13a9-488c-81a9-460e39524950	skipped	deduplicate	\N	\N	\N	{"inn": "770100445566", "sex": "М", "email": "kirill_v@hotmail.com", "login": "kirill.v88", "notes": null, "phone": null, "snils": "123-456-789 00", "phone2": null, "status": "активен", "cust_id": 22, "marital": "холостой", "birth_dt": "1988/11/11", "fullname": "Вешняков Кирилл Павлович", "reg_date": "2024-05-03", "loyalty_lvl": "bronze"}	2026-06-07 18:44:11.131351+03
17b2a2aa-b111-42b9-8af7-2ed6b84c9b12	628acff9-25fb-45a8-b4db-24fe075aebdd	partner_bd2	23	65e1d23b-dfa8-44a3-bb40-15bee23ade75	skipped	deduplicate	\N	\N	\N	{"inn": null, "sex": "Ж", "email": "d.gorbunova@gmail.com", "login": "diana.gorbunova", "notes": "дата рождения неизвестна", "phone": "+74951234567", "snils": null, "phone2": null, "status": "активен", "cust_id": 23, "marital": "Замужем", "birth_dt": "н/д", "fullname": "Горбунова Диана Сергеевна", "reg_date": "2025-03-15", "loyalty_lvl": "bronze"}	2026-06-07 18:44:11.131351+03
1967c19a-6b3a-4c39-b1d4-6a5a14d1a674	628acff9-25fb-45a8-b4db-24fe075aebdd	partner_bd2	24	3fde298b-7536-4b09-a828-87223b009b1c	skipped	deduplicate	\N	\N	\N	{"inn": null, "sex": "М", "email": "ion.popescu@mail.ru", "login": "ion.popescu87", "notes": "гражданин Молдовы, ИНН отсутствует", "phone": "+37369123456", "snils": null, "phone2": null, "status": "активен", "cust_id": 24, "marital": "женат", "birth_dt": "15.03.1987", "fullname": "Попеску Ион Александрович", "reg_date": "2022-10-10", "loyalty_lvl": "silver"}	2026-06-07 18:44:11.131351+03
75dfc7aa-fb1a-483a-9d0c-b0949088bc0f	628acff9-25fb-45a8-b4db-24fe075aebdd	partner_bd2	25	b4eaf12e-13a9-488c-81a9-460e39524950	skipped	deduplicate	\N	\N	\N	{"inn": "7701-00-445566", "sex": "муж.", "email": "ilya.chernov@gmail.com", "login": "ilya.chernov91", "notes": null, "phone": "8 901 234 56 78", "snils": "321-654-987 00", "phone2": null, "status": "активен", "cust_id": 25, "marital": "не женат", "birth_dt": "5 января 1991", "fullname": "Чернов Илья Павлович", "reg_date": "2023-11-20", "loyalty_lvl": "bronze"}	2026-06-07 18:44:11.131351+03
\.


--
-- Data for Name: migration_person_link; Type: TABLE DATA; Schema: map; Owner: yui
--

COPY map.migration_person_link (link_id, migration_run_id, source_system, source_record_id, target_person_id, created_at) FROM stdin;
d1902aa4-3b9a-45b8-9e60-bb4088d0b0f5	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	1	06ac479a-edda-4596-9bb0-9deb06e869a8	2026-06-07 18:44:11.023358+03
57c1aaaf-9e93-4814-97c8-451e0fa75bd2	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	2	ea3eb759-6095-4565-98d0-0fd031f58fcb	2026-06-07 18:44:11.023358+03
c763b4eb-68e5-4590-a329-6b2da47c14d4	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	3	0ad7b981-2af7-472f-99f9-69ce294b9abd	2026-06-07 18:44:11.023358+03
2d32e99e-1272-40a5-b1e1-f005435e96a5	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	4	0ad7b981-2af7-472f-99f9-69ce294b9abd	2026-06-07 18:44:11.023358+03
2052071c-1cd0-4aaa-ac0d-4a73c613b686	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	5	19980952-8d8b-4cc1-9358-72a785bd48e2	2026-06-07 18:44:11.023358+03
a92f60d7-fad2-46d1-b27d-1c75b7d6cc76	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	6	fd592784-4d39-47d2-b247-a4a557add4d7	2026-06-07 18:44:11.023358+03
d2f48bb3-2aea-43b9-8338-ebb1d73becae	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	7	fd592784-4d39-47d2-b247-a4a557add4d7	2026-06-07 18:44:11.023358+03
410fc920-7934-4ed4-b305-5d4e3d7cd619	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	8	6e107408-70b2-4de9-8205-f5af46476a63	2026-06-07 18:44:11.023358+03
550752d1-40bd-4fb4-a033-5cf16feb3f9b	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	9	314f1da4-b6ba-41a3-88f4-ffd61e8ba47f	2026-06-07 18:44:11.023358+03
93cf0827-477a-4b66-b32e-cf2f8a8e7e72	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	10	19980952-8d8b-4cc1-9358-72a785bd48e2	2026-06-07 18:44:11.023358+03
5ec7fa55-2e98-4e35-90a8-117e75060f62	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	11	b1c3dde5-9ccc-4b5f-891c-57ebeece11c8	2026-06-07 18:44:11.023358+03
dc0f3996-c43a-4272-b852-9bb218fd1e5a	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	12	6e107408-70b2-4de9-8205-f5af46476a63	2026-06-07 18:44:11.023358+03
d2bac686-cf44-4401-b0ec-5fb789ddcd1e	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	13	162f794a-bac5-490a-acf5-160eb22fa716	2026-06-07 18:44:11.023358+03
b65f60e6-76d4-46f7-a360-daea82e4e4cf	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	14	cffa55ae-4de8-4c9a-b8be-9a55292fe7b1	2026-06-07 18:44:11.023358+03
dffcd12d-b60b-4840-9467-d78727d7db41	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	15	995c7b75-4104-41cc-8946-fe53c81de20c	2026-06-07 18:44:11.023358+03
534ce7ed-2afa-4b16-8f5d-47ba716e18ee	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	16	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	2026-06-07 18:44:11.023358+03
9e1520f2-a1fc-493f-814c-1355ee052221	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	17	9ea569e8-ea5b-40c1-99ca-ea03c68bbe4d	2026-06-07 18:44:11.023358+03
8057aa88-c38b-4c0f-8327-40d8225b04bb	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	18	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	2026-06-07 18:44:11.023358+03
3013b76c-1779-4350-85bd-fcb72c7fffbc	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	19	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	2026-06-07 18:44:11.023358+03
2c3fdfb2-2363-4b02-bf94-7579a9a321d6	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	20	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	2026-06-07 18:44:11.023358+03
f88884be-95d0-4699-867d-a2bae18e5da8	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	21	b4eaf12e-13a9-488c-81a9-460e39524950	2026-06-07 18:44:11.023358+03
c06c304f-113c-477d-a41c-c5c6876e17e9	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	22	b4eaf12e-13a9-488c-81a9-460e39524950	2026-06-07 18:44:11.023358+03
566202a9-939b-4c38-b402-98599f6e89da	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	23	65e1d23b-dfa8-44a3-bb40-15bee23ade75	2026-06-07 18:44:11.023358+03
f37a5d52-468f-4411-8594-05069b3f2e28	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	24	3fde298b-7536-4b09-a828-87223b009b1c	2026-06-07 18:44:11.023358+03
76ac9105-5550-46e3-bf23-b6f6cf97f43c	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	25	b4eaf12e-13a9-488c-81a9-460e39524950	2026-06-07 18:44:11.023358+03
\.


--
-- Data for Name: migration_unmapped_attribute; Type: TABLE DATA; Schema: map; Owner: yui
--

COPY map.migration_unmapped_attribute (unmapped_attribute_id, migration_run_id, source_system, source_record_id, target_person_id, source_field_name, source_field_value, reason, created_at) FROM stdin;
e9b384eb-295f-44b0-8cbf-c6586df35b8b	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	1	06ac479a-edda-4596-9bb0-9deb06e869a8	customers.marital	женат	Target tech marketplace customer model has no marital status field	2026-06-07 18:44:11.023358+03
f98ef770-0a9d-4d98-9a5c-5de0e392500f	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	2	ea3eb759-6095-4565-98d0-0fd031f58fcb	customers.marital	не замужем	Target tech marketplace customer model has no marital status field	2026-06-07 18:44:11.023358+03
efe72faf-1627-48c6-943f-c83608ae066a	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	3	0ad7b981-2af7-472f-99f9-69ce294b9abd	customers.marital	холост	Target tech marketplace customer model has no marital status field	2026-06-07 18:44:11.023358+03
2bcbff6e-2598-4f68-9c4c-8d33f3d252b4	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	4	0ad7b981-2af7-472f-99f9-69ce294b9abd	customers.marital	Разведён	Target tech marketplace customer model has no marital status field	2026-06-07 18:44:11.023358+03
577aadb0-474b-4664-b54c-617ceff84778	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	5	19980952-8d8b-4cc1-9358-72a785bd48e2	customers.marital	замужем	Target tech marketplace customer model has no marital status field	2026-06-07 18:44:11.023358+03
2ee770b6-57ba-4214-85ee-483b3084d71c	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	7	fd592784-4d39-47d2-b247-a4a557add4d7	customers.marital	женат	Target tech marketplace customer model has no marital status field	2026-06-07 18:44:11.023358+03
37954b3b-15e6-408e-a004-93ee27548134	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	8	6e107408-70b2-4de9-8205-f5af46476a63	cust_extra.Sony	да	Attribute was not mapped to target business EAV	2026-06-07 18:44:11.023358+03
c0097da8-c365-4d0a-99e0-8842104ddc6f	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	8	6e107408-70b2-4de9-8205-f5af46476a63	customers.marital	одинока	Target tech marketplace customer model has no marital status field	2026-06-07 18:44:11.023358+03
5a3362f4-ae45-4164-9e0c-40c8cbfa5940	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	9	314f1da4-b6ba-41a3-88f4-ffd61e8ba47f	customers.marital	не указано	Target tech marketplace customer model has no marital status field	2026-06-07 18:44:11.023358+03
cc67fcdb-b69d-401b-8733-9abc81c14971	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	10	19980952-8d8b-4cc1-9358-72a785bd48e2	customers.marital	разведена	Target tech marketplace customer model has no marital status field	2026-06-07 18:44:11.023358+03
d1a83a58-547e-4f3c-aa85-62d363b53cf8	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	11	b1c3dde5-9ccc-4b5f-891c-57ebeece11c8	customers.marital	женат	Target tech marketplace customer model has no marital status field	2026-06-07 18:44:11.023358+03
af1b2a50-0809-4157-8307-d2c4eb1e6bfb	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	12	6e107408-70b2-4de9-8205-f5af46476a63	customers.marital	замужем	Target tech marketplace customer model has no marital status field	2026-06-07 18:44:11.023358+03
1de050f8-164d-4a4e-8f95-4a32a3afd429	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	13	162f794a-bac5-490a-acf5-160eb22fa716	customers.marital	Холост	Target tech marketplace customer model has no marital status field	2026-06-07 18:44:11.023358+03
08545559-c35d-424d-a23e-14224a7f926a	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	14	cffa55ae-4de8-4c9a-b8be-9a55292fe7b1	customers.marital	не замужем	Target tech marketplace customer model has no marital status field	2026-06-07 18:44:11.023358+03
225b4a52-9afa-400d-aaa8-76693d949ab7	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	15	995c7b75-4104-41cc-8946-fe53c81de20c	customers.marital	вдовец	Target tech marketplace customer model has no marital status field	2026-06-07 18:44:11.023358+03
07f67c50-e29a-4724-98d1-14b564629cc0	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	16	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	customers.marital	не женат	Target tech marketplace customer model has no marital status field	2026-06-07 18:44:11.023358+03
ee32a505-a5a1-41d6-91e5-05bab2a423d8	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	17	9ea569e8-ea5b-40c1-99ca-ea03c68bbe4d	customers.marital	одинокая	Target tech marketplace customer model has no marital status field	2026-06-07 18:44:11.023358+03
d4b45505-815d-4cce-a923-cd066ee75b5d	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	18	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	customers.marital	Женат	Target tech marketplace customer model has no marital status field	2026-06-07 18:44:11.023358+03
40eb5056-3b68-42ba-b28b-06abc4cc537c	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	19	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	customers.marital	замужем	Target tech marketplace customer model has no marital status field	2026-06-07 18:44:11.023358+03
0e85292a-6c3d-4b4e-adf0-8a238e4ecbb5	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	20	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	customers.marital	женат	Target tech marketplace customer model has no marital status field	2026-06-07 18:44:11.023358+03
3ebe1dab-e8cf-4762-b38b-1143ae9431dc	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	21	b4eaf12e-13a9-488c-81a9-460e39524950	customers.marital	незамужем	Target tech marketplace customer model has no marital status field	2026-06-07 18:44:11.023358+03
f9da1c96-8642-4ef3-a2ef-1b9e92486c14	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	22	b4eaf12e-13a9-488c-81a9-460e39524950	customers.marital	холостой	Target tech marketplace customer model has no marital status field	2026-06-07 18:44:11.023358+03
825b897a-1661-48de-b52e-08a05a368293	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	23	65e1d23b-dfa8-44a3-bb40-15bee23ade75	customers.marital	Замужем	Target tech marketplace customer model has no marital status field	2026-06-07 18:44:11.023358+03
ecab910b-a5ea-4dd7-a273-4c7887a3ffa6	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	24	3fde298b-7536-4b09-a828-87223b009b1c	customers.marital	женат	Target tech marketplace customer model has no marital status field	2026-06-07 18:44:11.023358+03
1e8c39b8-ee61-40c0-8be8-b547f5ebb8be	4a0792e4-24ee-4523-b6a6-1a0b6bc1aeca	partner_bd2	25	b4eaf12e-13a9-488c-81a9-460e39524950	customers.marital	не женат	Target tech marketplace customer model has no marital status field	2026-06-07 18:44:11.023358+03
\.


--
-- Data for Name: dict_account_status; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.dict_account_status (account_status_id, code, name) FROM stdin;
ab572d97-4008-4b0e-9db6-72ec49ec2dcd	ACTIVE	Активен
49ee063a-69bf-48e3-9780-497ee08509c5	BLOCKED	Заблокирован
35b3fe0d-cc12-46ae-b738-8d5da16bc73f	DELETED	Удален
0fb5475f-71a5-43b7-85fb-4cdffd9f2585	PENDING	Ожидает подтверждения
\.


--
-- Data for Name: dict_address_type; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.dict_address_type (address_type_id, code, name) FROM stdin;
0a265f6c-c591-4eb1-9fde-860a04155761	DELIVERY	Адрес доставки
4953feab-0ee2-43a8-bd4a-e3f397a030d6	HOME	Домашний адрес
c2700f93-5dbf-4dee-b850-c482c21439aa	PICKUP	Пункт выдачи
\.


--
-- Data for Name: dict_city; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.dict_city (city_id, region_id, name) FROM stdin;
e12269fd-28a5-48ad-ac83-a476c1f54a29	c7ffbf2a-d46e-4be3-8b53-e7b4a38c99c5	Подольск
c27279e3-6d76-490b-b4c0-ce294a220034	7b67ecf0-d2c9-4476-95fc-100a9ef0dd40	Не указан
38cd737f-86f9-4220-9c90-45bb90e2c98a	9e2b94f7-5aaa-4845-b522-547a3718e5d1	Ростов-На-Дону
e0fd670b-7f13-4c25-a091-3b69b57eeeae	1a7ea4cb-b492-4664-8d56-1807a1885299	Екатеринбург
5e6c532c-93ce-4e7f-8f63-9a130d27ab44	240a1287-8a6a-4eb0-b752-8caa317a20b5	Казань
4d8683e7-125a-4e47-b3ee-888c1861df80	cc959383-0154-442e-8a25-b3978bff8ec8	Новосибирск
04f04aa1-c6e7-4875-b90b-afea53c6a2b3	c7ffbf2a-d46e-4be3-8b53-e7b4a38c99c5	Химки
592103da-a24d-4735-9475-d9fe6e88dbd7	f55682d9-aaf2-4622-b80f-bb6b299d9774	Краснодар
081bd21c-3e6e-4585-9111-a9567a72e75c	ad792a09-9fa0-41c5-9ee4-18500d55ad9f	Москва
40841ce5-f1ee-4d73-a25a-abcb96b1e21e	826af9bc-965f-4298-b190-8ec68de4d8c9	Санкт-Петербург
\.


--
-- Data for Name: dict_consent_type; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.dict_consent_type (consent_type_id, code, name, description) FROM stdin;
caaecc37-11ec-4832-b99b-beb8c30f411d	PERSONAL_DATA_PROCESSING	Обработка персональных данных	Согласие на хранение и обработку персональных данных покупателя
912dda8c-1f03-452a-aa1a-1a0c5add40b4	MARKETING_EMAIL	Email-рассылка	Согласие на рекламные письма
b18eafa9-0618-45ba-8762-98aaf1ba4161	MARKETING_SMS	SMS-рассылка	Согласие на рекламные SMS
ab774da4-f227-425d-92ac-1b5b93a3c838	DATA_TRANSFER_TO_PARTNERS	Передача данных партнерам	Согласие на передачу данных службам доставки и партнерам
\.


--
-- Data for Name: dict_contact_type; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.dict_contact_type (contact_type_id, code, name) FROM stdin;
72637c84-ac87-49d4-9383-ec5788f52af7	EMAIL	Email
d000df9c-5de3-4d15-8b50-053f010ac84e	PHONE	Телефон
d07693b8-7595-441a-8e66-8e6345a31687	TELEGRAM	Telegram
81c03a87-55c7-449c-96f2-3abf479e1ea2	WHATSAPP	WhatsApp
\.


--
-- Data for Name: dict_country; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.dict_country (country_id, iso_code, name) FROM stdin;
010165a5-aaab-4238-a6e9-5fbde95618cd	\N	Россия
\.


--
-- Data for Name: dict_document_type; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.dict_document_type (document_type_id, code, name) FROM stdin;
b5efb985-8956-4535-a11a-ca095b2717b4	PASSPORT_RF	Паспорт РФ
739ff378-3ba0-443f-b745-99b6375fc676	DRIVER_LICENSE	Водительское удостоверение
072c79e3-d892-469a-b753-ccf9fbe3a099	MILITARY_ID	Военный билет
65e8aec1-d43c-4f80-8306-573c76fe4ef6	FOREIGN_PASSPORT	Заграничный паспорт
\.


--
-- Data for Name: dict_gender; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.dict_gender (gender_id, code, name) FROM stdin;
c5f4d5a0-cfb6-4469-9f16-5bdaefb96d7d	MALE	Мужской
20b12bc6-a5bc-409a-9912-e9361a8ead2e	FEMALE	Женский
064c1126-7d66-4d57-99f8-60d49c1c88ec	UNKNOWN	Не указан
\.


--
-- Data for Name: dict_identifier_type; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.dict_identifier_type (identifier_type_id, code, name) FROM stdin;
5937abf2-7985-4c70-bfd8-adb324b0bf86	INN	ИНН
1ad93ae3-d143-4982-830c-d76958aa3d8f	SNILS	СНИЛС
7ed5f25a-1a52-4551-accb-956345eb6756	LOYALTY_CARD	Карта лояльности
\.


--
-- Data for Name: dict_region; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.dict_region (region_id, country_id, name) FROM stdin;
7b67ecf0-d2c9-4476-95fc-100a9ef0dd40	010165a5-aaab-4238-a6e9-5fbde95618cd	Не указан
9e2b94f7-5aaa-4845-b522-547a3718e5d1	010165a5-aaab-4238-a6e9-5fbde95618cd	Ростовская область
1a7ea4cb-b492-4664-8d56-1807a1885299	010165a5-aaab-4238-a6e9-5fbde95618cd	Свердловская область
240a1287-8a6a-4eb0-b752-8caa317a20b5	010165a5-aaab-4238-a6e9-5fbde95618cd	Татарстан
cc959383-0154-442e-8a25-b3978bff8ec8	010165a5-aaab-4238-a6e9-5fbde95618cd	Новосибирская область
c7ffbf2a-d46e-4be3-8b53-e7b4a38c99c5	010165a5-aaab-4238-a6e9-5fbde95618cd	Московская область
f55682d9-aaf2-4622-b80f-bb6b299d9774	010165a5-aaab-4238-a6e9-5fbde95618cd	Краснодарский край
ad792a09-9fa0-41c5-9ee4-18500d55ad9f	010165a5-aaab-4238-a6e9-5fbde95618cd	Москва
826af9bc-965f-4298-b190-8ec68de4d8c9	010165a5-aaab-4238-a6e9-5fbde95618cd	Санкт-Петербург
\.


--
-- Data for Name: dict_street; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.dict_street (street_id, city_id, name) FROM stdin;
37837cbd-a375-4afb-b2f9-6f6d0f80c655	04f04aa1-c6e7-4875-b90b-afea53c6a2b3	Молодежная
926994ea-17bd-4047-839c-6cd05010a38b	5e6c532c-93ce-4e7f-8f63-9a130d27ab44	Баумана
1a079ef4-f6e9-4d7b-a5e1-929043ee29c2	4d8683e7-125a-4e47-b3ee-888c1861df80	Красный проспект
7b3e3aab-7917-444f-a880-143d57d1a16c	081bd21c-3e6e-4585-9111-a9567a72e75c	Арбат
d892be9c-354c-47bf-943b-221efae1bc56	e12269fd-28a5-48ad-ac83-a476c1f54a29	Садовая
b4a1e5a6-c84b-462d-831d-bcb81066dca8	40841ce5-f1ee-4d73-a25a-abcb96b1e21e	Литейный проспект
15eb2230-ab04-444d-862c-f9c57e4f5906	5e6c532c-93ce-4e7f-8f63-9a130d27ab44	Кремлевская
aaaaedc6-55dc-4b37-8bf7-dca613fa25b7	4d8683e7-125a-4e47-b3ee-888c1861df80	Карла Маркса
64a3d5f6-b094-427a-8207-3f8ca4aaa6db	081bd21c-3e6e-4585-9111-a9567a72e75c	Профсоюзная
9fbb83a6-3e16-4f9e-b1e6-a3aa034b27bc	592103da-a24d-4735-9475-d9fe6e88dbd7	Красная
5b7d91e3-02e9-457f-b014-688ab364ee53	38cd737f-86f9-4220-9c90-45bb90e2c98a	Большая Садовая
042ab31f-5a80-4747-a2b1-be4311865988	e0fd670b-7f13-4c25-a091-3b69b57eeeae	Малышева
59e75344-22b5-4049-b7d5-649fd0c04d43	40841ce5-f1ee-4d73-a25a-abcb96b1e21e	Невский проспект
c0a28558-344b-4fa2-b5fe-253be1955c0c	04f04aa1-c6e7-4875-b90b-afea53c6a2b3	Юбилейный проспект
c94f1c1f-2598-42d3-a86c-2382672396c8	081bd21c-3e6e-4585-9111-a9567a72e75c	Лесной пер.
ca22c7ca-6387-438d-9da5-7f936635eae1	40841ce5-f1ee-4d73-a25a-abcb96b1e21e	Маршала Жукова
8012b294-4f49-4d7e-a143-0a1e0e21cdf0	081bd21c-3e6e-4585-9111-a9567a72e75c	Коньково
7efea53f-2bde-46c5-945d-aea0b7b5f258	081bd21c-3e6e-4585-9111-a9567a72e75c	4-й Лесной пер.
71cb9f52-01f2-4e48-9b96-6db212e65174	592103da-a24d-4735-9475-d9fe6e88dbd7	Северная
ae279e42-386d-4cc1-ba5f-ad0af1cec886	38cd737f-86f9-4220-9c90-45bb90e2c98a	Ленина
e32a0ee4-7e38-40a3-8a78-864ee8607fd3	40841ce5-f1ee-4d73-a25a-abcb96b1e21e	Кронверкский пр-т
6c9b5a44-c861-4039-9110-604eff26f901	081bd21c-3e6e-4585-9111-a9567a72e75c	Тверская
10401bc2-2a35-4099-b7e0-773c8181a127	081bd21c-3e6e-4585-9111-a9567a72e75c	шоссе 34
e0e79245-d43b-48b0-a778-2ddaf74e2913	40841ce5-f1ee-4d73-a25a-abcb96b1e21e	пр -т
e86de646-7ca3-49a1-97f6-b7fc870df877	4d8683e7-125a-4e47-b3ee-888c1861df80	Красный проспект 26/5
079ebb37-1efd-49c5-be2e-b7c72b209d1a	e0fd670b-7f13-4c25-a091-3b69b57eeeae	ул. Ленина 100
3431694f-84ba-4154-9fa7-8c8ffb367a31	081bd21c-3e6e-4585-9111-a9567a72e75c	ул. Пушкина
d25e2705-00d9-4e82-8e06-7cac8f4b22a4	c27279e3-6d76-490b-b4c0-ce294a220034	ул Садовая 5
073f7c9f-2f45-4df0-8edb-3566bea3fa88	081bd21c-3e6e-4585-9111-a9567a72e75c	пр. Мира 55-А
36b197a8-1318-4532-b4d9-362ab09d6eaa	40841ce5-f1ee-4d73-a25a-abcb96b1e21e	пр. 100
98ebbd59-ae7a-462b-a554-ca46a2ff1c6f	081bd21c-3e6e-4585-9111-a9567a72e75c	ул. Тверская
a4cb1e22-4bc9-4996-bea8-edf80c8fc0db	38cd737f-86f9-4220-9c90-45bb90e2c98a	Пр. Ленина 15 оф. 304
c47dfe5e-059d-4626-a0cb-c1714169dbb6	e0fd670b-7f13-4c25-a091-3b69b57eeeae	ул. Малышева 51-79
baef930d-7240-4c5e-af42-167c5a2316c6	081bd21c-3e6e-4585-9111-a9567a72e75c	ул. 4-я Тверская-Ямская 5
c221f4af-2a56-4018-a32c-592d092698da	5e6c532c-93ce-4e7f-8f63-9a130d27ab44	ул. Баумана 10
ccaedd60-171d-48c3-963d-4cd30399e4e2	40841ce5-f1ee-4d73-a25a-abcb96b1e21e	ул. Маршала Жукова
052bd77b-5208-491a-b4ef-af759ccb844f	4d8683e7-125a-4e47-b3ee-888c1861df80	пр-т Карла Маркса 7 кв 19
408aeb01-4e24-4020-8893-dea35486d75a	04f04aa1-c6e7-4875-b90b-afea53c6a2b3	пр. 78
b78f81d2-e78a-43b2-be30-bba89e79cfeb	592103da-a24d-4735-9475-d9fe6e88dbd7	Краснодар Красная 135
cd15a00b-4ab0-44b4-9bcc-1730f955c0a6	081bd21c-3e6e-4585-9111-a9567a72e75c	пер. 4
14232dff-f0d6-46c4-8834-424a76849104	40841ce5-f1ee-4d73-a25a-abcb96b1e21e	проспект 44
\.


--
-- Data for Name: dict_verification_status; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.dict_verification_status (verification_status_id, code, name) FROM stdin;
5d8085e7-9311-432c-8d46-61ddf0008a7b	NOT_CHECKED	Не проверен
04403f61-f336-4eaf-8ee6-f4a148ccd2db	PENDING	На проверке
1084ec39-bdd9-423f-a7d0-1c4e18d07168	VERIFIED	Проверен
2b42eec1-a7f9-40ac-9634-369f49740eb9	REJECTED	Отклонен
\.


--
-- Data for Name: person_identifier; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.person_identifier (identifier_id, person_id, identifier_type_id, identifier_value, raw_value, is_verified) FROM stdin;
df5559eb-b536-4620-9869-baaa695d50a6	995c7b75-4104-41cc-8946-fe53c81de20c	5937abf2-7985-4c70-bfd8-adb324b0bf86	770123456789	ИНН: 7701-234567-89	f
8f1ab1be-c96e-417b-bac7-9ff3a272158e	abc36053-4caa-4234-b469-90c2f0ae43f1	7ed5f25a-1a52-4551-accb-956345eb6756	00077	карта TECH-00077	t
b1283ab9-b596-40d5-ade1-2c6bb44c1c7e	d35af3e1-167d-4b2a-8075-b530012c5b63	7ed5f25a-1a52-4551-accb-956345eb6756	00001	карта TECH-00001	t
d896be79-2439-4fdd-8a79-f79dcc7099e7	e629d14c-b866-487e-ab96-8b01ab7f2836	7ed5f25a-1a52-4551-accb-956345eb6756	00002	карта TECH-00002	t
8ef5b49e-14da-47cf-8f00-a234e0a6229b	3345e1ce-1de2-4519-99a0-f585cab7398a	7ed5f25a-1a52-4551-accb-956345eb6756	00003	карта TECH-00003	t
4fdada4e-1b71-4edd-ad41-d9f675810216	dac44047-f9eb-4702-a9ed-1866a95da0c8	7ed5f25a-1a52-4551-accb-956345eb6756	00004	карта TECH-00004	t
5e1340b6-4b4f-4498-bbb6-4a71a0b9079a	c07e21b3-ddbb-4a10-b476-8a293fe4d8a3	7ed5f25a-1a52-4551-accb-956345eb6756	00005	карта TECH-00005	t
a24a86c2-15a6-42de-978a-b72e24a0b55f	2fc7c4eb-10ae-4e45-ac36-265ed4cb5170	7ed5f25a-1a52-4551-accb-956345eb6756	00006	карта TECH-00006	t
6fe16bcb-9ec9-4dc6-84df-73927cbf57f5	d4ae4121-632e-43c8-8837-66eb636f1ef5	7ed5f25a-1a52-4551-accb-956345eb6756	00007	карта TECH-00007	t
2604280b-db4d-42a7-a74e-bfdbaf65e41c	6de364c7-80e9-4f25-913c-0132beea6dd9	7ed5f25a-1a52-4551-accb-956345eb6756	00008	карта TECH-00008	t
13e40dc4-7943-4f69-acce-57715fefd2cf	24705f4b-8062-4e79-b2e8-373f8919f2fa	7ed5f25a-1a52-4551-accb-956345eb6756	00009	карта TECH-00009	t
ff855b7d-dac0-4fac-93ef-9c27ba947a69	2fb47c36-e066-4314-be66-72a1e5ca8789	7ed5f25a-1a52-4551-accb-956345eb6756	00010	карта TECH-00010	t
dd219d1e-5ad9-43f6-8a6e-5aa28f8e9648	34e9b7f0-650b-4a39-b90a-547b4de07dc2	7ed5f25a-1a52-4551-accb-956345eb6756	00011	карта TECH-00011	t
556173a1-29a2-4775-bafe-2cb4e7fb0eaf	b545f08b-037e-4246-8c20-481f91097b7d	7ed5f25a-1a52-4551-accb-956345eb6756	00012	карта TECH-00012	t
b13f9f83-d432-4b77-be3b-d023bd86f26d	4e69e1df-f2a3-4637-89be-ad45c0c37294	7ed5f25a-1a52-4551-accb-956345eb6756	00013	карта TECH-00013	t
e2e4871d-a5d3-4795-81e8-c741a2cdbc38	b4eaf12e-13a9-488c-81a9-460e39524950	7ed5f25a-1a52-4551-accb-956345eb6756	00014	карта TECH-00014	t
0c4391cd-9402-49c8-8a46-13828a88b2d9	27c7b285-1b06-4e1b-854f-52acea9a3ad5	7ed5f25a-1a52-4551-accb-956345eb6756	00015	карта TECH-00015	t
3f155d02-253e-482f-8ba3-f8cf52492ffd	e3efa025-1091-4a9c-a6c8-4d2d50228fba	7ed5f25a-1a52-4551-accb-956345eb6756	00016	карта TECH-00016	t
9d40b453-c210-4bd6-96a3-d607a3a8a4d9	65e1d23b-dfa8-44a3-bb40-15bee23ade75	7ed5f25a-1a52-4551-accb-956345eb6756	00017	карта TECH-00017	t
97db351b-a260-4031-aa9c-bc2d29c3d9d3	878871b9-bfcc-4946-baa0-4acf54f6c4b1	7ed5f25a-1a52-4551-accb-956345eb6756	00018	карта TECH-00018	t
399c40ae-7dc1-425c-b9ab-c4e92208efee	17155d97-bf5f-4e23-a0c5-d4e903c45d9a	7ed5f25a-1a52-4551-accb-956345eb6756	00019	карта TECH-00019	t
700d0f48-e181-42c9-8ddb-e209858fd477	6e107408-70b2-4de9-8205-f5af46476a63	7ed5f25a-1a52-4551-accb-956345eb6756	00020	карта TECH-00020	t
7f5929d7-b6f4-429d-a9d2-2dee5ced652e	06ac479a-edda-4596-9bb0-9deb06e869a8	5937abf2-7985-4c70-bfd8-adb324b0bf86	7743001234	7743001234	f
b70b6b0d-a58f-4de7-b73c-b42bb76f6d42	06ac479a-edda-4596-9bb0-9deb06e869a8	1ad93ae3-d143-4982-830c-d76958aa3d8f	11223344595	112-233-445 95	f
c1a609b9-0a13-452e-b60c-6298c4ce064a	ea3eb759-6095-4565-98d0-0fd031f58fcb	5937abf2-7985-4c70-bfd8-adb324b0bf86	770100223344	7701 00 223344	f
e39f491e-629e-4b28-bc1a-008794348a7b	0ad7b981-2af7-472f-99f9-69ce294b9abd	5937abf2-7985-4c70-bfd8-adb324b0bf86	540100998877	540100 998877	f
ba80c07b-6b03-4bd9-b750-664df97e3336	0ad7b981-2af7-472f-99f9-69ce294b9abd	1ad93ae3-d143-4982-830c-d76958aa3d8f	32145678901	321 456 789 01	f
63e5ece1-d5bd-49e0-94c1-19f1c5988388	fd592784-4d39-47d2-b247-a4a557add4d7	5937abf2-7985-4c70-bfd8-adb324b0bf86	6612005544332	6612005544332	f
c8f0d143-ae13-4d14-a440-5e576aabddfe	fd592784-4d39-47d2-b247-a4a557add4d7	1ad93ae3-d143-4982-830c-d76958aa3d8f	55566677700	55566677700	f
e1ec8494-1136-46d7-b63d-fb69f90385b3	6e107408-70b2-4de9-8205-f5af46476a63	1ad93ae3-d143-4982-830c-d76958aa3d8f	99988877766	999 888 777 66	f
09e18ef0-d97b-486d-b4d5-eb3e2be6ac3e	19980952-8d8b-4cc1-9358-72a785bd48e2	5937abf2-7985-4c70-bfd8-adb324b0bf86	616400112233	6 164 001 122 33	f
3593e743-297d-41d3-a161-7d565c2ff13b	19980952-8d8b-4cc1-9358-72a785bd48e2	1ad93ae3-d143-4982-830c-d76958aa3d8f	10020030040	100.200.300-40	f
96b07403-5d0e-4b5b-981f-19b732a644bd	b1c3dde5-9ccc-4b5f-891c-57ebeece11c8	5937abf2-7985-4c70-bfd8-adb324b0bf86	7743000132	7 743 000 132	f
2c850163-1f07-4a36-b004-08be759efb94	b1c3dde5-9ccc-4b5f-891c-57ebeece11c8	1ad93ae3-d143-4982-830c-d76958aa3d8f	77700011200	77700011200	f
f4ff6a09-dcd0-41cd-b787-251b1e8723c9	6e107408-70b2-4de9-8205-f5af46476a63	5937abf2-7985-4c70-bfd8-adb324b0bf86	7701987654	7701987654	f
d147c2a0-9f14-4ff3-be81-51f900b80886	6e107408-70b2-4de9-8205-f5af46476a63	1ad93ae3-d143-4982-830c-d76958aa3d8f	44556677899	445-566-778 99	f
c6765dfa-e426-4c3b-8b0f-eb3e783f6b7e	162f794a-bac5-490a-acf5-160eb22fa716	5937abf2-7985-4c70-bfd8-adb324b0bf86	504000123456	5040-001-234-56	f
fe9b5a7a-e344-43ec-8242-eb3af29f4cb5	162f794a-bac5-490a-acf5-160eb22fa716	1ad93ae3-d143-4982-830c-d76958aa3d8f	98765432100	98765432100	f
5a2ee2a6-359f-47bf-9e5f-6a519525d785	cffa55ae-4de8-4c9a-b8be-9a55292fe7b1	5937abf2-7985-4c70-bfd8-adb324b0bf86	5030101234	5030101234	f
df09d0ad-9ca1-432e-b20e-26ac28965ef0	995c7b75-4104-41cc-8946-fe53c81de20c	5937abf2-7985-4c70-bfd8-adb324b0bf86	7700000000	7700000000	f
a31d9024-8e25-45fc-a57f-73a21ada797e	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	5937abf2-7985-4c70-bfd8-adb324b0bf86	5050123456	5050 1234 56	f
8f364adc-06a6-4851-a859-2d17bdb1f42f	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	1ad93ae3-d143-4982-830c-d76958aa3d8f	88899900011	88899900011	f
714cd8ab-362a-4b00-bb80-caf371e60cf9	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	5937abf2-7985-4c70-bfd8-adb324b0bf86	7714998877	7714998877	f
5852f9c4-6ded-49b3-85a3-f04b128b1de8	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	1ad93ae3-d143-4982-830c-d76958aa3d8f	00100200304	001 002 003 04	f
8b1ed9d6-f00d-40fa-9b50-597c94791a29	995c7b75-4104-41cc-8946-fe53c81de20c	1ad93ae3-d143-4982-830c-d76958aa3d8f	12345678900	123-456-789 00	f
429d1bb3-ac6b-4492-b555-de531a7bed08	b4eaf12e-13a9-488c-81a9-460e39524950	5937abf2-7985-4c70-bfd8-adb324b0bf86	770100445566	7701-00-445566	f
4541af80-da62-4725-8117-8eca0a7ec933	9ea569e8-ea5b-40c1-99ca-ea03c68bbe4d	1ad93ae3-d143-4982-830c-d76958aa3d8f	32165498700	321-654-987 00	f
\.


--
-- Data for Name: person_profile; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.person_profile (person_id, last_name, first_name, middle_name, birth_date, birth_date_raw, gender_id, created_at) FROM stdin;
ff58df0d-e9b5-44b3-9458-d3080031deff	Петрова	Мария	\N	1990-05-01	01.05.90	20b12bc6-a5bc-409a-9912-e9361a8ead2e	2026-06-07 18:44:10.928178+03
abc36053-4caa-4234-b469-90c2f0ae43f1	Сидоров	Алексей	Павлович	1995-12-03	1995-12-03	c5f4d5a0-cfb6-4469-9f16-5bdaefb96d7d	2026-06-07 18:44:10.933062+03
bcfa673e-ca8d-4c18-be68-e245f5375075	Кузнецова	Елена	\N	\N	31/02/1988	20b12bc6-a5bc-409a-9912-e9361a8ead2e	2026-06-07 18:44:10.936834+03
fe5d381f-5d02-421b-9cc6-e55541e56478	Орлов	Денис	\N	\N	\N	064c1126-7d66-4d57-99f8-60d49c1c88ec	2026-06-07 18:44:10.940391+03
d35af3e1-167d-4b2a-8075-b530012c5b63	Смирнов	Павел	Олегович	1989-04-12	1989/04/12	c5f4d5a0-cfb6-4469-9f16-5bdaefb96d7d	2026-06-07 18:44:10.944758+03
e629d14c-b866-487e-ab96-8b01ab7f2836	Васильева	Ольга	Игоревна	1991-09-12	12.09.1991	20b12bc6-a5bc-409a-9912-e9361a8ead2e	2026-06-07 18:44:10.944758+03
3345e1ce-1de2-4519-99a0-f585cab7398a	Никитин	Роман	\N	1984-11-07	7 ноября 1984 года	c5f4d5a0-cfb6-4469-9f16-5bdaefb96d7d	2026-06-07 18:44:10.944758+03
dac44047-f9eb-4702-a9ed-1866a95da0c8	Медведева	Ирина	Сергеевна	2003-03-03	03.03.03	20b12bc6-a5bc-409a-9912-e9361a8ead2e	2026-06-07 18:44:10.944758+03
c07e21b3-ddbb-4a10-b476-8a293fe4d8a3	Алексеев	Григорий	Андреевич	1978-10-30	1978-10-30	c5f4d5a0-cfb6-4469-9f16-5bdaefb96d7d	2026-06-07 18:44:10.944758+03
2fc7c4eb-10ae-4e45-ac36-265ed4cb5170	Романова	Дарья	\N	\N	н/д	20b12bc6-a5bc-409a-9912-e9361a8ead2e	2026-06-07 18:44:10.944758+03
d4ae4121-632e-43c8-8837-66eb636f1ef5	Гаврилов	Максим	Петрович	1982-02-14	14-02-1982	c5f4d5a0-cfb6-4469-9f16-5bdaefb96d7d	2026-06-07 18:44:10.944758+03
6de364c7-80e9-4f25-913c-0132beea6dd9	Егорова	Виктория	Алексеевна	1994-06-30	1994-06-30	20b12bc6-a5bc-409a-9912-e9361a8ead2e	2026-06-07 18:44:10.944758+03
24705f4b-8062-4e79-b2e8-373f8919f2fa	Павлов	Степан	Денисович	1991-03-05	March 5, 1991	c5f4d5a0-cfb6-4469-9f16-5bdaefb96d7d	2026-06-07 18:44:10.944758+03
2fb47c36-e066-4314-be66-72a1e5ca8789	Фомина	Ксения	\N	1970-12-25	25/12/1970	20b12bc6-a5bc-409a-9912-e9361a8ead2e	2026-06-07 18:44:10.944758+03
34e9b7f0-650b-4a39-b90a-547b4de07dc2	Беляев	Матвей	Ильич	2000-01-01	2000-01-01	c5f4d5a0-cfb6-4469-9f16-5bdaefb96d7d	2026-06-07 18:44:10.944758+03
b545f08b-037e-4246-8c20-481f91097b7d	Соловьева	Наталья	Романовна	\N	31/02/1988	20b12bc6-a5bc-409a-9912-e9361a8ead2e	2026-06-07 18:44:10.944758+03
4e69e1df-f2a3-4637-89be-ad45c0c37294	Титов	Арсений	\N	1991-01-05	5 января 1991	c5f4d5a0-cfb6-4469-9f16-5bdaefb96d7d	2026-06-07 18:44:10.944758+03
27c7b285-1b06-4e1b-854f-52acea9a3ad5	Крылов	Федор	Вячеславович	1979-11-30	1979-11-30	c5f4d5a0-cfb6-4469-9f16-5bdaefb96d7d	2026-06-07 18:44:10.944758+03
e3efa025-1091-4a9c-a6c8-4d2d50228fba	Зуева	Марина	\N	1967-08-15	15 августа 1967 года	20b12bc6-a5bc-409a-9912-e9361a8ead2e	2026-06-07 18:44:10.944758+03
878871b9-bfcc-4946-baa0-4acf54f6c4b1	Макарова	Юлия	Олеговна	1985-03-15	1985/03/15	20b12bc6-a5bc-409a-9912-e9361a8ead2e	2026-06-07 18:44:10.944758+03
17155d97-bf5f-4e23-a0c5-d4e903c45d9a	Дорофеев	Лев	\N	\N	ноябрь 1979	c5f4d5a0-cfb6-4469-9f16-5bdaefb96d7d	2026-06-07 18:44:10.944758+03
06ac479a-edda-4596-9bb0-9deb06e869a8	Иванов	Иван	Сергеевич	1988-03-15	1988-03-15	c5f4d5a0-cfb6-4469-9f16-5bdaefb96d7d	2026-06-07 18:44:11.023358+03
ea3eb759-6095-4565-98d0-0fd031f58fcb	Петрова	Анна	Михайловна	1992-07-15	15.07.1992	20b12bc6-a5bc-409a-9912-e9361a8ead2e	2026-06-07 18:44:11.023358+03
0ad7b981-2af7-472f-99f9-69ce294b9abd	Сидоров	Борис	Геннадьевич	1985-08-15	15-08-1985	c5f4d5a0-cfb6-4469-9f16-5bdaefb96d7d	2026-06-07 18:44:11.023358+03
fd592784-4d39-47d2-b247-a4a557add4d7	Лебедев	Сергей	Николаевич	1990-05-01	ноябрь 1979	c5f4d5a0-cfb6-4469-9f16-5bdaefb96d7d	2026-06-07 18:44:11.023358+03
314f1da4-b6ba-41a3-88f4-ffd61e8ba47f	Михайлов	Андрей	\N	\N	\N	c5f4d5a0-cfb6-4469-9f16-5bdaefb96d7d	2026-06-07 18:44:11.023358+03
19980952-8d8b-4cc1-9358-72a785bd48e2	Федорова	Юлия	Олеговна	1985-03-15	1985/03/15	20b12bc6-a5bc-409a-9912-e9361a8ead2e	2026-06-07 18:44:11.023358+03
b1c3dde5-9ccc-4b5f-891c-57ebeece11c8	Попов	Виктор	Геннадьевич	1972-11-03	03.11.1972	c5f4d5a0-cfb6-4469-9f16-5bdaefb96d7d	2026-06-07 18:44:11.023358+03
6e107408-70b2-4de9-8205-f5af46476a63	Кузнецова	Анна	Максимовна	1993-12-25	25 декабря 1993 года	20b12bc6-a5bc-409a-9912-e9361a8ead2e	2026-06-07 18:44:10.944758+03
162f794a-bac5-490a-acf5-160eb22fa716	Зайцев	Роман	Евгеньевич	1991-04-07	07-04-1991	c5f4d5a0-cfb6-4469-9f16-5bdaefb96d7d	2026-06-07 18:44:11.023358+03
cffa55ae-4de8-4c9a-b8be-9a55292fe7b1	Белова	К.	\N	1998-06-22	1998/06/22	20b12bc6-a5bc-409a-9912-e9361a8ead2e	2026-06-07 18:44:11.023358+03
995c7b75-4104-41cc-8946-fe53c81de20c	Тарасов	Константин	Игоревич	1970-12-25	25/12/1970	064c1126-7d66-4d57-99f8-60d49c1c88ec	2026-06-07 18:44:10.912383+03
9ea569e8-ea5b-40c1-99ca-ea03c68bbe4d	Фролова	Наталья	\N	1991-03-05	March 5, 1991	20b12bc6-a5bc-409a-9912-e9361a8ead2e	2026-06-07 18:44:11.023358+03
f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	Богданов	Виктор	Анатольевич	1967-08-15	15 августа 1967 года	c5f4d5a0-cfb6-4469-9f16-5bdaefb96d7d	2026-06-07 18:44:11.023358+03
65e1d23b-dfa8-44a3-bb40-15bee23ade75	Горбунова	Диана	Сергеевна	\N	н/д	20b12bc6-a5bc-409a-9912-e9361a8ead2e	2026-06-07 18:44:10.944758+03
3fde298b-7536-4b09-a828-87223b009b1c	Попеску	Ион	Александрович	1987-03-15	15.03.1987	c5f4d5a0-cfb6-4469-9f16-5bdaefb96d7d	2026-06-07 18:44:11.023358+03
b4eaf12e-13a9-488c-81a9-460e39524950	Чернов	Илья	Павлович	1991-01-05	5 января 1991	c5f4d5a0-cfb6-4469-9f16-5bdaefb96d7d	2026-06-07 18:44:10.944758+03
\.


--
-- Data for Name: user_account; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.user_account (account_id, person_id, login, password_hash, account_status_id, registered_at, last_login_at) FROM stdin;
f71f0bf6-dcec-46d9-abe1-0734c2e4b8a5	ff58df0d-e9b5-44b3-9458-d3080031deff	m.pet.rova@example.com	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:10.928178+03	\N
5f0b3391-22d8-41eb-b913-da16e804c71b	abc36053-4caa-4234-b469-90c2f0ae43f1	alexey.sid	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:10.933062+03	\N
cfb90562-1dab-4465-9ab5-36fa0f47dd07	bcfa673e-ca8d-4c18-be68-e245f5375075	elena_k	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:10.936834+03	\N
6cbfc7c5-e0bb-43c1-9adb-3dab081e7d71	fe5d381f-5d02-421b-9cc6-e55541e56478	denis.orlov@example.net	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:10.940391+03	\N
3404496d-a647-4f87-b5be-6d1d22144a4e	d35af3e1-167d-4b2a-8075-b530012c5b63	p.smirnov.tech	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:10.944758+03	\N
92423fa9-e461-4458-b92f-467d618fdd8f	e629d14c-b866-487e-ab96-8b01ab7f2836	olga.v.tech	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:10.944758+03	\N
b764644f-ca1e-453c-9692-042a3dc485e6	3345e1ce-1de2-4519-99a0-f585cab7398a	roman_nikitin	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:10.944758+03	\N
f3fee064-3faf-4522-a930-70b92581cb97	dac44047-f9eb-4702-a9ed-1866a95da0c8	irina.medvedeva	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:10.944758+03	\N
dbe03586-375d-41fe-8d19-d4b4aeec623f	c07e21b3-ddbb-4a10-b476-8a293fe4d8a3	g.alekseev	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:10.944758+03	\N
840dafaf-ed97-47d7-a605-0c89e2dea8b8	2fc7c4eb-10ae-4e45-ac36-265ed4cb5170	d.romanova	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:10.944758+03	\N
2651debd-17fc-4366-b67f-bff2ec7de054	d4ae4121-632e-43c8-8837-66eb636f1ef5	max.gavrilov	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:10.944758+03	\N
27919ad7-e2a3-41ff-ae2e-c0b37b1d6b0b	6de364c7-80e9-4f25-913c-0132beea6dd9	v.egorova	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:10.944758+03	\N
4a62e164-e9b0-4f47-b595-de148b4ba11c	24705f4b-8062-4e79-b2e8-373f8919f2fa	stepan.pavlov	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:10.944758+03	\N
ca3eb650-ba94-47b2-a19b-909314d2373a	2fb47c36-e066-4314-be66-72a1e5ca8789	ks.fomina	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:10.944758+03	\N
79b6b784-df1e-464b-9a91-fa5d1951be5f	34e9b7f0-650b-4a39-b90a-547b4de07dc2	matvey.belyaev	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:10.944758+03	\N
c683808e-d64c-4c99-9f49-e13f971db467	b545f08b-037e-4246-8c20-481f91097b7d	n.solovieva	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:10.944758+03	\N
476ae78f-cd21-4b75-be05-90c4c8a0ed16	4e69e1df-f2a3-4637-89be-ad45c0c37294	ars.titov	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:10.944758+03	\N
ff3f09dc-6f40-4f28-a60b-d5839dfa0992	27c7b285-1b06-4e1b-854f-52acea9a3ad5	fedor.krylov	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:10.944758+03	\N
9e9f2c08-b1a8-4a46-9363-e20b3a835c62	e3efa025-1091-4a9c-a6c8-4d2d50228fba	marina.zueva	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:10.944758+03	\N
804b03ae-4a1e-47cd-8953-930bec34c6b5	878871b9-bfcc-4946-baa0-4acf54f6c4b1	y.makarova	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:10.944758+03	\N
990cdeca-4c2c-4523-a442-e309352d48d1	17155d97-bf5f-4e23-a0c5-d4e903c45d9a	lev.dorofeev	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:10.944758+03	\N
fb0da599-0aa3-4fbe-b2fd-8aed5d0df340	06ac479a-edda-4596-9bb0-9deb06e869a8	ivan.ivanov88	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:11.023358+03	\N
67bfef38-0100-4806-bcce-1ab15570742d	ea3eb759-6095-4565-98d0-0fd031f58fcb	anna.petrova	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:11.023358+03	\N
54dbbe89-6244-48e2-8443-80c94cb92376	0ad7b981-2af7-472f-99f9-69ce294b9abd	b.sidorov85	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:11.023358+03	\N
0fd25af5-6353-4b5d-9cf6-3a11d4658d55	fd592784-4d39-47d2-b247-a4a557add4d7	s.lebedev79	\N	49ee063a-69bf-48e3-9780-497ee08509c5	2026-06-07 18:44:11.023358+03	\N
ebca88fc-d8b1-4c2d-b9f0-0315be15bc71	314f1da4-b6ba-41a3-88f4-ffd61e8ba47f	a.mikhaylov	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:11.023358+03	\N
034052ce-abec-447a-a44b-bf2b6f61a63d	19980952-8d8b-4cc1-9358-72a785bd48e2	yuliya.fedorova85	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:11.023358+03	\N
79ffa9c0-a629-48a1-aa54-fc9a02926c0f	b1c3dde5-9ccc-4b5f-891c-57ebeece11c8	viktor.popov72	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:11.023358+03	\N
301e3f63-952a-48cc-ac36-bd628d092f5f	6e107408-70b2-4de9-8205-f5af46476a63	anna.kuznetsova93	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:10.944758+03	\N
d9d12e32-f1c2-4214-a130-e8504046f532	162f794a-bac5-490a-acf5-160eb22fa716	roman.zaitsev91	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:11.023358+03	\N
610edf3f-8503-4a20-b51b-b8f976dde0aa	cffa55ae-4de8-4c9a-b8be-9a55292fe7b1	belova_ks98	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:11.023358+03	\N
8a16e8ec-96b6-4243-bd80-929307cbf697	995c7b75-4104-41cc-8946-fe53c81de20c	k.tarasov70	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:10.912383+03	\N
63aa5644-857f-4cee-a682-0f67960dc3a0	9ea569e8-ea5b-40c1-99ca-ea03c68bbe4d	natasha.frolova91	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:11.023358+03	\N
4ec8e7fa-1513-4f08-8544-283adafabb80	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	v.bogdanov67	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:11.023358+03	\N
4a942433-6205-4288-a02c-f40920f2b605	65e1d23b-dfa8-44a3-bb40-15bee23ade75	diana.gorbunova	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:10.944758+03	\N
d759d5e4-c126-4710-be5e-b6ae958003f6	3fde298b-7536-4b09-a828-87223b009b1c	ion.popescu87	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:11.023358+03	\N
ebb3ff79-34e7-4e32-94fd-b75feec4b2c5	b4eaf12e-13a9-488c-81a9-460e39524950	ilya.chernov91	\N	ab572d97-4008-4b0e-9db6-72ec49ec2dcd	2026-06-07 18:44:10.944758+03	\N
\.


--
-- Data for Name: user_address; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.user_address (address_id, person_id, address_type_id, country_id, region_id, city_id, street_id, house, building, flat, postal_code, raw_address, is_default) FROM stdin;
12c5411d-2f28-4376-9a87-4554321abe84	995c7b75-4104-41cc-8946-fe53c81de20c	0a265f6c-c591-4eb1-9fde-860a04155761	010165a5-aaab-4238-a6e9-5fbde95618cd	ad792a09-9fa0-41c5-9ee4-18500d55ad9f	081bd21c-3e6e-4585-9111-a9567a72e75c	6c9b5a44-c861-4039-9110-604eff26f901	12	\N	45	125009	Москва, Тверская 12 кв 45, домофон не работает	t
2ada2f01-9401-4e11-aed0-186b27c1630c	ff58df0d-e9b5-44b3-9458-d3080031deff	0a265f6c-c591-4eb1-9fde-860a04155761	010165a5-aaab-4238-a6e9-5fbde95618cd	c7ffbf2a-d46e-4be3-8b53-e7b4a38c99c5	04f04aa1-c6e7-4875-b90b-afea53c6a2b3	37837cbd-a375-4afb-b2f9-6f6d0f80c655	7	2	101	\N	МО, г Химки, Молодежная 7к2, 101	f
7544ccda-33d2-4852-8440-f5e5d566ca15	abc36053-4caa-4234-b469-90c2f0ae43f1	0a265f6c-c591-4eb1-9fde-860a04155761	010165a5-aaab-4238-a6e9-5fbde95618cd	826af9bc-965f-4298-b190-8ec68de4d8c9	40841ce5-f1ee-4d73-a25a-abcb96b1e21e	59e75344-22b5-4049-b7d5-649fd0c04d43	1	\N	8	\N	СПб Невский 1-8	f
91335951-39ba-4d82-9e84-42d2a4bbb531	bcfa673e-ca8d-4c18-be68-e245f5375075	4953feab-0ee2-43a8-bd4a-e3f397a030d6	010165a5-aaab-4238-a6e9-5fbde95618cd	240a1287-8a6a-4eb0-b752-8caa317a20b5	5e6c532c-93ce-4e7f-8f63-9a130d27ab44	926994ea-17bd-4047-839c-6cd05010a38b	5	\N	12	420111	Казань, Баумана 5, квартира 12	f
d1e3c932-eb01-49a1-a234-a4e8f9c1c4f8	fe5d381f-5d02-421b-9cc6-e55541e56478	c2700f93-5dbf-4dee-b850-c482c21439aa	010165a5-aaab-4238-a6e9-5fbde95618cd	cc959383-0154-442e-8a25-b3978bff8ec8	4d8683e7-125a-4e47-b3ee-888c1861df80	1a079ef4-f6e9-4d7b-a5e1-929043ee29c2	30	\N	\N	\N	ПВЗ Новосибирск Красный 30	f
aad0c137-932a-4fcf-ba07-411917dc8a2f	d35af3e1-167d-4b2a-8075-b530012c5b63	0a265f6c-c591-4eb1-9fde-860a04155761	010165a5-aaab-4238-a6e9-5fbde95618cd	ad792a09-9fa0-41c5-9ee4-18500d55ad9f	081bd21c-3e6e-4585-9111-a9567a72e75c	7b3e3aab-7917-444f-a880-143d57d1a16c	10	\N	15	\N	Москва, Арбат 10 кв. 15	t
bdcccff4-d698-48da-b4e0-c78fdc271329	e629d14c-b866-487e-ab96-8b01ab7f2836	0a265f6c-c591-4eb1-9fde-860a04155761	010165a5-aaab-4238-a6e9-5fbde95618cd	c7ffbf2a-d46e-4be3-8b53-e7b4a38c99c5	e12269fd-28a5-48ad-ac83-a476c1f54a29	d892be9c-354c-47bf-943b-221efae1bc56	5	\N	7	\N	Подольск, Садовая 5 кв. 7	t
b315d7c6-f76e-4f2d-b462-392aefbdffc5	3345e1ce-1de2-4519-99a0-f585cab7398a	0a265f6c-c591-4eb1-9fde-860a04155761	010165a5-aaab-4238-a6e9-5fbde95618cd	826af9bc-965f-4298-b190-8ec68de4d8c9	40841ce5-f1ee-4d73-a25a-abcb96b1e21e	b4a1e5a6-c84b-462d-831d-bcb81066dca8	44	\N	21	\N	Санкт-Петербург, Литейный проспект 44 кв. 21	t
9af9e913-cc29-468d-82a8-2503d53aef63	dac44047-f9eb-4702-a9ed-1866a95da0c8	0a265f6c-c591-4eb1-9fde-860a04155761	010165a5-aaab-4238-a6e9-5fbde95618cd	240a1287-8a6a-4eb0-b752-8caa317a20b5	5e6c532c-93ce-4e7f-8f63-9a130d27ab44	15eb2230-ab04-444d-862c-f9c57e4f5906	2	\N	11	\N	Казань, Кремлевская 2 кв. 11	t
1d88c53a-45b3-48da-84da-0f57bb45d89d	c07e21b3-ddbb-4a10-b476-8a293fe4d8a3	0a265f6c-c591-4eb1-9fde-860a04155761	010165a5-aaab-4238-a6e9-5fbde95618cd	cc959383-0154-442e-8a25-b3978bff8ec8	4d8683e7-125a-4e47-b3ee-888c1861df80	aaaaedc6-55dc-4b37-8bf7-dca613fa25b7	7	\N	19	\N	Новосибирск, Карла Маркса 7 кв. 19	t
e5ab1df3-b525-4ee6-bab9-1e54ad8aa4ab	2fc7c4eb-10ae-4e45-ac36-265ed4cb5170	0a265f6c-c591-4eb1-9fde-860a04155761	010165a5-aaab-4238-a6e9-5fbde95618cd	ad792a09-9fa0-41c5-9ee4-18500d55ad9f	081bd21c-3e6e-4585-9111-a9567a72e75c	64a3d5f6-b094-427a-8207-3f8ca4aaa6db	88	\N	42	\N	Москва, Профсоюзная 88 кв. 42	t
1eb1ea10-b5b3-4c90-8187-b6bf3d3a80ea	d4ae4121-632e-43c8-8837-66eb636f1ef5	0a265f6c-c591-4eb1-9fde-860a04155761	010165a5-aaab-4238-a6e9-5fbde95618cd	f55682d9-aaf2-4622-b80f-bb6b299d9774	592103da-a24d-4735-9475-d9fe6e88dbd7	9fbb83a6-3e16-4f9e-b1e6-a3aa034b27bc	135	\N	3	\N	Краснодар, Красная 135 кв. 3	t
34278459-31ce-459c-b227-ba65ac189106	6de364c7-80e9-4f25-913c-0132beea6dd9	0a265f6c-c591-4eb1-9fde-860a04155761	010165a5-aaab-4238-a6e9-5fbde95618cd	9e2b94f7-5aaa-4845-b522-547a3718e5d1	38cd737f-86f9-4220-9c90-45bb90e2c98a	5b7d91e3-02e9-457f-b014-688ab364ee53	15	\N	304	\N	Ростов-На-Дону, Большая Садовая 15 кв. 304	t
9428e685-1035-40ad-85a4-a5a2e32aabfa	24705f4b-8062-4e79-b2e8-373f8919f2fa	0a265f6c-c591-4eb1-9fde-860a04155761	010165a5-aaab-4238-a6e9-5fbde95618cd	1a7ea4cb-b492-4664-8d56-1807a1885299	e0fd670b-7f13-4c25-a091-3b69b57eeeae	042ab31f-5a80-4747-a2b1-be4311865988	51	\N	79	\N	Екатеринбург, Малышева 51 кв. 79	t
7580ef33-50e5-43c1-8e16-f1c843c23b63	2fb47c36-e066-4314-be66-72a1e5ca8789	0a265f6c-c591-4eb1-9fde-860a04155761	010165a5-aaab-4238-a6e9-5fbde95618cd	826af9bc-965f-4298-b190-8ec68de4d8c9	40841ce5-f1ee-4d73-a25a-abcb96b1e21e	59e75344-22b5-4049-b7d5-649fd0c04d43	100	\N	200	\N	Санкт-Петербург, Невский проспект 100 кв. 200	t
30f3994e-b86b-404b-afca-41c5e57c532b	34e9b7f0-650b-4a39-b90a-547b4de07dc2	0a265f6c-c591-4eb1-9fde-860a04155761	010165a5-aaab-4238-a6e9-5fbde95618cd	ad792a09-9fa0-41c5-9ee4-18500d55ad9f	081bd21c-3e6e-4585-9111-a9567a72e75c	6c9b5a44-c861-4039-9110-604eff26f901	1	\N	8	\N	Москва, Тверская 1 кв. 8	t
a09f0c0f-0467-4875-b5e0-29f03333ec75	b545f08b-037e-4246-8c20-481f91097b7d	0a265f6c-c591-4eb1-9fde-860a04155761	010165a5-aaab-4238-a6e9-5fbde95618cd	c7ffbf2a-d46e-4be3-8b53-e7b4a38c99c5	04f04aa1-c6e7-4875-b90b-afea53c6a2b3	c0a28558-344b-4fa2-b5fe-253be1955c0c	78	\N	55	\N	Химки, Юбилейный проспект 78 кв. 55	t
2f6f3870-8247-42a4-a72e-1b5e56d8a4d4	4e69e1df-f2a3-4637-89be-ad45c0c37294	0a265f6c-c591-4eb1-9fde-860a04155761	010165a5-aaab-4238-a6e9-5fbde95618cd	ad792a09-9fa0-41c5-9ee4-18500d55ad9f	081bd21c-3e6e-4585-9111-a9567a72e75c	c94f1c1f-2598-42d3-a86c-2382672396c8	4	\N	\N	\N	Москва, Лесной пер. 4	t
040d1e4e-34e1-480f-a654-0d52bd7f1517	b4eaf12e-13a9-488c-81a9-460e39524950	0a265f6c-c591-4eb1-9fde-860a04155761	010165a5-aaab-4238-a6e9-5fbde95618cd	826af9bc-965f-4298-b190-8ec68de4d8c9	40841ce5-f1ee-4d73-a25a-abcb96b1e21e	ca22c7ca-6387-438d-9da5-7f936635eae1	41	\N	22	\N	Санкт-Петербург, Маршала Жукова 41 кв. 22	t
b901e478-e45a-463c-b227-486774e11aab	27c7b285-1b06-4e1b-854f-52acea9a3ad5	0a265f6c-c591-4eb1-9fde-860a04155761	010165a5-aaab-4238-a6e9-5fbde95618cd	ad792a09-9fa0-41c5-9ee4-18500d55ad9f	081bd21c-3e6e-4585-9111-a9567a72e75c	8012b294-4f49-4d7e-a143-0a1e0e21cdf0	9	\N	17	\N	Москва, Коньково 9 кв. 17	t
1df274b4-06f2-455d-835e-73fafdec657b	e3efa025-1091-4a9c-a6c8-4d2d50228fba	0a265f6c-c591-4eb1-9fde-860a04155761	010165a5-aaab-4238-a6e9-5fbde95618cd	ad792a09-9fa0-41c5-9ee4-18500d55ad9f	081bd21c-3e6e-4585-9111-a9567a72e75c	7efea53f-2bde-46c5-945d-aea0b7b5f258	4	\N	\N	\N	Москва, 4-й Лесной пер. 4	t
8840654f-55b9-4548-a402-0dc8f67d84e5	65e1d23b-dfa8-44a3-bb40-15bee23ade75	0a265f6c-c591-4eb1-9fde-860a04155761	010165a5-aaab-4238-a6e9-5fbde95618cd	f55682d9-aaf2-4622-b80f-bb6b299d9774	592103da-a24d-4735-9475-d9fe6e88dbd7	71cb9f52-01f2-4e48-9b96-6db212e65174	20	\N	2	\N	Краснодар, Северная 20 кв. 2	t
2d21440d-1932-44e4-84ae-3ef1fe31e2df	878871b9-bfcc-4946-baa0-4acf54f6c4b1	0a265f6c-c591-4eb1-9fde-860a04155761	010165a5-aaab-4238-a6e9-5fbde95618cd	9e2b94f7-5aaa-4845-b522-547a3718e5d1	38cd737f-86f9-4220-9c90-45bb90e2c98a	ae279e42-386d-4cc1-ba5f-ad0af1cec886	15	\N	304	\N	Ростов-На-Дону, Ленина 15 кв. 304	t
712c4904-10bb-4ea9-a380-8ebfa939b902	17155d97-bf5f-4e23-a0c5-d4e903c45d9a	0a265f6c-c591-4eb1-9fde-860a04155761	010165a5-aaab-4238-a6e9-5fbde95618cd	826af9bc-965f-4298-b190-8ec68de4d8c9	40841ce5-f1ee-4d73-a25a-abcb96b1e21e	e32a0ee4-7e38-40a3-8a78-864ee8607fd3	7	\N	14	\N	Санкт-Петербург, Кронверкский пр-т 7 кв. 14	t
abfa04ec-0937-4801-a1a9-a1ef465cb754	6e107408-70b2-4de9-8205-f5af46476a63	0a265f6c-c591-4eb1-9fde-860a04155761	010165a5-aaab-4238-a6e9-5fbde95618cd	ad792a09-9fa0-41c5-9ee4-18500d55ad9f	081bd21c-3e6e-4585-9111-a9567a72e75c	6c9b5a44-c861-4039-9110-604eff26f901	12	\N	45	\N	Москва, Тверская 12 кв. 45	t
eded4300-a3e2-426b-a097-3201c4abad71	06ac479a-edda-4596-9bb0-9deb06e869a8	0a265f6c-c591-4eb1-9fde-860a04155761	010165a5-aaab-4238-a6e9-5fbde95618cd	ad792a09-9fa0-41c5-9ee4-18500d55ad9f	081bd21c-3e6e-4585-9111-a9567a72e75c	10401bc2-2a35-4099-b7e0-773c8181a127	34	\N	128	115533	Каширское шоссе 34 кв. 128	t
98d06048-7744-435b-846f-af68eb6e1e92	ea3eb759-6095-4565-98d0-0fd031f58fcb	0a265f6c-c591-4eb1-9fde-860a04155761	010165a5-aaab-4238-a6e9-5fbde95618cd	826af9bc-965f-4298-b190-8ec68de4d8c9	40841ce5-f1ee-4d73-a25a-abcb96b1e21e	e0e79245-d43b-48b0-a778-2ddaf74e2913	7	\N	14	197101	Кронверкский пр-т, 7, кв.14	t
cf90d9f1-4040-41ae-b043-37758c78b3ca	0ad7b981-2af7-472f-99f9-69ce294b9abd	4953feab-0ee2-43a8-bd4a-e3f397a030d6	010165a5-aaab-4238-a6e9-5fbde95618cd	cc959383-0154-442e-8a25-b3978bff8ec8	4d8683e7-125a-4e47-b3ee-888c1861df80	e86de646-7ca3-49a1-97f6-b7fc870df877	26/5	\N	\N	630099	Красный проспект 26/5	t
ca5aaca4-1627-437e-9c6c-a26cc336ce08	0ad7b981-2af7-472f-99f9-69ce294b9abd	4953feab-0ee2-43a8-bd4a-e3f397a030d6	010165a5-aaab-4238-a6e9-5fbde95618cd	1a7ea4cb-b492-4664-8d56-1807a1885299	e0fd670b-7f13-4c25-a091-3b69b57eeeae	079ebb37-1efd-49c5-be2e-b7c72b209d1a	100	\N	55	620000	ул. Ленина 100, кв 55	t
4e5d9e32-57ff-4e1f-9392-663069128110	19980952-8d8b-4cc1-9358-72a785bd48e2	0a265f6c-c591-4eb1-9fde-860a04155761	010165a5-aaab-4238-a6e9-5fbde95618cd	ad792a09-9fa0-41c5-9ee4-18500d55ad9f	081bd21c-3e6e-4585-9111-a9567a72e75c	3431694f-84ba-4154-9fa7-8c8ffb367a31	10	\N	35	125009	ул. Пушкина д. 10 кв. 35	t
b89acdd9-6558-4f17-979c-33eef045980e	19980952-8d8b-4cc1-9358-72a785bd48e2	4953feab-0ee2-43a8-bd4a-e3f397a030d6	010165a5-aaab-4238-a6e9-5fbde95618cd	7b67ecf0-d2c9-4476-95fc-100a9ef0dd40	c27279e3-6d76-490b-b4c0-ce294a220034	d25e2705-00d9-4e82-8e06-7cac8f4b22a4	5	\N	\N	142100	Московская обл г Подольск ул Садовая 5	f
162144f1-8199-4f29-bd6d-fe2847d57f2d	fd592784-4d39-47d2-b247-a4a557add4d7	4953feab-0ee2-43a8-bd4a-e3f397a030d6	010165a5-aaab-4238-a6e9-5fbde95618cd	ad792a09-9fa0-41c5-9ee4-18500d55ad9f	081bd21c-3e6e-4585-9111-a9567a72e75c	073f7c9f-2f45-4df0-8edb-3566bea3fa88	55-А	\N	3	129085	пр. Мира 55-А кв.3	t
4726a372-00ea-4c69-b78f-8da60181198b	fd592784-4d39-47d2-b247-a4a557add4d7	4953feab-0ee2-43a8-bd4a-e3f397a030d6	010165a5-aaab-4238-a6e9-5fbde95618cd	826af9bc-965f-4298-b190-8ec68de4d8c9	40841ce5-f1ee-4d73-a25a-abcb96b1e21e	36b197a8-1318-4532-b4d9-362ab09d6eaa	100	\N	200	191025	Невский пр. 100 кв.200	t
7c10c10a-3987-4b73-9173-9e3cd46173f6	6e107408-70b2-4de9-8205-f5af46476a63	0a265f6c-c591-4eb1-9fde-860a04155761	010165a5-aaab-4238-a6e9-5fbde95618cd	ad792a09-9fa0-41c5-9ee4-18500d55ad9f	081bd21c-3e6e-4585-9111-a9567a72e75c	98ebbd59-ae7a-462b-a554-ca46a2ff1c6f	1	\N	\N	125009	Россия, г.Москва, ул.Тверская, дом 1	t
5a66b8ff-0279-4710-a058-815fc28e1f2f	19980952-8d8b-4cc1-9358-72a785bd48e2	0a265f6c-c591-4eb1-9fde-860a04155761	010165a5-aaab-4238-a6e9-5fbde95618cd	9e2b94f7-5aaa-4845-b522-547a3718e5d1	38cd737f-86f9-4220-9c90-45bb90e2c98a	a4cb1e22-4bc9-4996-bea8-edf80c8fc0db	15	\N	\N	344000	Пр. Ленина 15 оф. 304	t
8515a19d-a1b2-4525-b474-dce896a7fd06	b1c3dde5-9ccc-4b5f-891c-57ebeece11c8	4953feab-0ee2-43a8-bd4a-e3f397a030d6	010165a5-aaab-4238-a6e9-5fbde95618cd	1a7ea4cb-b492-4664-8d56-1807a1885299	e0fd670b-7f13-4c25-a091-3b69b57eeeae	c47dfe5e-059d-4626-a0cb-c1714169dbb6	620000	\N	\N	620000	Россия 620000 Свердл.обл г.Екб ул.Малышева 51-79	t
ba3b119f-79a2-4db1-a510-6bb55e1e2105	6e107408-70b2-4de9-8205-f5af46476a63	0a265f6c-c591-4eb1-9fde-860a04155761	010165a5-aaab-4238-a6e9-5fbde95618cd	ad792a09-9fa0-41c5-9ee4-18500d55ad9f	081bd21c-3e6e-4585-9111-a9567a72e75c	baef930d-7240-4c5e-af42-167c5a2316c6	5	\N	\N	125047	Москва ул.4-я Тверская-Ямская 5	t
1ab6f44f-3fc4-4e51-9012-39bb4e4d9fa9	162f794a-bac5-490a-acf5-160eb22fa716	4953feab-0ee2-43a8-bd4a-e3f397a030d6	010165a5-aaab-4238-a6e9-5fbde95618cd	240a1287-8a6a-4eb0-b752-8caa317a20b5	5e6c532c-93ce-4e7f-8f63-9a130d27ab44	c221f4af-2a56-4018-a32c-592d092698da	10	\N	\N	420000	Казань ул. Баумана 10	t
4fd0442d-0fd7-46d2-8004-5b10a39ecf89	cffa55ae-4de8-4c9a-b8be-9a55292fe7b1	0a265f6c-c591-4eb1-9fde-860a04155761	010165a5-aaab-4238-a6e9-5fbde95618cd	826af9bc-965f-4298-b190-8ec68de4d8c9	40841ce5-f1ee-4d73-a25a-abcb96b1e21e	ccaedd60-171d-48c3-963d-4cd30399e4e2	41	\N	22	198328	198328, г. Санкт-Петербург, ул. Маршала Жукова, д.41 к.1 кв.22	t
4a531363-2870-4e92-a815-618c80adbd12	995c7b75-4104-41cc-8946-fe53c81de20c	4953feab-0ee2-43a8-bd4a-e3f397a030d6	010165a5-aaab-4238-a6e9-5fbde95618cd	cc959383-0154-442e-8a25-b3978bff8ec8	4d8683e7-125a-4e47-b3ee-888c1861df80	052bd77b-5208-491a-b4ef-af759ccb844f	7	\N	19	630007	Новосибирск пр-т Карла Маркса 7 кв 19	t
3b6bd871-9fd3-4632-81de-cda424656989	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	0a265f6c-c591-4eb1-9fde-860a04155761	010165a5-aaab-4238-a6e9-5fbde95618cd	c7ffbf2a-d46e-4be3-8b53-e7b4a38c99c5	04f04aa1-c6e7-4875-b90b-afea53c6a2b3	408aeb01-4e24-4020-8893-dea35486d75a	78	\N	55	141400	МО, Химки, Юбилейный пр. 78, кв.55	t
0c055b88-cc88-439d-ad47-d66888bf387d	9ea569e8-ea5b-40c1-99ca-ea03c68bbe4d	4953feab-0ee2-43a8-bd4a-e3f397a030d6	010165a5-aaab-4238-a6e9-5fbde95618cd	f55682d9-aaf2-4622-b80f-bb6b299d9774	592103da-a24d-4735-9475-d9fe6e88dbd7	b78f81d2-e78a-43b2-be30-bba89e79cfeb	135	\N	\N	350000	Краснодар Красная 135	t
4b510bef-8eb0-4db7-9a21-33adabc1aeeb	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	4953feab-0ee2-43a8-bd4a-e3f397a030d6	010165a5-aaab-4238-a6e9-5fbde95618cd	ad792a09-9fa0-41c5-9ee4-18500d55ad9f	081bd21c-3e6e-4585-9111-a9567a72e75c	cd15a00b-4ab0-44b4-9bcc-1730f955c0a6	4-й	\N	\N	125047	г. Москва 4-й Лесной пер. 4	t
92256c35-3c81-4f9e-8dfb-69613df01858	b4eaf12e-13a9-488c-81a9-460e39524950	0a265f6c-c591-4eb1-9fde-860a04155761	010165a5-aaab-4238-a6e9-5fbde95618cd	826af9bc-965f-4298-b190-8ec68de4d8c9	40841ce5-f1ee-4d73-a25a-abcb96b1e21e	14232dff-f0d6-46c4-8834-424a76849104	44	\N	\N	191014	Санкт-Петербург Литейный проспект 44	t
\.


--
-- Data for Name: user_attribute_type; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.user_attribute_type (attribute_type_id, code, name, value_type, description) FROM stdin;
22d0c615-7592-4b40-bdca-7f5a99742f9a	FAVORITE_TECH_CATEGORY	Любимая категория техники	text	Например смартфоны, ноутбуки, умный дом
f3fb8b42-e703-4c79-9b5c-76ef28601e3a	PREFERRED_BRAND	Предпочитаемый бренд	text	Маркетинговое предпочтение покупателя
25874ea2-ded6-41ed-a291-64932c16b6b2	INSTALLMENT_INTEREST	Интерес к рассрочке	bool	Покупатель интересуется рассрочкой
35469795-ba78-4824-90fe-9a3efcd6ad74	AVG_ORDER_BUDGET	Средний бюджет заказа	number	Примерный бюджет покупки техники
f2f24f03-8280-498f-b67e-82acda6f94d0	HAS_SMART_HOME	Есть устройства умного дома	bool	Гибкий признак покупателя техники
37e9c6fb-b79a-4d2c-85f7-c9e6dad3d685	DEVICE_ECOSYSTEM	Экосистема устройств	text	Apple, Android, Windows, mixed
bfbad852-bfb6-4d57-ba5a-d2c7e1e71365	LOYALTY_LEVEL	Уровень лояльности	text	basic, silver, gold
7d98e244-abb0-47b0-8a44-8e14b9d17efd	BIOMETRIC_FACE_REF	Ссылка на биометрический шаблон лица	text	Опциональная ссылка на внешний биометрический шаблон
\.


--
-- Data for Name: user_attribute_value; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.user_attribute_value (attribute_value_id, person_id, attribute_type_id, value_text, value_number, value_date, value_bool, value_json, raw_value) FROM stdin;
85432075-a356-44a1-bf2b-1a2dfce11c8d	995c7b75-4104-41cc-8946-fe53c81de20c	bfbad852-bfb6-4d57-ba5a-d2c7e1e71365	gold	\N	\N	\N	\N	"gold"
9a4c892e-83d7-4aea-a5aa-865fd179ccab	995c7b75-4104-41cc-8946-fe53c81de20c	f2f24f03-8280-498f-b67e-82acda6f94d0	\N	\N	\N	t	\N	true
773643a9-7bf4-4b45-a752-bba6c6632fab	995c7b75-4104-41cc-8946-fe53c81de20c	35469795-ba78-4824-90fe-9a3efcd6ad74	\N	65000	\N	\N	\N	65000
e9417716-ec07-48f3-9b92-f9045778479b	995c7b75-4104-41cc-8946-fe53c81de20c	37e9c6fb-b79a-4d2c-85f7-c9e6dad3d685	Android	\N	\N	\N	\N	"Android"
25f7d1cd-3665-4156-8082-97abd0a05f03	995c7b75-4104-41cc-8946-fe53c81de20c	25874ea2-ded6-41ed-a291-64932c16b6b2	\N	\N	\N	t	\N	true
f19e64ad-74bb-4336-b86c-d0fd773d1a34	995c7b75-4104-41cc-8946-fe53c81de20c	22d0c615-7592-4b40-bdca-7f5a99742f9a	смартфоны	\N	\N	\N	\N	"смартфоны"
1831bed2-be37-474d-96f3-bfbdcdbb0870	ff58df0d-e9b5-44b3-9458-d3080031deff	bfbad852-bfb6-4d57-ba5a-d2c7e1e71365	silver	\N	\N	\N	\N	"silver"
64f0168c-244b-4113-a9a2-fac4f412bb62	ff58df0d-e9b5-44b3-9458-d3080031deff	f3fb8b42-e703-4c79-9b5c-76ef28601e3a	Apple	\N	\N	\N	\N	"Apple"
5653a189-805b-4ac2-8ff6-51f55283eb85	ff58df0d-e9b5-44b3-9458-d3080031deff	35469795-ba78-4824-90fe-9a3efcd6ad74	\N	120000	\N	\N	\N	120000
93069620-1c76-42f5-921c-57d68134520e	ff58df0d-e9b5-44b3-9458-d3080031deff	37e9c6fb-b79a-4d2c-85f7-c9e6dad3d685	Apple	\N	\N	\N	\N	"Apple"
712cb3de-2aaa-4671-a75b-f022af8c51d3	ff58df0d-e9b5-44b3-9458-d3080031deff	25874ea2-ded6-41ed-a291-64932c16b6b2	\N	\N	\N	f	\N	false
12c24b37-cbf4-491a-bc35-617e7265dd75	ff58df0d-e9b5-44b3-9458-d3080031deff	22d0c615-7592-4b40-bdca-7f5a99742f9a	ноутбуки	\N	\N	\N	\N	"ноутбуки"
57e0f9b9-b1d3-49ff-bee6-44a928906b48	abc36053-4caa-4234-b469-90c2f0ae43f1	bfbad852-bfb6-4d57-ba5a-d2c7e1e71365	basic	\N	\N	\N	\N	"basic"
8d0b8c95-0d1d-4fb8-8e36-4e76d0ed5725	abc36053-4caa-4234-b469-90c2f0ae43f1	f2f24f03-8280-498f-b67e-82acda6f94d0	\N	\N	\N	f	\N	false
ba6085d4-8e92-4653-b611-80573eefa612	abc36053-4caa-4234-b469-90c2f0ae43f1	f3fb8b42-e703-4c79-9b5c-76ef28601e3a	Sony	\N	\N	\N	\N	"Sony"
a0154429-c874-415a-a9d3-71b2ad69cf3a	abc36053-4caa-4234-b469-90c2f0ae43f1	35469795-ba78-4824-90fe-9a3efcd6ad74	\N	80000	\N	\N	\N	80000
5af690ff-5b7a-44ee-9266-78f8f2403bf1	abc36053-4caa-4234-b469-90c2f0ae43f1	25874ea2-ded6-41ed-a291-64932c16b6b2	\N	\N	\N	t	\N	true
ce638360-eb9d-4624-be16-c47b1128beba	abc36053-4caa-4234-b469-90c2f0ae43f1	22d0c615-7592-4b40-bdca-7f5a99742f9a	игровые консоли	\N	\N	\N	\N	"игровые консоли"
157a9c9d-9e07-4407-86a6-cb7d51b27b1f	bcfa673e-ca8d-4c18-be68-e245f5375075	f2f24f03-8280-498f-b67e-82acda6f94d0	\N	\N	\N	t	\N	true
9ac665a8-de43-43fd-a1fe-c6f74f2baeb4	bcfa673e-ca8d-4c18-be68-e245f5375075	f3fb8b42-e703-4c79-9b5c-76ef28601e3a	Xiaomi	\N	\N	\N	\N	"Xiaomi"
ddbfaffc-f816-4b75-affa-9824f8a95f1d	bcfa673e-ca8d-4c18-be68-e245f5375075	35469795-ba78-4824-90fe-9a3efcd6ad74	\N	30000	\N	\N	\N	30000
dbc6e5b7-eda7-46ac-ab96-854aa1d076e9	bcfa673e-ca8d-4c18-be68-e245f5375075	37e9c6fb-b79a-4d2c-85f7-c9e6dad3d685	mixed	\N	\N	\N	\N	"mixed"
5ed0c81d-0168-43bd-87e3-2ae8ccc9a32e	bcfa673e-ca8d-4c18-be68-e245f5375075	7d98e244-abb0-47b0-8a44-8e14b9d17efd	face-template://legacy/4451	\N	\N	\N	\N	"face-template://legacy/4451"
7b8eddb8-3aa4-4590-98ba-37c1b243b4d0	bcfa673e-ca8d-4c18-be68-e245f5375075	25874ea2-ded6-41ed-a291-64932c16b6b2	\N	\N	\N	t	\N	true
3ddcd728-7ade-4017-9dc7-391261b7c341	bcfa673e-ca8d-4c18-be68-e245f5375075	22d0c615-7592-4b40-bdca-7f5a99742f9a	умный дом	\N	\N	\N	\N	"умный дом"
04abcaa5-6b95-4e66-bc9e-43612ed41f16	fe5d381f-5d02-421b-9cc6-e55541e56478	bfbad852-bfb6-4d57-ba5a-d2c7e1e71365	basic	\N	\N	\N	\N	"basic"
0731ed1f-d82b-4e52-83ce-63a8dc62d59a	fe5d381f-5d02-421b-9cc6-e55541e56478	f3fb8b42-e703-4c79-9b5c-76ef28601e3a	AMD	\N	\N	\N	\N	"AMD"
e066ffb2-6a22-473b-b7d3-a97086e1c256	fe5d381f-5d02-421b-9cc6-e55541e56478	35469795-ba78-4824-90fe-9a3efcd6ad74	\N	45000	\N	\N	\N	45000
7d98c2d8-551c-4b98-8403-3dfb242dc7e6	fe5d381f-5d02-421b-9cc6-e55541e56478	25874ea2-ded6-41ed-a291-64932c16b6b2	\N	\N	\N	f	\N	false
3136e09c-33e8-4b6c-be48-6a55913809e4	fe5d381f-5d02-421b-9cc6-e55541e56478	22d0c615-7592-4b40-bdca-7f5a99742f9a	комплектующие	\N	\N	\N	\N	"комплектующие"
6831cdc9-d3b7-43a7-8828-2a27b71feea4	d35af3e1-167d-4b2a-8075-b530012c5b63	bfbad852-bfb6-4d57-ba5a-d2c7e1e71365	gold	\N	\N	\N	\N	"gold"
961c7583-728b-4065-a803-76d83c1ea624	d35af3e1-167d-4b2a-8075-b530012c5b63	f3fb8b42-e703-4c79-9b5c-76ef28601e3a	Lenovo	\N	\N	\N	\N	"Lenovo"
201da6b6-2d12-4188-a98e-fbfd017c1e36	d35af3e1-167d-4b2a-8075-b530012c5b63	35469795-ba78-4824-90fe-9a3efcd6ad74	\N	90000	\N	\N	\N	90000
589dc272-28f1-4167-a429-a6b017763d3d	d35af3e1-167d-4b2a-8075-b530012c5b63	25874ea2-ded6-41ed-a291-64932c16b6b2	\N	\N	\N	t	\N	true
c92d004c-778b-4592-8754-2435afa831bc	d35af3e1-167d-4b2a-8075-b530012c5b63	22d0c615-7592-4b40-bdca-7f5a99742f9a	ноутбуки	\N	\N	\N	\N	"ноутбуки"
641db6af-2fb7-4748-bd24-dbb08e0cf4de	e629d14c-b866-487e-ab96-8b01ab7f2836	bfbad852-bfb6-4d57-ba5a-d2c7e1e71365	gold	\N	\N	\N	\N	"gold"
3ed789b4-5e21-40ed-aed8-d1ca270eb61d	e629d14c-b866-487e-ab96-8b01ab7f2836	f3fb8b42-e703-4c79-9b5c-76ef28601e3a	Apple	\N	\N	\N	\N	"Apple"
140c1d0f-1151-4411-ab2b-ec23c908cd27	e629d14c-b866-487e-ab96-8b01ab7f2836	35469795-ba78-4824-90fe-9a3efcd6ad74	\N	110000	\N	\N	\N	110000
d21f7e8a-ef3b-4304-8c51-222a4964a35a	e629d14c-b866-487e-ab96-8b01ab7f2836	25874ea2-ded6-41ed-a291-64932c16b6b2	\N	\N	\N	f	\N	false
46923b9d-d3c4-4846-a2e5-4883662817aa	e629d14c-b866-487e-ab96-8b01ab7f2836	22d0c615-7592-4b40-bdca-7f5a99742f9a	смартфоны	\N	\N	\N	\N	"смартфоны"
87423982-0601-43d4-8d19-1cf427edfa24	3345e1ce-1de2-4519-99a0-f585cab7398a	bfbad852-bfb6-4d57-ba5a-d2c7e1e71365	silver	\N	\N	\N	\N	"silver"
1fb6bbd6-6d3d-49ed-ab50-59b71a53ddfd	3345e1ce-1de2-4519-99a0-f585cab7398a	f3fb8b42-e703-4c79-9b5c-76ef28601e3a	LG	\N	\N	\N	\N	"LG"
2dbc1c1c-bd0c-47fe-b524-2dc86a50fba6	3345e1ce-1de2-4519-99a0-f585cab7398a	35469795-ba78-4824-90fe-9a3efcd6ad74	\N	70000	\N	\N	\N	70000
6dc680af-819e-47aa-a953-c31abcc65fe4	3345e1ce-1de2-4519-99a0-f585cab7398a	25874ea2-ded6-41ed-a291-64932c16b6b2	\N	\N	\N	t	\N	true
3edef446-2f6e-48ab-a76f-3b2b5ea4b05e	3345e1ce-1de2-4519-99a0-f585cab7398a	22d0c615-7592-4b40-bdca-7f5a99742f9a	телевизоры	\N	\N	\N	\N	"телевизоры"
a4270b0e-37f7-4554-8b87-706f325bfd71	dac44047-f9eb-4702-a9ed-1866a95da0c8	bfbad852-bfb6-4d57-ba5a-d2c7e1e71365	basic	\N	\N	\N	\N	"basic"
4d49f738-be0c-4737-a2f1-7cb7e2b61a3f	dac44047-f9eb-4702-a9ed-1866a95da0c8	f3fb8b42-e703-4c79-9b5c-76ef28601e3a	Xiaomi	\N	\N	\N	\N	"Xiaomi"
5adbf502-46af-4d36-9d4a-04a2610405a2	dac44047-f9eb-4702-a9ed-1866a95da0c8	35469795-ba78-4824-90fe-9a3efcd6ad74	\N	35000	\N	\N	\N	35000
41c4f04e-7b33-431d-b649-f9d70b5d377a	dac44047-f9eb-4702-a9ed-1866a95da0c8	25874ea2-ded6-41ed-a291-64932c16b6b2	\N	\N	\N	t	\N	true
693eefda-b60a-4781-9bd3-039921d4c65b	dac44047-f9eb-4702-a9ed-1866a95da0c8	22d0c615-7592-4b40-bdca-7f5a99742f9a	умный дом	\N	\N	\N	\N	"умный дом"
480f8eaf-1908-4bb5-9210-6962d5a5223e	c07e21b3-ddbb-4a10-b476-8a293fe4d8a3	bfbad852-bfb6-4d57-ba5a-d2c7e1e71365	silver	\N	\N	\N	\N	"silver"
3925140f-b1c6-4e2e-b952-951d4ade4fd5	c07e21b3-ddbb-4a10-b476-8a293fe4d8a3	f3fb8b42-e703-4c79-9b5c-76ef28601e3a	AMD	\N	\N	\N	\N	"AMD"
ef4b10d3-aa11-41ec-9401-c479998b25bc	c07e21b3-ddbb-4a10-b476-8a293fe4d8a3	35469795-ba78-4824-90fe-9a3efcd6ad74	\N	55000	\N	\N	\N	55000
8df376e1-54e0-4a48-bb55-7cc4e738dcee	c07e21b3-ddbb-4a10-b476-8a293fe4d8a3	25874ea2-ded6-41ed-a291-64932c16b6b2	\N	\N	\N	f	\N	false
76ec972a-9e9b-419f-ac4b-7bdbfab9bbea	c07e21b3-ddbb-4a10-b476-8a293fe4d8a3	22d0c615-7592-4b40-bdca-7f5a99742f9a	комплектующие	\N	\N	\N	\N	"комплектующие"
0912e03a-d01d-4059-9c67-e2a44704c2d7	2fc7c4eb-10ae-4e45-ac36-265ed4cb5170	bfbad852-bfb6-4d57-ba5a-d2c7e1e71365	silver	\N	\N	\N	\N	"silver"
fa8607b0-e52d-476d-a29d-a1ae3fe3e99f	2fc7c4eb-10ae-4e45-ac36-265ed4cb5170	f3fb8b42-e703-4c79-9b5c-76ef28601e3a	Samsung	\N	\N	\N	\N	"Samsung"
7e0a9b99-cf3b-44d0-8f83-c19e62df0eb2	2fc7c4eb-10ae-4e45-ac36-265ed4cb5170	35469795-ba78-4824-90fe-9a3efcd6ad74	\N	50000	\N	\N	\N	50000
b9a38d1f-b46e-481a-8c16-becfccd4ad4c	2fc7c4eb-10ae-4e45-ac36-265ed4cb5170	25874ea2-ded6-41ed-a291-64932c16b6b2	\N	\N	\N	t	\N	true
a248579c-2b49-4e44-9800-c169be826d8d	2fc7c4eb-10ae-4e45-ac36-265ed4cb5170	22d0c615-7592-4b40-bdca-7f5a99742f9a	планшеты	\N	\N	\N	\N	"планшеты"
2d7db974-9615-43b6-8cd4-5366f1edba75	d4ae4121-632e-43c8-8837-66eb636f1ef5	bfbad852-bfb6-4d57-ba5a-d2c7e1e71365	silver	\N	\N	\N	\N	"silver"
87a3d928-3d77-4328-a7b5-057900c02c3d	d4ae4121-632e-43c8-8837-66eb636f1ef5	f3fb8b42-e703-4c79-9b5c-76ef28601e3a	Sony	\N	\N	\N	\N	"Sony"
aa76b32f-e275-48c3-b52e-62c9b01d9bfe	d4ae4121-632e-43c8-8837-66eb636f1ef5	35469795-ba78-4824-90fe-9a3efcd6ad74	\N	78000	\N	\N	\N	78000
bc6df19b-2731-4988-beba-0b54c864e0bd	d4ae4121-632e-43c8-8837-66eb636f1ef5	25874ea2-ded6-41ed-a291-64932c16b6b2	\N	\N	\N	t	\N	true
5f592fb4-45ca-49e8-a685-c7bc4479eaa3	d4ae4121-632e-43c8-8837-66eb636f1ef5	22d0c615-7592-4b40-bdca-7f5a99742f9a	игровые консоли	\N	\N	\N	\N	"игровые консоли"
ce5d2bf3-6353-476e-b0ff-92ff987dcf89	6de364c7-80e9-4f25-913c-0132beea6dd9	bfbad852-bfb6-4d57-ba5a-d2c7e1e71365	silver	\N	\N	\N	\N	"silver"
a9c5cee7-4a3d-4a01-9f35-8ac0d5353380	6de364c7-80e9-4f25-913c-0132beea6dd9	f3fb8b42-e703-4c79-9b5c-76ef28601e3a	Canon	\N	\N	\N	\N	"Canon"
89a2ddee-8f2c-4e04-bd3b-a8a51e92c70d	6de364c7-80e9-4f25-913c-0132beea6dd9	35469795-ba78-4824-90fe-9a3efcd6ad74	\N	65000	\N	\N	\N	65000
70dcbc30-886f-45d3-8c0d-ac5aa7cd8c5a	6de364c7-80e9-4f25-913c-0132beea6dd9	25874ea2-ded6-41ed-a291-64932c16b6b2	\N	\N	\N	f	\N	false
47b865c8-3dd5-495e-b225-0e6b7d540fa5	6de364c7-80e9-4f25-913c-0132beea6dd9	22d0c615-7592-4b40-bdca-7f5a99742f9a	фото	\N	\N	\N	\N	"фото"
76b09b47-6765-4647-bf75-90b44c2463f0	24705f4b-8062-4e79-b2e8-373f8919f2fa	bfbad852-bfb6-4d57-ba5a-d2c7e1e71365	silver	\N	\N	\N	\N	"silver"
77e10242-462c-4e29-92a9-2176cf157326	24705f4b-8062-4e79-b2e8-373f8919f2fa	f3fb8b42-e703-4c79-9b5c-76ef28601e3a	HP	\N	\N	\N	\N	"HP"
0398395b-c401-464c-8c0b-e2eb85a9071b	24705f4b-8062-4e79-b2e8-373f8919f2fa	35469795-ba78-4824-90fe-9a3efcd6ad74	\N	60000	\N	\N	\N	60000
23fd93d1-fef2-4afc-b3de-59c51b965dc7	24705f4b-8062-4e79-b2e8-373f8919f2fa	25874ea2-ded6-41ed-a291-64932c16b6b2	\N	\N	\N	f	\N	false
d60908f3-231b-440b-a501-69e1bb24d001	24705f4b-8062-4e79-b2e8-373f8919f2fa	22d0c615-7592-4b40-bdca-7f5a99742f9a	ноутбуки	\N	\N	\N	\N	"ноутбуки"
d0330a8a-91ea-4033-8042-247d13ca971f	2fb47c36-e066-4314-be66-72a1e5ca8789	bfbad852-bfb6-4d57-ba5a-d2c7e1e71365	basic	\N	\N	\N	\N	"basic"
c43218c7-aa8b-43f4-9b30-90379334b8c7	2fb47c36-e066-4314-be66-72a1e5ca8789	f3fb8b42-e703-4c79-9b5c-76ef28601e3a	Huawei	\N	\N	\N	\N	"Huawei"
2b94bf93-6ca6-4778-a51e-243c09752bbc	2fb47c36-e066-4314-be66-72a1e5ca8789	35469795-ba78-4824-90fe-9a3efcd6ad74	\N	42000	\N	\N	\N	42000
7f9cef22-4d13-4ec1-80ae-5414ddd35c33	2fb47c36-e066-4314-be66-72a1e5ca8789	25874ea2-ded6-41ed-a291-64932c16b6b2	\N	\N	\N	t	\N	true
932e6ba8-9463-4d30-8b08-a000bd0a8fd9	2fb47c36-e066-4314-be66-72a1e5ca8789	22d0c615-7592-4b40-bdca-7f5a99742f9a	смартфоны	\N	\N	\N	\N	"смартфоны"
5544f7f8-3360-4c47-9123-a71102fa2035	34e9b7f0-650b-4a39-b90a-547b4de07dc2	bfbad852-bfb6-4d57-ba5a-d2c7e1e71365	basic	\N	\N	\N	\N	"basic"
661de359-3812-4a4b-b207-889437886631	34e9b7f0-650b-4a39-b90a-547b4de07dc2	f3fb8b42-e703-4c79-9b5c-76ef28601e3a	Sony	\N	\N	\N	\N	"Sony"
e8adf870-2d18-4e7a-b481-f9e3912eeee2	34e9b7f0-650b-4a39-b90a-547b4de07dc2	35469795-ba78-4824-90fe-9a3efcd6ad74	\N	22000	\N	\N	\N	22000
24ecd81d-c5c1-4127-814d-3a92e5c5970b	34e9b7f0-650b-4a39-b90a-547b4de07dc2	25874ea2-ded6-41ed-a291-64932c16b6b2	\N	\N	\N	f	\N	false
f0903f13-7fc9-4fc5-a1ef-8707b8fb67e0	34e9b7f0-650b-4a39-b90a-547b4de07dc2	22d0c615-7592-4b40-bdca-7f5a99742f9a	наушники	\N	\N	\N	\N	"наушники"
bc624a0a-7aa7-4ce7-b00b-357769ff0972	b545f08b-037e-4246-8c20-481f91097b7d	bfbad852-bfb6-4d57-ba5a-d2c7e1e71365	basic	\N	\N	\N	\N	"basic"
db26e513-fee7-4feb-9678-72018374ef31	b545f08b-037e-4246-8c20-481f91097b7d	f3fb8b42-e703-4c79-9b5c-76ef28601e3a	Aqara	\N	\N	\N	\N	"Aqara"
6d321029-4bfd-484f-830f-63b101bc6f71	b545f08b-037e-4246-8c20-481f91097b7d	35469795-ba78-4824-90fe-9a3efcd6ad74	\N	28000	\N	\N	\N	28000
ff0cc7fa-f6a7-43aa-98aa-9e89d507c8cf	b545f08b-037e-4246-8c20-481f91097b7d	25874ea2-ded6-41ed-a291-64932c16b6b2	\N	\N	\N	t	\N	true
0db4f8f5-559f-4f20-b036-20ba21f16d24	b545f08b-037e-4246-8c20-481f91097b7d	22d0c615-7592-4b40-bdca-7f5a99742f9a	умный дом	\N	\N	\N	\N	"умный дом"
0444d2d6-6b83-4e18-a14b-da5b82ec7459	4e69e1df-f2a3-4637-89be-ad45c0c37294	bfbad852-bfb6-4d57-ba5a-d2c7e1e71365	basic	\N	\N	\N	\N	"basic"
6c0e20ea-7386-4ee7-a8bb-4d5f7ece252b	4e69e1df-f2a3-4637-89be-ad45c0c37294	f3fb8b42-e703-4c79-9b5c-76ef28601e3a	Intel	\N	\N	\N	\N	"Intel"
32676bfa-51bb-4f28-98a4-85c800235041	4e69e1df-f2a3-4637-89be-ad45c0c37294	35469795-ba78-4824-90fe-9a3efcd6ad74	\N	47000	\N	\N	\N	47000
d445a3dc-2eb0-44ba-8d3e-eeac14f7b56d	4e69e1df-f2a3-4637-89be-ad45c0c37294	25874ea2-ded6-41ed-a291-64932c16b6b2	\N	\N	\N	f	\N	false
2ad56051-5099-44e5-9789-c57954a767a4	4e69e1df-f2a3-4637-89be-ad45c0c37294	22d0c615-7592-4b40-bdca-7f5a99742f9a	комплектующие	\N	\N	\N	\N	"комплектующие"
ce89de6e-988b-45d4-b371-67a4f94a94f2	b4eaf12e-13a9-488c-81a9-460e39524950	bfbad852-bfb6-4d57-ba5a-d2c7e1e71365	silver	\N	\N	\N	\N	"silver"
ea8876d3-1bc8-460a-b7b0-af2bfda094f9	b4eaf12e-13a9-488c-81a9-460e39524950	f3fb8b42-e703-4c79-9b5c-76ef28601e3a	Bosch	\N	\N	\N	\N	"Bosch"
4890f150-1766-42ce-bfeb-f14b5fdf98c0	b4eaf12e-13a9-488c-81a9-460e39524950	35469795-ba78-4824-90fe-9a3efcd6ad74	\N	52000	\N	\N	\N	52000
0d3c5c6d-a857-4199-9653-42eebe1302c5	b4eaf12e-13a9-488c-81a9-460e39524950	25874ea2-ded6-41ed-a291-64932c16b6b2	\N	\N	\N	t	\N	true
a09a023a-17d5-4a9b-9e81-568cc062bdce	b4eaf12e-13a9-488c-81a9-460e39524950	22d0c615-7592-4b40-bdca-7f5a99742f9a	бытовая техника	\N	\N	\N	\N	"бытовая техника"
d1f0038c-5e20-4b83-9147-c102ff8c4d69	27c7b285-1b06-4e1b-854f-52acea9a3ad5	bfbad852-bfb6-4d57-ba5a-d2c7e1e71365	basic	\N	\N	\N	\N	"basic"
099fbca2-30ea-4e7e-8b2b-7d867e594b36	27c7b285-1b06-4e1b-854f-52acea9a3ad5	f3fb8b42-e703-4c79-9b5c-76ef28601e3a	TCL	\N	\N	\N	\N	"TCL"
0da62a28-23d0-4fc1-9863-6a07ec981a44	27c7b285-1b06-4e1b-854f-52acea9a3ad5	35469795-ba78-4824-90fe-9a3efcd6ad74	\N	33000	\N	\N	\N	33000
8f8f704e-426b-461d-87b7-e344d0e47587	27c7b285-1b06-4e1b-854f-52acea9a3ad5	25874ea2-ded6-41ed-a291-64932c16b6b2	\N	\N	\N	f	\N	false
73943aff-6925-4c7a-932c-bda02396d84b	27c7b285-1b06-4e1b-854f-52acea9a3ad5	22d0c615-7592-4b40-bdca-7f5a99742f9a	телевизоры	\N	\N	\N	\N	"телевизоры"
23065802-55d9-4dc7-918e-1c455e4bffea	e3efa025-1091-4a9c-a6c8-4d2d50228fba	bfbad852-bfb6-4d57-ba5a-d2c7e1e71365	basic	\N	\N	\N	\N	"basic"
2de41a67-dc1b-4726-8804-fe6894aebada	e3efa025-1091-4a9c-a6c8-4d2d50228fba	f3fb8b42-e703-4c79-9b5c-76ef28601e3a	Xiaomi	\N	\N	\N	\N	"Xiaomi"
1f8781eb-e3d3-4e16-8fc9-dea40306480a	e3efa025-1091-4a9c-a6c8-4d2d50228fba	35469795-ba78-4824-90fe-9a3efcd6ad74	\N	39000	\N	\N	\N	39000
28dbccdc-90d5-419a-b79e-8cb5b8a84679	e3efa025-1091-4a9c-a6c8-4d2d50228fba	25874ea2-ded6-41ed-a291-64932c16b6b2	\N	\N	\N	t	\N	true
ee5c9cf5-290d-4340-aa3a-5fcee6b80d42	e3efa025-1091-4a9c-a6c8-4d2d50228fba	22d0c615-7592-4b40-bdca-7f5a99742f9a	смартфоны	\N	\N	\N	\N	"смартфоны"
51765ed8-871a-4a58-9fb2-85d90ccfa92d	65e1d23b-dfa8-44a3-bb40-15bee23ade75	bfbad852-bfb6-4d57-ba5a-d2c7e1e71365	gold	\N	\N	\N	\N	"gold"
82970e43-01ec-4982-a8da-a00301076910	65e1d23b-dfa8-44a3-bb40-15bee23ade75	f3fb8b42-e703-4c79-9b5c-76ef28601e3a	Microsoft	\N	\N	\N	\N	"Microsoft"
688b1c6c-c0a0-4d17-abcb-57e4ce3b3937	65e1d23b-dfa8-44a3-bb40-15bee23ade75	35469795-ba78-4824-90fe-9a3efcd6ad74	\N	85000	\N	\N	\N	85000
dd6b6e32-307f-4d4f-a597-3bb1fa31b142	65e1d23b-dfa8-44a3-bb40-15bee23ade75	25874ea2-ded6-41ed-a291-64932c16b6b2	\N	\N	\N	t	\N	true
fa805bd0-2057-4557-9b58-685d75abbb43	65e1d23b-dfa8-44a3-bb40-15bee23ade75	22d0c615-7592-4b40-bdca-7f5a99742f9a	игровые консоли	\N	\N	\N	\N	"игровые консоли"
9430e2f5-9669-4d56-ba5f-1de6fc87c609	878871b9-bfcc-4946-baa0-4acf54f6c4b1	bfbad852-bfb6-4d57-ba5a-d2c7e1e71365	gold	\N	\N	\N	\N	"gold"
8f334ab8-743f-4341-85a9-b0e37a706022	878871b9-bfcc-4946-baa0-4acf54f6c4b1	f3fb8b42-e703-4c79-9b5c-76ef28601e3a	Asus	\N	\N	\N	\N	"Asus"
9124d120-cf1f-48cd-945d-f29c294d85dd	878871b9-bfcc-4946-baa0-4acf54f6c4b1	35469795-ba78-4824-90fe-9a3efcd6ad74	\N	95000	\N	\N	\N	95000
516f2527-193a-4c9d-adf2-0546d6d90657	878871b9-bfcc-4946-baa0-4acf54f6c4b1	25874ea2-ded6-41ed-a291-64932c16b6b2	\N	\N	\N	f	\N	false
c2a08878-ef8b-4264-a3c0-98c4892e8708	878871b9-bfcc-4946-baa0-4acf54f6c4b1	22d0c615-7592-4b40-bdca-7f5a99742f9a	ноутбуки	\N	\N	\N	\N	"ноутбуки"
392e4a74-9426-4ac1-8795-3a7f3c32b860	17155d97-bf5f-4e23-a0c5-d4e903c45d9a	bfbad852-bfb6-4d57-ba5a-d2c7e1e71365	silver	\N	\N	\N	\N	"silver"
0f84c1e9-0256-4188-8568-983eaa2976d7	17155d97-bf5f-4e23-a0c5-d4e903c45d9a	f3fb8b42-e703-4c79-9b5c-76ef28601e3a	Nikon	\N	\N	\N	\N	"Nikon"
163d88f1-b675-4648-baec-48909539757f	17155d97-bf5f-4e23-a0c5-d4e903c45d9a	35469795-ba78-4824-90fe-9a3efcd6ad74	\N	73000	\N	\N	\N	73000
0e1ed5c2-758d-4f5b-9aa9-ad1ca6050240	17155d97-bf5f-4e23-a0c5-d4e903c45d9a	25874ea2-ded6-41ed-a291-64932c16b6b2	\N	\N	\N	t	\N	true
ab471500-b489-4bdb-b773-a3bc1646eb82	17155d97-bf5f-4e23-a0c5-d4e903c45d9a	22d0c615-7592-4b40-bdca-7f5a99742f9a	фото	\N	\N	\N	\N	"фото"
1c0a79bb-2afd-444c-9eab-378205e23439	6e107408-70b2-4de9-8205-f5af46476a63	bfbad852-bfb6-4d57-ba5a-d2c7e1e71365	basic	\N	\N	\N	\N	"basic"
1b42fa47-444a-4110-8301-cd813a5c5d31	6e107408-70b2-4de9-8205-f5af46476a63	35469795-ba78-4824-90fe-9a3efcd6ad74	\N	25000	\N	\N	\N	25000
65fb9042-f594-4659-ba85-e606794d1805	6e107408-70b2-4de9-8205-f5af46476a63	25874ea2-ded6-41ed-a291-64932c16b6b2	\N	\N	\N	f	\N	false
32824623-63e8-4261-9360-b7294c81e92a	06ac479a-edda-4596-9bb0-9deb06e869a8	f3fb8b42-e703-4c79-9b5c-76ef28601e3a	Apple	\N	\N	\N	\N	"Apple"
d8f606cf-127a-43a6-a737-679cd2303c87	06ac479a-edda-4596-9bb0-9deb06e869a8	35469795-ba78-4824-90fe-9a3efcd6ad74	\N	150000	\N	\N	\N	150000
2980668e-7ba4-4c55-97b1-9591055aec20	06ac479a-edda-4596-9bb0-9deb06e869a8	22d0c615-7592-4b40-bdca-7f5a99742f9a	ноутбуки	\N	\N	\N	\N	"ноутбуки"
7b067aa5-0bf4-476b-9710-77bd587f50b8	ea3eb759-6095-4565-98d0-0fd031f58fcb	f3fb8b42-e703-4c79-9b5c-76ef28601e3a	Samsung	\N	\N	\N	\N	"Samsung"
957dfc72-7c80-4413-801a-f81cc06699c8	ea3eb759-6095-4565-98d0-0fd031f58fcb	25874ea2-ded6-41ed-a291-64932c16b6b2	\N	\N	\N	t	\N	true
18573830-9231-49f9-b83e-92f453463a54	ea3eb759-6095-4565-98d0-0fd031f58fcb	22d0c615-7592-4b40-bdca-7f5a99742f9a	смартфоны	\N	\N	\N	\N	"смартфоны"
36a99a8c-f368-46cb-9922-c0542b5fb590	0ad7b981-2af7-472f-99f9-69ce294b9abd	35469795-ba78-4824-90fe-9a3efcd6ad74	\N	80000	\N	\N	\N	80000
1da3a0a4-a2dd-4343-9bf5-178983835704	0ad7b981-2af7-472f-99f9-69ce294b9abd	22d0c615-7592-4b40-bdca-7f5a99742f9a	gaming	\N	\N	\N	\N	"gaming"
87b75c7a-9714-44fe-a92f-49ffa5d79080	0ad7b981-2af7-472f-99f9-69ce294b9abd	f3fb8b42-e703-4c79-9b5c-76ef28601e3a	Lenovo	\N	\N	\N	\N	"Lenovo"
c4f5fb07-d4b2-4bf4-9e0e-69ca90c39420	19980952-8d8b-4cc1-9358-72a785bd48e2	f2f24f03-8280-498f-b67e-82acda6f94d0	\N	\N	\N	t	\N	true
5f74a99a-4872-4871-9132-c953a8f724d3	19980952-8d8b-4cc1-9358-72a785bd48e2	35469795-ba78-4824-90fe-9a3efcd6ad74	\N	300	\N	\N	\N	300
ce443350-2164-4cc3-971f-d58c4f71487a	19980952-8d8b-4cc1-9358-72a785bd48e2	22d0c615-7592-4b40-bdca-7f5a99742f9a	умный дом	\N	\N	\N	\N	"умный дом"
9bb2aa88-e2d8-4eb4-9ab3-e3f9eb599d06	fd592784-4d39-47d2-b247-a4a557add4d7	f3fb8b42-e703-4c79-9b5c-76ef28601e3a	LG	\N	\N	\N	\N	"LG"
76815f56-78b1-4355-9d8b-95dc49927eb3	fd592784-4d39-47d2-b247-a4a557add4d7	22d0c615-7592-4b40-bdca-7f5a99742f9a	TV	\N	\N	\N	\N	"TV"
8fe2ecca-f068-45e0-b48e-bb9703ecd41a	6e107408-70b2-4de9-8205-f5af46476a63	22d0c615-7592-4b40-bdca-7f5a99742f9a	фото	\N	\N	\N	\N	"фото"
822ddd6a-ef39-4618-b529-c77fe9f4b831	19980952-8d8b-4cc1-9358-72a785bd48e2	f3fb8b42-e703-4c79-9b5c-76ef28601e3a	нет предпочтений	\N	\N	\N	\N	"нет предпочтений"
c9726efa-cf75-4f71-b953-5d799f813c21	b1c3dde5-9ccc-4b5f-891c-57ebeece11c8	22d0c615-7592-4b40-bdca-7f5a99742f9a	Ноутбуки	\N	\N	\N	\N	"Ноутбуки"
fe8da357-0518-4cfa-8ff9-a6f404af8e80	6e107408-70b2-4de9-8205-f5af46476a63	f2f24f03-8280-498f-b67e-82acda6f94d0	\N	\N	\N	t	\N	true
c685cffe-9329-4dd3-af7f-80e450a20fc8	6e107408-70b2-4de9-8205-f5af46476a63	f3fb8b42-e703-4c79-9b5c-76ef28601e3a	iPhone	\N	\N	\N	\N	"iPhone"
03977cbf-4e4b-46a7-b6e0-3586c1e015f2	995c7b75-4104-41cc-8946-fe53c81de20c	f3fb8b42-e703-4c79-9b5c-76ef28601e3a	HP	\N	\N	\N	\N	"HP"
9f128efb-5703-4725-807b-265382603413	9ea569e8-ea5b-40c1-99ca-ea03c68bbe4d	22d0c615-7592-4b40-bdca-7f5a99742f9a	смартфоны	\N	\N	\N	\N	"смартфоны"
7fa86702-1fec-45f0-84b8-fe8a2a1a6a9f	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	f3fb8b42-e703-4c79-9b5c-76ef28601e3a	Apple	\N	\N	\N	\N	"Apple"
b6156cea-2a5a-4c69-82d4-a8f083e7a8a9	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	37e9c6fb-b79a-4d2c-85f7-c9e6dad3d685	Apple	\N	\N	\N	\N	"Apple"
\.


--
-- Data for Name: user_consent; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.user_consent (consent_id, person_id, consent_type_id, is_granted, granted_at, revoked_at, source, raw_value) FROM stdin;
d1b3223a-f16f-47cf-af81-811b2c2ddd16	995c7b75-4104-41cc-8946-fe53c81de20c	912dda8c-1f03-452a-aa1a-1a0c5add40b4	t	2026-05-06 10:00:00+03	\N	web_form	да, хочу скидки
525e39df-3e48-46c8-ab22-4b0fd5dc0d34	ff58df0d-e9b5-44b3-9458-d3080031deff	caaecc37-11ec-4832-b99b-beb8c30f411d	t	2026-05-07 12:20:00+03	\N	mobile_app	+
b36df7a3-1277-4bec-beeb-74f3879feb5f	ff58df0d-e9b5-44b3-9458-d3080031deff	b18eafa9-0618-45ba-8762-98aaf1ba4161	f	\N	\N	mobile_app	sms: нет
d32a5d46-e737-4c38-9529-ccfb96932a66	abc36053-4caa-4234-b469-90c2f0ae43f1	caaecc37-11ec-4832-b99b-beb8c30f411d	t	2026-05-08 09:00:00+03	\N	call_center	оператор отметил согласие
3f5a33a6-37dd-401a-a5db-a2254c66f288	bcfa673e-ca8d-4c18-be68-e245f5375075	caaecc37-11ec-4832-b99b-beb8c30f411d	t	\N	\N	paper_form	бумажная анкета: да
125f4f5f-d4ae-4313-8753-5731147df76a	bcfa673e-ca8d-4c18-be68-e245f5375075	ab774da4-f227-425d-92ac-1b5b93a3c838	t	\N	\N	paper_form	передача партнерам: согласна
2049f7d5-9e7e-4822-8645-8f2fdfff3424	fe5d381f-5d02-421b-9cc6-e55541e56478	caaecc37-11ec-4832-b99b-beb8c30f411d	t	2026-05-09 17:45:00+03	\N	web_form	accepted
c8b60a4b-2886-44e7-a821-24193451d355	d35af3e1-167d-4b2a-8075-b530012c5b63	caaecc37-11ec-4832-b99b-beb8c30f411d	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
22f13beb-fdb5-4c1c-b7cd-88dce86e8892	d35af3e1-167d-4b2a-8075-b530012c5b63	912dda8c-1f03-452a-aa1a-1a0c5add40b4	f	\N	\N	seed_bulk	email no
facb7d5d-dcba-4b7a-8d20-d2bba14f307c	e629d14c-b866-487e-ab96-8b01ab7f2836	caaecc37-11ec-4832-b99b-beb8c30f411d	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
687ca172-f09f-48ea-b132-c56400633fc3	e629d14c-b866-487e-ab96-8b01ab7f2836	912dda8c-1f03-452a-aa1a-1a0c5add40b4	t	\N	\N	seed_bulk	email yes
fbb8a425-7d07-4455-a254-5d8aaca9928a	3345e1ce-1de2-4519-99a0-f585cab7398a	caaecc37-11ec-4832-b99b-beb8c30f411d	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
7c3d15f7-617f-4c02-8881-1f28b6882cfd	3345e1ce-1de2-4519-99a0-f585cab7398a	912dda8c-1f03-452a-aa1a-1a0c5add40b4	f	\N	\N	seed_bulk	email no
454b8359-390d-4dde-9732-74898b989359	dac44047-f9eb-4702-a9ed-1866a95da0c8	caaecc37-11ec-4832-b99b-beb8c30f411d	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
f3e8d5a4-ab2c-4ef4-be58-79e2a8b9a129	dac44047-f9eb-4702-a9ed-1866a95da0c8	912dda8c-1f03-452a-aa1a-1a0c5add40b4	t	\N	\N	seed_bulk	email yes
ddfa7b70-efc0-43f8-a3af-7f707ec28e8d	c07e21b3-ddbb-4a10-b476-8a293fe4d8a3	caaecc37-11ec-4832-b99b-beb8c30f411d	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
2a7b4f2d-6e46-4794-b712-9454e7659f58	c07e21b3-ddbb-4a10-b476-8a293fe4d8a3	912dda8c-1f03-452a-aa1a-1a0c5add40b4	f	\N	\N	seed_bulk	email no
72a84914-f4c8-45ac-ad81-f1ed80ee4dd7	2fc7c4eb-10ae-4e45-ac36-265ed4cb5170	caaecc37-11ec-4832-b99b-beb8c30f411d	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
1309fe3b-907a-4f80-abed-1bafd7b0515e	2fc7c4eb-10ae-4e45-ac36-265ed4cb5170	912dda8c-1f03-452a-aa1a-1a0c5add40b4	t	\N	\N	seed_bulk	email yes
3d32e12d-7c3b-4c69-b76e-fc776ab01405	d4ae4121-632e-43c8-8837-66eb636f1ef5	caaecc37-11ec-4832-b99b-beb8c30f411d	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
fe3e30be-f55d-4587-a309-97ba56edb998	d4ae4121-632e-43c8-8837-66eb636f1ef5	912dda8c-1f03-452a-aa1a-1a0c5add40b4	f	\N	\N	seed_bulk	email no
15a639bd-3f43-4252-b3c4-64943a027feb	6de364c7-80e9-4f25-913c-0132beea6dd9	caaecc37-11ec-4832-b99b-beb8c30f411d	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
6722fb90-7b92-420d-82dc-ad6f0490cc74	6de364c7-80e9-4f25-913c-0132beea6dd9	912dda8c-1f03-452a-aa1a-1a0c5add40b4	t	\N	\N	seed_bulk	email yes
107f83be-e211-4890-95e3-1c2e7daf39fd	24705f4b-8062-4e79-b2e8-373f8919f2fa	caaecc37-11ec-4832-b99b-beb8c30f411d	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
4eea296a-92e9-46bf-afc0-7107d9cc481d	24705f4b-8062-4e79-b2e8-373f8919f2fa	912dda8c-1f03-452a-aa1a-1a0c5add40b4	f	\N	\N	seed_bulk	email no
008dba1d-58d6-44a0-9dd8-2ed0400b7c33	2fb47c36-e066-4314-be66-72a1e5ca8789	caaecc37-11ec-4832-b99b-beb8c30f411d	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
a960fed5-0dd9-4b9f-8d7f-c011311e6b33	2fb47c36-e066-4314-be66-72a1e5ca8789	912dda8c-1f03-452a-aa1a-1a0c5add40b4	t	\N	\N	seed_bulk	email yes
05ddfba2-925f-4e7d-a149-bf03db79c0e0	34e9b7f0-650b-4a39-b90a-547b4de07dc2	caaecc37-11ec-4832-b99b-beb8c30f411d	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
4490494f-edc8-47e5-b521-204893831334	34e9b7f0-650b-4a39-b90a-547b4de07dc2	912dda8c-1f03-452a-aa1a-1a0c5add40b4	f	\N	\N	seed_bulk	email no
4d910c87-253c-49ca-b709-17be0afb089d	b545f08b-037e-4246-8c20-481f91097b7d	caaecc37-11ec-4832-b99b-beb8c30f411d	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
02e82b41-1ae3-4ba8-a21b-f87ca5e42407	b545f08b-037e-4246-8c20-481f91097b7d	912dda8c-1f03-452a-aa1a-1a0c5add40b4	t	\N	\N	seed_bulk	email yes
7e4e4fbf-ae14-4033-b18c-aa5867115725	4e69e1df-f2a3-4637-89be-ad45c0c37294	caaecc37-11ec-4832-b99b-beb8c30f411d	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
71c6bd0d-c031-4ca1-83c2-98120f0961ec	4e69e1df-f2a3-4637-89be-ad45c0c37294	912dda8c-1f03-452a-aa1a-1a0c5add40b4	f	\N	\N	seed_bulk	email no
f8dd7b92-2ba9-45ea-a75f-d155e0a341a4	b4eaf12e-13a9-488c-81a9-460e39524950	caaecc37-11ec-4832-b99b-beb8c30f411d	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
9ef88a6c-e57b-4232-afbb-bc04173a509c	b4eaf12e-13a9-488c-81a9-460e39524950	912dda8c-1f03-452a-aa1a-1a0c5add40b4	t	\N	\N	seed_bulk	email yes
03eff25f-39a9-4907-a09a-3dccc3c5edcc	27c7b285-1b06-4e1b-854f-52acea9a3ad5	caaecc37-11ec-4832-b99b-beb8c30f411d	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
f1bb8559-8447-4a2e-b883-20967fa1d22d	27c7b285-1b06-4e1b-854f-52acea9a3ad5	912dda8c-1f03-452a-aa1a-1a0c5add40b4	f	\N	\N	seed_bulk	email no
edbce572-bb7c-4a35-9823-c07a78e5f252	e3efa025-1091-4a9c-a6c8-4d2d50228fba	caaecc37-11ec-4832-b99b-beb8c30f411d	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
ad2d3afa-efcc-4da9-9a92-1c6ec9c5782d	e3efa025-1091-4a9c-a6c8-4d2d50228fba	912dda8c-1f03-452a-aa1a-1a0c5add40b4	t	\N	\N	seed_bulk	email yes
902a134e-b3a6-4cfb-9742-00e2c211bc43	65e1d23b-dfa8-44a3-bb40-15bee23ade75	caaecc37-11ec-4832-b99b-beb8c30f411d	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
fe2feae7-99e2-48f8-87e2-80b828ec111b	65e1d23b-dfa8-44a3-bb40-15bee23ade75	912dda8c-1f03-452a-aa1a-1a0c5add40b4	f	\N	\N	seed_bulk	email no
c8b33b37-df7f-4cb7-8934-fcfe58b06b9f	878871b9-bfcc-4946-baa0-4acf54f6c4b1	caaecc37-11ec-4832-b99b-beb8c30f411d	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
fdd6f880-868b-4d4f-a6e3-08798a7b81e4	878871b9-bfcc-4946-baa0-4acf54f6c4b1	912dda8c-1f03-452a-aa1a-1a0c5add40b4	t	\N	\N	seed_bulk	email yes
f9a5f32a-6c6e-49e6-898d-09794f3c76ef	17155d97-bf5f-4e23-a0c5-d4e903c45d9a	caaecc37-11ec-4832-b99b-beb8c30f411d	t	2026-05-10 10:00:00+03	\N	seed_bulk	ПД: да
6e7d740d-836e-4845-8598-f5d98259f3e1	17155d97-bf5f-4e23-a0c5-d4e903c45d9a	912dda8c-1f03-452a-aa1a-1a0c5add40b4	f	\N	\N	seed_bulk	email no
8fb482e6-92d7-40b7-83ef-a78eae8b3420	06ac479a-edda-4596-9bb0-9deb06e869a8	caaecc37-11ec-4832-b99b-beb8c30f411d	t	2021-05-10 00:00:00+03	\N	partner_source	обработка персональных данных=да
4a9fdbdb-8f97-4e55-8212-9c0e63becf42	06ac479a-edda-4596-9bb0-9deb06e869a8	912dda8c-1f03-452a-aa1a-1a0c5add40b4	t	2021-05-10 00:00:00+03	\N	partner_source	рекламные рассылки=да
3a3de492-4e6e-455d-8bdc-2a41257847eb	06ac479a-edda-4596-9bb0-9deb06e869a8	ab774da4-f227-425d-92ac-1b5b93a3c838	f	\N	2021-05-10 00:00:00+03	partner_source	передача данных партнёрам=нет
13b983eb-853a-4bb9-be1e-2c0296e1c381	ea3eb759-6095-4565-98d0-0fd031f58fcb	caaecc37-11ec-4832-b99b-beb8c30f411d	t	2022-11-03 00:00:00+03	\N	partner_source	персональные данные=1
a6161c03-75d5-403a-9d56-d99de2447a2a	ea3eb759-6095-4565-98d0-0fd031f58fcb	912dda8c-1f03-452a-aa1a-1a0c5add40b4	f	\N	2022-11-03 00:00:00+03	partner_source	маркетинг=0
68b29a3a-9ce5-46bb-80cc-09cb3759d79c	0ad7b981-2af7-472f-99f9-69ce294b9abd	912dda8c-1f03-452a-aa1a-1a0c5add40b4	f	\N	2020-02-14 00:00:00+03	partner_source	реклама=no
2bc4658d-97e3-4eff-ae9f-a4afb3825627	0ad7b981-2af7-472f-99f9-69ce294b9abd	caaecc37-11ec-4832-b99b-beb8c30f411d	t	2023-04-01 00:00:00+03	\N	partner_source	ПД=+
68a83217-f844-4d13-bd7c-0a0c8b96edff	19980952-8d8b-4cc1-9358-72a785bd48e2	ab774da4-f227-425d-92ac-1b5b93a3c838	f	\N	2019-08-20 00:00:00+03	partner_source	передача партнёрам=НЕТ
923ab119-6a12-479d-aa6e-8f104007b81c	fd592784-4d39-47d2-b247-a4a557add4d7	912dda8c-1f03-452a-aa1a-1a0c5add40b4	f	\N	2018-06-05 00:00:00+03	partner_source	маркетинг=false
5862f81d-5fa4-4a71-84fc-614e5a32ebdf	fd592784-4d39-47d2-b247-a4a557add4d7	caaecc37-11ec-4832-b99b-beb8c30f411d	t	2017-03-22 00:00:00+03	\N	partner_source	ПД=+
ce50b37b-d6d4-48e7-939d-e6fb514951aa	314f1da4-b6ba-41a3-88f4-ffd61e8ba47f	caaecc37-11ec-4832-b99b-beb8c30f411d	t	2025-01-10 00:00:00+03	\N	partner_source	персональные данные=1
c242634e-1d77-4719-86b6-55eaf1a395cf	19980952-8d8b-4cc1-9358-72a785bd48e2	caaecc37-11ec-4832-b99b-beb8c30f411d	t	2020-09-01 00:00:00+03	\N	partner_source	ПД=да
e969311a-ae7a-4919-8ce4-b6e574f0e80b	19980952-8d8b-4cc1-9358-72a785bd48e2	912dda8c-1f03-452a-aa1a-1a0c5add40b4	f	\N	2020-09-01 00:00:00+03	partner_source	реклама=-
75455001-4631-4c4a-b2fc-ab29550091a9	b1c3dde5-9ccc-4b5f-891c-57ebeece11c8	caaecc37-11ec-4832-b99b-beb8c30f411d	t	2016-12-01 00:00:00+03	\N	partner_source	обработка персональных данных=yes
4a3fe454-f56f-425f-ae0c-35e38157ec10	6e107408-70b2-4de9-8205-f5af46476a63	caaecc37-11ec-4832-b99b-beb8c30f411d	t	2021-07-07 00:00:00+03	\N	partner_source	ПД=да
c9fc3841-b34f-40fb-9772-0c57c161ee97	6e107408-70b2-4de9-8205-f5af46476a63	912dda8c-1f03-452a-aa1a-1a0c5add40b4	t	2021-07-07 00:00:00+03	\N	partner_source	маркетинг=да
7823d79e-617a-42fe-98ac-1d6b1ba63595	162f794a-bac5-490a-acf5-160eb22fa716	caaecc37-11ec-4832-b99b-beb8c30f411d	t	2022-07-15 00:00:00+03	\N	partner_source	персональные данные=TRUE
2b9004c4-8ee4-4e05-a67d-f6fbea1b64df	cffa55ae-4de8-4c9a-b8be-9a55292fe7b1	caaecc37-11ec-4832-b99b-beb8c30f411d	t	2023-09-10 00:00:00+03	\N	partner_source	ПД=1
fd0cc579-6dfe-453c-a9af-c6c6b2502066	995c7b75-4104-41cc-8946-fe53c81de20c	caaecc37-11ec-4832-b99b-beb8c30f411d	t	2021-01-11 00:00:00+03	\N	partner_source	обработка ПД=да
56331789-0176-4d1e-8d47-6c4142e9eec9	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	caaecc37-11ec-4832-b99b-beb8c30f411d	t	2023-03-05 00:00:00+03	\N	partner_source	персональные данные=+
\.


--
-- Data for Name: user_contact; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.user_contact (contact_id, person_id, contact_type_id, contact_value, raw_value, is_primary, is_verified, created_at) FROM stdin;
c2f97a9c-3885-4c73-8d6f-3ed32625530d	995c7b75-4104-41cc-8946-fe53c81de20c	72637c84-ac87-49d4-9383-ec5788f52af7	ivanov@example.ru	ivanov@example.ru, i.ivanov@oldmail.ru	t	t	2026-06-07 18:44:10.912383+03
36e89ad6-eb5a-405d-b124-2967989fda67	995c7b75-4104-41cc-8946-fe53c81de20c	d000df9c-5de3-4d15-8b50-053f010ac84e	+79991234567	+7 (999) 123-45-67 / tg: @ivan_tech	t	f	2026-06-07 18:44:10.912383+03
ee598d71-1335-45ee-9f62-bdd4891ee523	995c7b75-4104-41cc-8946-fe53c81de20c	d07693b8-7595-441a-8e66-8e6345a31687	@ivan_tech	+7 (999) 123-45-67 / tg: @ivan_tech	f	f	2026-06-07 18:44:10.912383+03
8170aee0-d477-4e94-9fd2-79dbefdc0dc5	ff58df0d-e9b5-44b3-9458-d3080031deff	72637c84-ac87-49d4-9383-ec5788f52af7	m.pet.rova@example.com	m.pet.rova@example.com; petrova.work@example.org	t	f	2026-06-07 18:44:10.928178+03
a09d89d0-546f-4f14-87b3-ffed3bbe14c9	ff58df0d-e9b5-44b3-9458-d3080031deff	72637c84-ac87-49d4-9383-ec5788f52af7	petrova.work@example.org	m.pet.rova@example.com; petrova.work@example.org	f	f	2026-06-07 18:44:10.928178+03
095df9ac-e0b9-40e6-b973-8167433deda9	ff58df0d-e9b5-44b3-9458-d3080031deff	d000df9c-5de3-4d15-8b50-053f010ac84e	+79161230000	8-916-123-00-00	f	f	2026-06-07 18:44:10.928178+03
56244c38-8884-4a8f-9994-c25a2648f03a	abc36053-4caa-4234-b469-90c2f0ae43f1	72637c84-ac87-49d4-9383-ec5788f52af7	bad-email-without-at	bad-email-without-at, alexey.sid@mail.ru	t	f	2026-06-07 18:44:10.933062+03
a500a6e1-e24d-49c3-83ab-cd95f2f2dc9a	abc36053-4caa-4234-b469-90c2f0ae43f1	72637c84-ac87-49d4-9383-ec5788f52af7	alexey.sid@mail.ru	bad-email-without-at, alexey.sid@mail.ru	f	f	2026-06-07 18:44:10.933062+03
8b9368e0-cdf5-414c-ae48-70eac1104266	abc36053-4caa-4234-b469-90c2f0ae43f1	81c03a87-55c7-449c-96f2-3abf479e1ea2	+79260001122	whatsapp +7 926 000 11 22	f	f	2026-06-07 18:44:10.933062+03
7cf979e3-cc8a-49b4-80f3-86c65e383390	bcfa673e-ca8d-4c18-be68-e245f5375075	d000df9c-5de3-4d15-8b50-053f010ac84e	+79035556677	тел. 9035556677	f	f	2026-06-07 18:44:10.936834+03
6631c6ff-d6d4-43c1-b33e-100497297767	bcfa673e-ca8d-4c18-be68-e245f5375075	d07693b8-7595-441a-8e66-8e6345a31687	@elena_devices	telegram: @elena_devices	f	f	2026-06-07 18:44:10.936834+03
acc31e2f-e085-4cb0-b8fa-0507ceb40689	fe5d381f-5d02-421b-9cc6-e55541e56478	72637c84-ac87-49d4-9383-ec5788f52af7	denis.orlov@example.net	\N	t	t	2026-06-07 18:44:10.940391+03
9a070bab-916c-4dee-b920-6bc36c794e03	d35af3e1-167d-4b2a-8075-b530012c5b63	72637c84-ac87-49d4-9383-ec5788f52af7	p.smirnov@example.ru	p.smirnov@example.ru, smirnov.old@mail.ru	t	t	2026-06-07 18:44:10.944758+03
3a7f439a-be2a-4640-8ffe-e18743dd4edc	d35af3e1-167d-4b2a-8075-b530012c5b63	d000df9c-5de3-4d15-8b50-053f010ac84e	+7 (916) 100-20-30	+7 (916) 100-20-30	f	f	2026-06-07 18:44:10.944758+03
12c92f4e-098e-4654-9ece-ff2cd2dc72af	e629d14c-b866-487e-ab96-8b01ab7f2836	72637c84-ac87-49d4-9383-ec5788f52af7	olga.v@example.ru	olga.v@example.ru	t	t	2026-06-07 18:44:10.944758+03
babf2101-2482-4099-b409-0737466f9499	e629d14c-b866-487e-ab96-8b01ab7f2836	d000df9c-5de3-4d15-8b50-053f010ac84e	8-926-222-33-44	8-926-222-33-44	f	f	2026-06-07 18:44:10.944758+03
0d3c5376-3238-41f5-bff3-fefdf98f59ef	3345e1ce-1de2-4519-99a0-f585cab7398a	72637c84-ac87-49d4-9383-ec5788f52af7	roman.n@example.ru	roman.n@example.ru; r.nikitin@work.ru	t	t	2026-06-07 18:44:10.944758+03
37ba1275-cd65-45b8-8378-8bf1d39c3ca7	3345e1ce-1de2-4519-99a0-f585cab7398a	d000df9c-5de3-4d15-8b50-053f010ac84e	+7 812 333 44 55	+7 812 333 44 55	f	f	2026-06-07 18:44:10.944758+03
80cf72da-87a9-45d9-a1a6-d0d93d45698b	dac44047-f9eb-4702-a9ed-1866a95da0c8	72637c84-ac87-49d4-9383-ec5788f52af7	irina.m@example.ru	irina.m@example.ru	t	t	2026-06-07 18:44:10.944758+03
555a8e2c-e2c8-4f04-9c2d-d852e0d28ca8	dac44047-f9eb-4702-a9ed-1866a95da0c8	d000df9c-5de3-4d15-8b50-053f010ac84e	9035556677	9035556677	f	f	2026-06-07 18:44:10.944758+03
0ee43f9e-66fe-4f56-9554-c490eeccd3ae	c07e21b3-ddbb-4a10-b476-8a293fe4d8a3	72637c84-ac87-49d4-9383-ec5788f52af7	g.alekseev@example.ru	g.alekseev@example.ru	t	t	2026-06-07 18:44:10.944758+03
ab7d5024-5de3-4294-85ab-c64a8bf8ccc4	c07e21b3-ddbb-4a10-b476-8a293fe4d8a3	d000df9c-5de3-4d15-8b50-053f010ac84e	+7(383)123-45-67	+7(383)123-45-67	f	f	2026-06-07 18:44:10.944758+03
7fb390cb-ef0a-4de8-8d54-004bbb499f53	2fc7c4eb-10ae-4e45-ac36-265ed4cb5170	72637c84-ac87-49d4-9383-ec5788f52af7	d.romanova.example.ru	d.romanova.example.ru	t	f	2026-06-07 18:44:10.944758+03
02fe146c-fdf3-4d3e-baec-a9135a734ada	2fc7c4eb-10ae-4e45-ac36-265ed4cb5170	d000df9c-5de3-4d15-8b50-053f010ac84e	+7 495 777 88 99	+7 495 777 88 99	f	f	2026-06-07 18:44:10.944758+03
bddeb4c1-948c-472b-baaf-5d221b0f9311	d4ae4121-632e-43c8-8837-66eb636f1ef5	72637c84-ac87-49d4-9383-ec5788f52af7	max.g@example.ru	max.g@example.ru, gavrilov.max@mail.ru	t	t	2026-06-07 18:44:10.944758+03
63512081-9cc6-4956-af4e-d4570c915540	d4ae4121-632e-43c8-8837-66eb636f1ef5	d000df9c-5de3-4d15-8b50-053f010ac84e	8 800 555 35 35	8 800 555 35 35	f	f	2026-06-07 18:44:10.944758+03
d153ef8b-0c29-4367-b5dc-fb3989ebd07a	6de364c7-80e9-4f25-913c-0132beea6dd9	72637c84-ac87-49d4-9383-ec5788f52af7	v.egorova@example.ru	v.egorova@example.ru	t	t	2026-06-07 18:44:10.944758+03
956de75a-1f59-47eb-a837-85071ca55e84	6de364c7-80e9-4f25-913c-0132beea6dd9	d000df9c-5de3-4d15-8b50-053f010ac84e	+7-917-111-22-33	+7-917-111-22-33	f	f	2026-06-07 18:44:10.944758+03
e1fe0757-9947-4614-bcff-202c67d9ab03	24705f4b-8062-4e79-b2e8-373f8919f2fa	72637c84-ac87-49d4-9383-ec5788f52af7	s.pavlov@example.ru	s.pavlov@example.ru	t	t	2026-06-07 18:44:10.944758+03
94c44a0a-250e-4498-b0e7-87b37ddebea4	24705f4b-8062-4e79-b2e8-373f8919f2fa	d000df9c-5de3-4d15-8b50-053f010ac84e	89161231212	89161231212	f	f	2026-06-07 18:44:10.944758+03
16b3b3aa-e9e6-421a-b2a1-d0fcd50edfd1	2fb47c36-e066-4314-be66-72a1e5ca8789	72637c84-ac87-49d4-9383-ec5788f52af7	ks.fomina@example.ru	ks.fomina@example.ru; k.fomina@old.ru	t	t	2026-06-07 18:44:10.944758+03
5f6edff2-d46c-4579-b2c0-6f902a23a2de	2fb47c36-e066-4314-be66-72a1e5ca8789	d000df9c-5de3-4d15-8b50-053f010ac84e	+7 921 000 11 22	+7 921 000 11 22	f	f	2026-06-07 18:44:10.944758+03
188c3e11-2deb-49fe-8049-11969ad3a42e	34e9b7f0-650b-4a39-b90a-547b4de07dc2	72637c84-ac87-49d4-9383-ec5788f52af7	matvey.b@example.ru	matvey.b@example.ru	t	t	2026-06-07 18:44:10.944758+03
49c9bc72-e25d-4a8c-8a34-a87f399da1c5	34e9b7f0-650b-4a39-b90a-547b4de07dc2	d000df9c-5de3-4d15-8b50-053f010ac84e	+7 999 010 20 30	+7 999 010 20 30	f	f	2026-06-07 18:44:10.944758+03
5c698cfe-b9f2-47ce-b0b6-dd78d3e27060	b545f08b-037e-4246-8c20-481f91097b7d	72637c84-ac87-49d4-9383-ec5788f52af7	n.solovieva@example.ru	n.solovieva@example.ru	t	t	2026-06-07 18:44:10.944758+03
96282d52-763a-4739-9f42-6fd9c4e5d3fd	b545f08b-037e-4246-8c20-481f91097b7d	d000df9c-5de3-4d15-8b50-053f010ac84e	+7 903 444 55 66	+7 903 444 55 66	f	f	2026-06-07 18:44:10.944758+03
b2ff5c4e-aa3d-45fe-a080-c692258f945c	4e69e1df-f2a3-4637-89be-ad45c0c37294	72637c84-ac87-49d4-9383-ec5788f52af7	ars.titov@example.ru	ars.titov@example.ru	t	t	2026-06-07 18:44:10.944758+03
014d9013-52b7-4c95-9f52-8bc858e9b848	4e69e1df-f2a3-4637-89be-ad45c0c37294	d000df9c-5de3-4d15-8b50-053f010ac84e	8(901)234-56-78	8(901)234-56-78	f	f	2026-06-07 18:44:10.944758+03
5d26904b-bfa1-4bc0-a9fe-34e2b5889b96	b4eaf12e-13a9-488c-81a9-460e39524950	72637c84-ac87-49d4-9383-ec5788f52af7	alina.m@example.ru	alina.m@example.ru	t	t	2026-06-07 18:44:10.944758+03
5a37ae1e-0677-49ff-8237-e9c6fdba8540	b4eaf12e-13a9-488c-81a9-460e39524950	d000df9c-5de3-4d15-8b50-053f010ac84e	+79269998877	+79269998877	f	f	2026-06-07 18:44:10.944758+03
a3362a20-ad01-4b94-abcc-46250d83aabf	27c7b285-1b06-4e1b-854f-52acea9a3ad5	72637c84-ac87-49d4-9383-ec5788f52af7	fedorkrylov.mail.ru	fedorkrylov.mail.ru	t	f	2026-06-07 18:44:10.944758+03
519871ad-197f-4ff0-9c1d-bbc4eadefd42	27c7b285-1b06-4e1b-854f-52acea9a3ad5	d000df9c-5de3-4d15-8b50-053f010ac84e	+79123456789	+79123456789	f	f	2026-06-07 18:44:10.944758+03
59e32324-1e9b-41a6-abac-956268b9eb49	e3efa025-1091-4a9c-a6c8-4d2d50228fba	72637c84-ac87-49d4-9383-ec5788f52af7	m.zueva@example.ru	m.zueva@example.ru, marina.zueva@work.ru	t	t	2026-06-07 18:44:10.944758+03
507fea0e-ff31-4d5b-8e2b-3cea2737bf77	e3efa025-1091-4a9c-a6c8-4d2d50228fba	d000df9c-5de3-4d15-8b50-053f010ac84e	8 800 333 44 55	8 800 333 44 55	f	f	2026-06-07 18:44:10.944758+03
50e9ee99-4bac-42d1-a746-45950eb3a1cc	65e1d23b-dfa8-44a3-bb40-15bee23ade75	72637c84-ac87-49d4-9383-ec5788f52af7	anton.k@example.ru	anton.k@example.ru	t	t	2026-06-07 18:44:10.944758+03
63078c87-6479-405e-9a69-169704ecd4e7	65e1d23b-dfa8-44a3-bb40-15bee23ade75	d000df9c-5de3-4d15-8b50-053f010ac84e	+74951234567	+74951234567	f	f	2026-06-07 18:44:10.944758+03
e9da7fde-08cc-4165-988d-3be4fbaf51f6	878871b9-bfcc-4946-baa0-4acf54f6c4b1	72637c84-ac87-49d4-9383-ec5788f52af7	y.makarova@example.ru	y.makarova@example.ru	t	t	2026-06-07 18:44:10.944758+03
de352596-5eb9-47fd-9583-0b77a1cb12fd	878871b9-bfcc-4946-baa0-4acf54f6c4b1	d000df9c-5de3-4d15-8b50-053f010ac84e	+7(863)222-33-44	+7(863)222-33-44	f	f	2026-06-07 18:44:10.944758+03
ba14a8fb-616f-4168-909a-2bb1fffca1ee	17155d97-bf5f-4e23-a0c5-d4e903c45d9a	72637c84-ac87-49d4-9383-ec5788f52af7	lev.d@example.ru	lev.d@example.ru	t	t	2026-06-07 18:44:10.944758+03
5d863765-dbec-41a0-8317-37ba587772b7	17155d97-bf5f-4e23-a0c5-d4e903c45d9a	d000df9c-5de3-4d15-8b50-053f010ac84e	+7 812 333 44 56	+7 812 333 44 56	f	f	2026-06-07 18:44:10.944758+03
563a634a-17a5-4798-b1d6-a581f9e25039	6e107408-70b2-4de9-8205-f5af46476a63	72637c84-ac87-49d4-9383-ec5788f52af7	s.borisova@example.ru	s.borisova@example.ru	t	t	2026-06-07 18:44:10.944758+03
9faae6e7-f475-4f11-b5e1-377e93e5015b	6e107408-70b2-4de9-8205-f5af46476a63	d000df9c-5de3-4d15-8b50-053f010ac84e	8-926-123-45-67	8-926-123-45-67	f	f	2026-06-07 18:44:10.944758+03
f43d9ef5-fd59-4d07-85a0-69d957aef798	06ac479a-edda-4596-9bb0-9deb06e869a8	72637c84-ac87-49d4-9383-ec5788f52af7	ivan.ivanov@gmail.com	ivan.ivanov@gmail.com	t	f	2026-06-07 18:44:11.023358+03
066e46eb-61fe-4381-b91b-9b424e349d7b	06ac479a-edda-4596-9bb0-9deb06e869a8	d000df9c-5de3-4d15-8b50-053f010ac84e	79261234567	+79261234567	t	f	2026-06-07 18:44:11.023358+03
9526d4cc-6a01-4541-91bd-bc7ad2ecf99d	ea3eb759-6095-4565-98d0-0fd031f58fcb	72637c84-ac87-49d4-9383-ec5788f52af7	anna.petrova@mail.ru	ANNA.PETROVA@MAIL.RU, a.petrova@yandex.ru	t	f	2026-06-07 18:44:11.023358+03
b639f404-5217-4a81-b898-14baca96f62f	ea3eb759-6095-4565-98d0-0fd031f58fcb	72637c84-ac87-49d4-9383-ec5788f52af7	a.petrova@yandex.ru	ANNA.PETROVA@MAIL.RU, a.petrova@yandex.ru	f	f	2026-06-07 18:44:11.023358+03
28fe6c43-5cd3-4b2d-b7fd-f6bae2ceb15f	ea3eb759-6095-4565-98d0-0fd031f58fcb	d000df9c-5de3-4d15-8b50-053f010ac84e	89165551122	8(916)555-11-22	t	f	2026-06-07 18:44:11.023358+03
e7be1e4e-60c2-4522-843c-b6c3da56c125	0ad7b981-2af7-472f-99f9-69ce294b9abd	72637c84-ac87-49d4-9383-ec5788f52af7	kozlov.ae@bk.ru	kozlov.ae@bk.ru	t	f	2026-06-07 18:44:11.023358+03
3441617b-6103-4f4d-97e9-0f1e22c10ff9	0ad7b981-2af7-472f-99f9-69ce294b9abd	d000df9c-5de3-4d15-8b50-053f010ac84e	83834445566	8 383 444 55 66	t	f	2026-06-07 18:44:11.023358+03
fde79e2f-0b14-4943-a1ea-de2d78c21e8b	0ad7b981-2af7-472f-99f9-69ce294b9abd	72637c84-ac87-49d4-9383-ec5788f52af7	b.sidorov@inbox.ru	b.sidorov@inbox.ru	t	f	2026-06-07 18:44:11.023358+03
e7c4ea6a-e3c8-4b1f-bd59-f42fb992cdda	0ad7b981-2af7-472f-99f9-69ce294b9abd	d000df9c-5de3-4d15-8b50-053f010ac84e	89161112233	89161112233	t	f	2026-06-07 18:44:11.023358+03
f558458c-3aaa-4092-aa77-c36bab73693b	19980952-8d8b-4cc1-9358-72a785bd48e2	72637c84-ac87-49d4-9383-ec5788f52af7	e.novikova@work.ru	e.novikova@work.ru,novikova85@mail.ru ,ea_nov@yandex.ru	t	f	2026-06-07 18:44:11.023358+03
3b4afd0c-e9e4-4d13-bd86-e3746c7919ad	19980952-8d8b-4cc1-9358-72a785bd48e2	72637c84-ac87-49d4-9383-ec5788f52af7	novikova85@mail.ru	e.novikova@work.ru,novikova85@mail.ru ,ea_nov@yandex.ru	f	f	2026-06-07 18:44:11.023358+03
942ef2de-5793-4dff-a020-5f2188198671	19980952-8d8b-4cc1-9358-72a785bd48e2	72637c84-ac87-49d4-9383-ec5788f52af7	ea_nov@yandex.ru	e.novikova@work.ru,novikova85@mail.ru ,ea_nov@yandex.ru	f	f	2026-06-07 18:44:11.023358+03
989113c6-089f-4dfe-ab21-5f2ae19ff222	19980952-8d8b-4cc1-9358-72a785bd48e2	d000df9c-5de3-4d15-8b50-053f010ac84e	74956001122	+7-495-600-11-22	t	f	2026-06-07 18:44:11.023358+03
150acc01-5262-44a2-8d1f-91c8c0ba4898	fd592784-4d39-47d2-b247-a4a557add4d7	72637c84-ac87-49d4-9383-ec5788f52af7	morozov_da@gmail.com	morozov_da@gmail.com	t	f	2026-06-07 18:44:11.023358+03
ce0b2415-23e9-48b7-a8de-b23a1cb04c2b	fd592784-4d39-47d2-b247-a4a557add4d7	d000df9c-5de3-4d15-8b50-053f010ac84e	89267778899	8 926 777 88 99	t	f	2026-06-07 18:44:11.023358+03
4aff9079-09a3-4a03-949a-d984d281f7f0	fd592784-4d39-47d2-b247-a4a557add4d7	72637c84-ac87-49d4-9383-ec5788f52af7	lebedev.sergey@list.ru	lebedev.sergey@list.ru	t	f	2026-06-07 18:44:11.023358+03
a28d1143-1ee4-440f-8eb1-a3e4279a83bf	fd592784-4d39-47d2-b247-a4a557add4d7	d000df9c-5de3-4d15-8b50-053f010ac84e	78123334455	+7 812 333 44 55	t	f	2026-06-07 18:44:11.023358+03
a6644847-722e-45f1-a61c-b2715f623a38	6e107408-70b2-4de9-8205-f5af46476a63	72637c84-ac87-49d4-9383-ec5788f52af7	nat.sokolova@gmail.com	nat.sokolova@gmail.com	t	f	2026-06-07 18:44:11.023358+03
ac695cbe-c9a6-4b9d-bd16-89d5c2b992eb	6e107408-70b2-4de9-8205-f5af46476a63	d000df9c-5de3-4d15-8b50-053f010ac84e	89261234567	8-926-123-45-67	t	f	2026-06-07 18:44:11.023358+03
750367bf-ed0f-422a-897d-db146aa7d5e2	314f1da4-b6ba-41a3-88f4-ffd61e8ba47f	72637c84-ac87-49d4-9383-ec5788f52af7	andreym_2000@inbox.ru	andreyM_2000@inbox.ru  andr.mikhaylov@corp.ru	t	f	2026-06-07 18:44:11.023358+03
192c336b-4a30-4f2b-bac7-069af3dde697	314f1da4-b6ba-41a3-88f4-ffd61e8ba47f	72637c84-ac87-49d4-9383-ec5788f52af7	andr.mikhaylov@corp.ru	andreyM_2000@inbox.ru  andr.mikhaylov@corp.ru	f	f	2026-06-07 18:44:11.023358+03
968d7e7a-238b-4c82-8a28-ef9c40cc1e53	19980952-8d8b-4cc1-9358-72a785bd48e2	72637c84-ac87-49d4-9383-ec5788f52af7	fedorova_y@yandex.ru	fedorova_y@yandex.ru	t	f	2026-06-07 18:44:11.023358+03
f60da6c4-3d4c-48ab-b9e8-0ea3b644b010	19980952-8d8b-4cc1-9358-72a785bd48e2	d000df9c-5de3-4d15-8b50-053f010ac84e	78632223344	+7(863)222-33-44	t	f	2026-06-07 18:44:11.023358+03
8f371685-ff30-4fb7-9e8b-f3369928201f	b1c3dde5-9ccc-4b5f-891c-57ebeece11c8	72637c84-ac87-49d4-9383-ec5788f52af7	v.popov@corp.ru	v.popov@corp.ru	t	f	2026-06-07 18:44:11.023358+03
780f9a2c-fa6e-4cbb-8f5e-e00eb7f1d683	b1c3dde5-9ccc-4b5f-891c-57ebeece11c8	d000df9c-5de3-4d15-8b50-053f010ac84e	74951112233	+7 495 111 22 33	t	f	2026-06-07 18:44:11.023358+03
009667b8-8854-4113-b497-08f401e68df5	6e107408-70b2-4de9-8205-f5af46476a63	72637c84-ac87-49d4-9383-ec5788f52af7	anna.k@gmail.com	anna.k@gmail.com	t	f	2026-06-07 18:44:11.023358+03
0a5b707c-4f1f-44ee-a1f9-d53e8c4abfd6	6e107408-70b2-4de9-8205-f5af46476a63	d000df9c-5de3-4d15-8b50-053f010ac84e	74951234567	+7(495) 123-45-67	t	f	2026-06-07 18:44:11.023358+03
c7232657-4902-4718-8206-f88347b748ab	6e107408-70b2-4de9-8205-f5af46476a63	d000df9c-5de3-4d15-8b50-053f010ac84e	89268889900	8-926-888-99-00	f	f	2026-06-07 18:44:11.023358+03
0e4a4539-04a1-47b4-91c5-37f1281a8f72	162f794a-bac5-490a-acf5-160eb22fa716	72637c84-ac87-49d4-9383-ec5788f52af7	roman.zaitsev@rambler.ru	roman.zaitsev@rambler.ru	t	f	2026-06-07 18:44:11.023358+03
68fd58b2-992f-4691-b979-3f848234b4c5	162f794a-bac5-490a-acf5-160eb22fa716	d000df9c-5de3-4d15-8b50-053f010ac84e	89031234567	89031234567	t	f	2026-06-07 18:44:11.023358+03
f941318b-d809-4507-9a29-756a868db7e6	cffa55ae-4de8-4c9a-b8be-9a55292fe7b1	72637c84-ac87-49d4-9383-ec5788f52af7	belova_ks@mail.ru	belova_ks@mail.ru, belova.kseniya@gmail.com	t	f	2026-06-07 18:44:11.023358+03
62e992d0-5ae1-4a63-a0c4-bcefe9a2357a	cffa55ae-4de8-4c9a-b8be-9a55292fe7b1	72637c84-ac87-49d4-9383-ec5788f52af7	belova.kseniya@gmail.com	belova_ks@mail.ru, belova.kseniya@gmail.com	f	f	2026-06-07 18:44:11.023358+03
7ed953e1-aaa6-4351-abca-072788fe9faa	cffa55ae-4de8-4c9a-b8be-9a55292fe7b1	d000df9c-5de3-4d15-8b50-053f010ac84e	9261112233	926-111-22-33	t	f	2026-06-07 18:44:11.023358+03
23e258e7-4bc5-4242-9f64-6f04657a134a	995c7b75-4104-41cc-8946-fe53c81de20c	72637c84-ac87-49d4-9383-ec5788f52af7	k.tarasov@yandex.ru	k.tarasov@yandex.ru	t	f	2026-06-07 18:44:11.023358+03
a4c9cff5-cba8-41cc-9627-c1bea35ff2f6	995c7b75-4104-41cc-8946-fe53c81de20c	d000df9c-5de3-4d15-8b50-053f010ac84e	83839998877	8(383)999-88-77	t	f	2026-06-07 18:44:11.023358+03
65fe61bb-3528-480f-bf8c-263af83f5776	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	72637c84-ac87-49d4-9383-ec5788f52af7	artem.gromov@gmail.com	artem.gromov@gmail.com;a.gromov@work.ru	t	f	2026-06-07 18:44:11.023358+03
755c0d23-6dda-4c11-8da2-1d34535d2082	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	72637c84-ac87-49d4-9383-ec5788f52af7	a.gromov@work.ru	artem.gromov@gmail.com;a.gromov@work.ru	f	f	2026-06-07 18:44:11.023358+03
02797c75-aa42-4356-a2b5-cb2a826ba4a7	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	d000df9c-5de3-4d15-8b50-053f010ac84e	79151234567	+79151234567	t	f	2026-06-07 18:44:11.023358+03
e69ab50d-cb50-4c16-bc2f-23cead264689	9ea569e8-ea5b-40c1-99ca-ea03c68bbe4d	72637c84-ac87-49d4-9383-ec5788f52af7	frolova_n@bk.ru	frolova_n@bk.ru	t	f	2026-06-07 18:44:11.023358+03
7fd1867b-4e09-4c02-9acc-aee2a0fc83bc	9ea569e8-ea5b-40c1-99ca-ea03c68bbe4d	d000df9c-5de3-4d15-8b50-053f010ac84e	79177776655	+7 917 777 66 55	t	f	2026-06-07 18:44:11.023358+03
963da7cf-fea2-48d5-9f95-1d95ff5f850c	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	72637c84-ac87-49d4-9383-ec5788f52af7	o.zakharov@inbox.ru	o.zakharov@inbox.ru	t	f	2026-06-07 18:44:11.023358+03
59f10acc-a87e-433c-9e26-6b85948e6753	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	d000df9c-5de3-4d15-8b50-053f010ac84e	89254567890	8 (925) 456 78 90	t	f	2026-06-07 18:44:11.023358+03
28d36769-50f3-4124-ae25-9941b995224d	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	72637c84-ac87-49d4-9383-ec5788f52af7	marinakrylova.mail.ru	marinakrylova.mail.ru	t	f	2026-06-07 18:44:11.023358+03
407eab73-e63f-4bd9-a2ec-50b1b6e655c3	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	d000df9c-5de3-4d15-8b50-053f010ac84e	79123456789	+79123456789	t	f	2026-06-07 18:44:11.023358+03
b45aa51e-bad8-4ce9-8fa3-080a3e6cc3fd	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	72637c84-ac87-49d4-9383-ec5788f52af7	v.bogdanov@gmail.com	v.bogdanov@gmail.com	t	f	2026-06-07 18:44:11.023358+03
0d7fe834-7b3a-4650-b369-af7fc84da1b5	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	d000df9c-5de3-4d15-8b50-053f010ac84e	88003334455	8 800 333 44 55	t	f	2026-06-07 18:44:11.023358+03
6ae76962-78d2-406e-9b06-b69a770abe5d	b4eaf12e-13a9-488c-81a9-460e39524950	72637c84-ac87-49d4-9383-ec5788f52af7	alina.simonova@yandex.ru	alina.simonova@yandex.ru	t	f	2026-06-07 18:44:11.023358+03
7c39f8d2-18ef-444f-8758-0b3112587708	b4eaf12e-13a9-488c-81a9-460e39524950	d000df9c-5de3-4d15-8b50-053f010ac84e	79269998877	+79269998877	t	f	2026-06-07 18:44:11.023358+03
119d4e01-4655-4f0a-9663-82ac02719f36	b4eaf12e-13a9-488c-81a9-460e39524950	72637c84-ac87-49d4-9383-ec5788f52af7	kirill_v@hotmail.com	kirill_v@hotmail.com	t	f	2026-06-07 18:44:11.023358+03
104c3730-08d9-4898-a495-c61d61c2c2ba	65e1d23b-dfa8-44a3-bb40-15bee23ade75	72637c84-ac87-49d4-9383-ec5788f52af7	d.gorbunova@gmail.com	d.gorbunova@gmail.com	t	f	2026-06-07 18:44:11.023358+03
2bb55741-2b23-4c0e-a379-98f4624f2a0c	65e1d23b-dfa8-44a3-bb40-15bee23ade75	d000df9c-5de3-4d15-8b50-053f010ac84e	74951234567	+74951234567	t	f	2026-06-07 18:44:11.023358+03
bc968fd8-9b49-48b0-8de5-e9baf4dc398c	3fde298b-7536-4b09-a828-87223b009b1c	72637c84-ac87-49d4-9383-ec5788f52af7	ion.popescu@mail.ru	ion.popescu@mail.ru	t	f	2026-06-07 18:44:11.023358+03
3a1eb95d-2c3d-4693-a3b8-954e4d08bd35	3fde298b-7536-4b09-a828-87223b009b1c	d000df9c-5de3-4d15-8b50-053f010ac84e	37369123456	+37369123456	t	f	2026-06-07 18:44:11.023358+03
282c42ea-eb3d-4f5a-bcea-8a308687293c	b4eaf12e-13a9-488c-81a9-460e39524950	72637c84-ac87-49d4-9383-ec5788f52af7	ilya.chernov@gmail.com	ilya.chernov@gmail.com	t	f	2026-06-07 18:44:11.023358+03
5d6c66b3-d5c9-4027-ac1a-0206f1e519e3	b4eaf12e-13a9-488c-81a9-460e39524950	d000df9c-5de3-4d15-8b50-053f010ac84e	89012345678	8 901 234 56 78	t	f	2026-06-07 18:44:11.023358+03
\.


--
-- Data for Name: user_verification_document; Type: TABLE DATA; Schema: public; Owner: yui
--

COPY public.user_verification_document (document_id, person_id, document_type_id, series, number, issue_date, issue_date_raw, issued_by, raw_document_text, verification_status_id) FROM stdin;
0ed842c1-5d5f-4228-b8e1-813061c9c592	995c7b75-4104-41cc-8946-fe53c81de20c	b5efb985-8956-4535-a11a-ca095b2717b4	4510	123456	2018-02-10	10.02.2018	ОВД Тверского района	4510 123456 выдан ОВД Тверского района 10.02.2018	1084ec39-bdd9-423f-a7d0-1c4e18d07168
1edbf1b4-3eb3-48ac-bf9a-e4f7e2b4567d	ff58df0d-e9b5-44b3-9458-d3080031deff	739ff378-3ba0-443f-b745-99b6375fc676	77AA	654321	2019-03-15	2019-03-15	ГИБДД Москва	ВУ 77AA 654321 от 2019-03-15	04403f61-f336-4eaf-8ee6-f4a148ccd2db
25d38ddd-32ff-491b-b62d-f05ec5407e03	abc36053-4caa-4234-b469-90c2f0ae43f1	b5efb985-8956-4535-a11a-ca095b2717b4	4012	777888	2016-03-20	20 марта 2016 года	ТП №1	паспорт 4012 777888 кем и когда выдан: ТП №1 20 марта 2016 года	5d8085e7-9311-432c-8d46-61ddf0008a7b
6223832f-151a-4aba-b179-137deb4c025a	bcfa673e-ca8d-4c18-be68-e245f5375075	072c79e3-d892-469a-b753-ccf9fbe3a099	МК	009988	2020-01-01	01.01.20	военкомат	МК 009988 военкомат 01.01.20	2b42eec1-a7f9-40ac-9634-369f49740eb9
f87018fb-84b3-4684-b236-5060c0f72b7c	3345e1ce-1de2-4519-99a0-f585cab7398a	b5efb985-8956-4535-a11a-ca095b2717b4	4513	500111	2013-04-10	10.04.2013	ОВД района	паспорт одной строкой: серия 4513 номер 500111	5d8085e7-9311-432c-8d46-61ddf0008a7b
25037fba-fe2e-4921-b299-ea8eacdbdfe7	2fc7c4eb-10ae-4e45-ac36-265ed4cb5170	b5efb985-8956-4535-a11a-ca095b2717b4	4516	500222	2016-07-10	10.07.2016	ОВД района	паспорт одной строкой: серия 4516 номер 500222	5d8085e7-9311-432c-8d46-61ddf0008a7b
2b827a15-6812-46c8-8e9c-f1e9c9b8c3d5	24705f4b-8062-4e79-b2e8-373f8919f2fa	b5efb985-8956-4535-a11a-ca095b2717b4	4519	500333	2019-02-10	10.02.2019	ОВД района	паспорт одной строкой: серия 4519 номер 500333	5d8085e7-9311-432c-8d46-61ddf0008a7b
c1eec118-42de-4dd4-99e6-a7df0956507d	b545f08b-037e-4246-8c20-481f91097b7d	b5efb985-8956-4535-a11a-ca095b2717b4	4522	500444	2012-05-10	10.05.2012	ОВД района	паспорт одной строкой: серия 4522 номер 500444	5d8085e7-9311-432c-8d46-61ddf0008a7b
49ed3d02-e5d2-45dc-b02f-2d8777ff90ab	27c7b285-1b06-4e1b-854f-52acea9a3ad5	b5efb985-8956-4535-a11a-ca095b2717b4	4525	500555	2015-08-10	10.08.2015	ОВД района	паспорт одной строкой: серия 4525 номер 500555	5d8085e7-9311-432c-8d46-61ddf0008a7b
96483eee-6481-46e5-b6c4-e91e49e29ac9	878871b9-bfcc-4946-baa0-4acf54f6c4b1	b5efb985-8956-4535-a11a-ca095b2717b4	4528	500666	2018-03-10	10.03.2018	ОВД района	паспорт одной строкой: серия 4528 номер 500666	5d8085e7-9311-432c-8d46-61ddf0008a7b
3921a03a-895e-4903-807c-4f9391ff416f	06ac479a-edda-4596-9bb0-9deb06e869a8	b5efb985-8956-4535-a11a-ca095b2717b4	4516	654321	2016-04-01	01.04.2016	4516 654321 выдан ОУФМС России по р-ну Печатники г.Москвы 01.04.2016 к/п 770-007	4516 654321 выдан ОУФМС России по р-ну Печатники г.Москвы 01.04.2016 к/п 770-007	5d8085e7-9311-432c-8d46-61ddf0008a7b
b1ea1417-082a-4e34-81ac-bee8f42c2221	ea3eb759-6095-4565-98d0-0fd031f58fcb	b5efb985-8956-4535-a11a-ca095b2717b4	4513	123789	2012-08-20	20.08.2012	серия 4513 № 123789, ОВД Академический г.Москвы, дата 20.08.2012	серия 4513 № 123789, ОВД Академический г.Москвы, дата 20.08.2012	5d8085e7-9311-432c-8d46-61ddf0008a7b
7bf308be-40b4-4011-bced-4e1303f19b81	0ad7b981-2af7-472f-99f9-69ce294b9abd	b5efb985-8956-4535-a11a-ca095b2717b4	4512	998877	2012-09-12	12.09.2012	45 12 998877 ОВД района Бибирево г.Москвы 12.09.2012	45 12 998877 ОВД района Бибирево г.Москвы 12.09.2012	5d8085e7-9311-432c-8d46-61ddf0008a7b
e85432a4-3e69-4871-bb22-fc5e1bd91588	0ad7b981-2af7-472f-99f9-69ce294b9abd	b5efb985-8956-4535-a11a-ca095b2717b4	4508	789012	2008-06-01	01.06.2008	Серия:45 08 Номер:789012, Кем выдан: ОФМС района Измайлово г.Москвы, Дата:01.06.2008	Серия:45 08 Номер:789012, Кем выдан: ОФМС района Измайлово г.Москвы, Дата:01.06.2008	5d8085e7-9311-432c-8d46-61ddf0008a7b
b7e0a671-215d-4c4d-9fca-ace5a7097b64	19980952-8d8b-4cc1-9358-72a785bd48e2	b5efb985-8956-4535-a11a-ca095b2717b4	4509	112233	2009-04-20	20.04.2009	4509 112233 ОУФМС России 77 рег. 20.04.2009 770-043	4509 112233 ОУФМС России 77 рег. 20.04.2009 770-043	5d8085e7-9311-432c-8d46-61ddf0008a7b
ba07fa30-dd72-4cbd-8e0b-97d385da9be8	fd592784-4d39-47d2-b247-a4a557add4d7	b5efb985-8956-4535-a11a-ca095b2717b4	4014	876543	2014-03-15	15-03-2014	40 14 876543 / ОУФМС Тверской / 15-03-2014 / к/п 770-013	40 14 876543 / ОУФМС Тверской / 15-03-2014 / к/п 770-013	5d8085e7-9311-432c-8d46-61ddf0008a7b
c1e31e2e-0297-4313-9bdf-341533e94e35	fd592784-4d39-47d2-b247-a4a557add4d7	b5efb985-8956-4535-a11a-ca095b2717b4	4515	567890	2015-12-15	15.12.2015	с.4515 н.567890 выд.15.12.2015 УФМС по г.СПб и ЛО по Адмиралтейскому р-ну	с.4515 н.567890 выд.15.12.2015 УФМС по г.СПб и ЛО по Адмиралтейскому р-ну	5d8085e7-9311-432c-8d46-61ddf0008a7b
abc066a6-561d-47e7-95e6-a68c7b3809bf	6e107408-70b2-4de9-8205-f5af46476a63	b5efb985-8956-4535-a11a-ca095b2717b4	4516	4516123	2016-07-15	2016-07-15	4516123456,ОУФМС по ЗАО г.Москвы,2016-07-15	4516123456,ОУФМС по ЗАО г.Москвы,2016-07-15	5d8085e7-9311-432c-8d46-61ddf0008a7b
2502b15c-e7c5-4dd0-8a66-8f8455a56606	19980952-8d8b-4cc1-9358-72a785bd48e2	739ff378-3ba0-443f-b745-99b6375fc676	УТ	445566	2019-05-15	15.05.2019	77УТ 445566 выд. 15.05.2019 ГИБДД УМВД России по г.Ростов-на-Дону кат. B,C	77УТ 445566 выд. 15.05.2019 ГИБДД УМВД России по г.Ростов-на-Дону кат. B,C	5d8085e7-9311-432c-8d46-61ddf0008a7b
3cd0e40c-c8a0-4775-af24-2621838e317f	b1c3dde5-9ccc-4b5f-891c-57ebeece11c8	b5efb985-8956-4535-a11a-ca095b2717b4	4510	334455	\N	10 номер 3344	серия 4510 номер 334455 ОУФМС СВАО Москвы 20.03.2010	серия 4510 номер 334455 ОУФМС СВАО Москвы 20.03.2010	5d8085e7-9311-432c-8d46-61ddf0008a7b
e3615c3c-b2f0-471d-9165-a7304bae4d2a	6e107408-70b2-4de9-8205-f5af46476a63	b5efb985-8956-4535-a11a-ca095b2717b4	4514	223344	2014-06-10	10.06.2014	45 14 223344 ФКУ ГИАЦ МВД России 10.06.2014	45 14 223344 ФКУ ГИАЦ МВД России 10.06.2014	5d8085e7-9311-432c-8d46-61ddf0008a7b
59aa71cc-4354-4f0d-b3bf-356841530ead	162f794a-bac5-490a-acf5-160eb22fa716	b5efb985-8956-4535-a11a-ca095b2717b4	4512	887766	2012-08-01	01.08.2012	4512 887766 УФМС ПО Г.КАЗАНИ 01.08.2012	4512 887766 УФМС ПО Г.КАЗАНИ 01.08.2012	5d8085e7-9311-432c-8d46-61ddf0008a7b
6bc05936-a5ea-4767-9534-e843461eb31c	995c7b75-4104-41cc-8946-fe53c81de20c	739ff378-3ba0-443f-b745-99b6375fc676	ХА	123456	\N	77 ХА 1234	77 ХА 123456 2005-11-01 УГИБДД ГУВД г.Москвы A,B	77 ХА 123456 2005-11-01 УГИБДД ГУВД г.Москвы A,B	5d8085e7-9311-432c-8d46-61ddf0008a7b
52b56657-c1d3-45a3-8f9f-4096fb585170	f6c206fc-7f72-4a7f-beaa-035ec5b65aa3	b5efb985-8956-4535-a11a-ca095b2717b4	4509	556677	2009-06-15	15.06.2009	4509 556677, ОУФМС по р-ну Коньково г.Москвы, 15.06.2009, к/п 770-091	4509 556677, ОУФМС по р-ну Коньково г.Москвы, 15.06.2009, к/п 770-091	5d8085e7-9311-432c-8d46-61ddf0008a7b
2a40477d-4507-461f-b41d-74d54837cd81	3fde298b-7536-4b09-a828-87223b009b1c	65e8aec1-d43c-4f80-8306-573c76fe4ef6	MD	1234567	2019-03-01	01.03.2019	MD серия MS номер 1234567 выдан 01.03.2019 истекает 01.03.2029 Кишинёв	MD серия MS номер 1234567 выдан 01.03.2019 истекает 01.03.2029 Кишинёв	5d8085e7-9311-432c-8d46-61ddf0008a7b
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

\unrestrict tsvBsatE254EclAJvf0DnmdBFqXrOpdPCNUoG2jskMnTui1d5lgCoSIh7bNbwJS

