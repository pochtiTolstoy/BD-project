drop table if exists user_attribute_value cascade;
drop table if exists user_consent cascade;
drop table if exists user_verification_document cascade;
drop table if exists person_identifier cascade;
drop table if exists user_address cascade;
drop table if exists user_contact cascade;
drop table if exists user_account cascade;
drop table if exists person_profile cascade;

drop table if exists user_attribute_type cascade;
drop table if exists dict_consent_type cascade;
drop table if exists dict_verification_status cascade;
drop table if exists dict_document_type cascade;
drop table if exists dict_identifier_type cascade;
drop table if exists dict_street cascade;
drop table if exists dict_city cascade;
drop table if exists dict_region cascade;
drop table if exists dict_country cascade;
drop table if exists dict_address_type cascade;
drop table if exists dict_contact_type cascade;
drop table if exists dict_account_status cascade;
drop table if exists dict_gender cascade;

create extension if not exists pgcrypto;

create table dict_gender (
    gender_id uuid primary key default gen_random_uuid(),
    code text not null unique,
    name text not null
);

create table dict_account_status (
    account_status_id uuid primary key default gen_random_uuid(),
    code text not null unique,
    name text not null
);

create table dict_contact_type (
    contact_type_id uuid primary key default gen_random_uuid(),
    code text not null unique,
    name text not null
);

create table dict_address_type (
    address_type_id uuid primary key default gen_random_uuid(),
    code text not null unique,
    name text not null
);

create table dict_country (
    country_id uuid primary key default gen_random_uuid(),
    iso_code text unique,
    name text not null unique
);

create table dict_region (
    region_id uuid primary key default gen_random_uuid(),
    country_id uuid not null references dict_country(country_id),
    name text not null,
    unique (country_id, name)
);

create table dict_city (
    city_id uuid primary key default gen_random_uuid(),
    region_id uuid not null references dict_region(region_id),
    name text not null,
    unique (region_id, name)
);

create table dict_street (
    street_id uuid primary key default gen_random_uuid(),
    city_id uuid not null references dict_city(city_id),
    name text not null,
    unique (city_id, name)
);

create table dict_identifier_type (
    identifier_type_id uuid primary key default gen_random_uuid(),
    code text not null unique,
    name text not null
);

create table dict_document_type (
    document_type_id uuid primary key default gen_random_uuid(),
    code text not null unique,
    name text not null
);

create table dict_verification_status (
    verification_status_id uuid primary key default gen_random_uuid(),
    code text not null unique,
    name text not null
);

create table dict_consent_type (
    consent_type_id uuid primary key default gen_random_uuid(),
    code text not null unique,
    name text not null,
    description text
);

create table user_attribute_type (
    attribute_type_id uuid primary key default gen_random_uuid(),
    code text not null unique,
    name text not null,
    value_type text not null check (value_type in ('text', 'number', 'date', 'bool', 'json')),
    description text
);

create table person_profile (
    person_id uuid primary key default gen_random_uuid(),
    last_name text not null,
    first_name text not null,
    middle_name text,
    birth_date date,
    birth_date_raw text,
    gender_id uuid references dict_gender(gender_id),
    created_at timestamptz not null default now(),
    unique (last_name, first_name, middle_name, birth_date)
);

create table user_account (
    account_id uuid primary key default gen_random_uuid(),
    person_id uuid not null unique references person_profile(person_id) on delete cascade,
    login text not null unique,
    password_hash text,
    account_status_id uuid not null references dict_account_status(account_status_id),
    registered_at timestamptz not null default now(),
    last_login_at timestamptz
);

create table user_contact (
    contact_id uuid primary key default gen_random_uuid(),
    person_id uuid not null references person_profile(person_id) on delete cascade,
    contact_type_id uuid not null references dict_contact_type(contact_type_id),
    contact_value text not null,
    raw_value text,
    is_primary boolean not null default false,
    is_verified boolean not null default false,
    created_at timestamptz not null default now(),
    unique (person_id, contact_type_id, contact_value)
);

create table user_address (
    address_id uuid primary key default gen_random_uuid(),
    person_id uuid not null references person_profile(person_id) on delete cascade,
    address_type_id uuid not null references dict_address_type(address_type_id),
    country_id uuid references dict_country(country_id),
    region_id uuid references dict_region(region_id),
    city_id uuid references dict_city(city_id),
    street_id uuid references dict_street(street_id),
    house text,
    building text,
    flat text,
    postal_code text,
    raw_address text,
    is_default boolean not null default false
);

create table person_identifier (
    identifier_id uuid primary key default gen_random_uuid(),
    person_id uuid not null references person_profile(person_id) on delete cascade,
    identifier_type_id uuid not null references dict_identifier_type(identifier_type_id),
    identifier_value text not null,
    raw_value text,
    is_verified boolean not null default false,
    unique (identifier_type_id, identifier_value)
);

create table user_verification_document (
    document_id uuid primary key default gen_random_uuid(),
    person_id uuid not null references person_profile(person_id) on delete cascade,
    document_type_id uuid not null references dict_document_type(document_type_id),
    series text,
    number text,
    issue_date date,
    issue_date_raw text,
    issued_by text,
    raw_document_text text,
    verification_status_id uuid not null references dict_verification_status(verification_status_id)
);

create table user_consent (
    consent_id uuid primary key default gen_random_uuid(),
    person_id uuid not null references person_profile(person_id) on delete cascade,
    consent_type_id uuid not null references dict_consent_type(consent_type_id),
    is_granted boolean not null,
    granted_at timestamptz,
    revoked_at timestamptz,
    source text,
    raw_value text,
    unique (person_id, consent_type_id)
);

create table user_attribute_value (
    attribute_value_id uuid primary key default gen_random_uuid(),
    person_id uuid not null references person_profile(person_id) on delete cascade,
    attribute_type_id uuid not null references user_attribute_type(attribute_type_id),
    value_text text,
    value_number numeric,
    value_date date,
    value_bool boolean,
    value_json jsonb,
    raw_value text,
    unique (person_id, attribute_type_id)
);

create unique index person_profile_natural_uidx
on person_profile (
    lower(last_name),
    lower(first_name),
    coalesce(lower(middle_name), ''),
    birth_date
)
where birth_date is not null;

create unique index user_address_dedupe_uidx
on user_address (
    person_id,
    address_type_id,
    coalesce(country_id, '00000000-0000-0000-0000-000000000000'::uuid),
    coalesce(region_id, '00000000-0000-0000-0000-000000000000'::uuid),
    coalesce(city_id, '00000000-0000-0000-0000-000000000000'::uuid),
    coalesce(street_id, '00000000-0000-0000-0000-000000000000'::uuid),
    coalesce(house, ''),
    coalesce(building, ''),
    coalesce(flat, ''),
    coalesce(postal_code, ''),
    coalesce(raw_address, '')
);

create unique index user_verification_document_dedupe_uidx
on user_verification_document (
    person_id,
    document_type_id,
    coalesce(series, ''),
    coalesce(number, ''),
    coalesce(raw_document_text, '')
);
