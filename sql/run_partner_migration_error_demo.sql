\set ON_ERROR_STOP on

\i sql/run_partner_migration.sql

insert into map.customers (
    cust_id,
    fullname,
    birth_dt,
    sex,
    email,
    phone,
    phone2,
    inn,
    snils,
    marital,
    loyalty_lvl,
    login,
    reg_date,
    status,
    notes
)
values
    (
        9001,
        '',
        '1990-01-01',
        'М',
        'error.empty.fullname@example.ru',
        '+79990000001',
        null,
        null,
        null,
        null,
        'demo',
        'error_empty_fullname',
        '2026-06-07',
        'активен',
        'Демонстрационная ошибка: пустое ФИО'
    ),
    (
        9002,
        'Ошибка Без Логина',
        '1992-02-02',
        'Ж',
        'error.empty.login@example.ru',
        '+79990000002',
        null,
        null,
        null,
        null,
        'demo',
        null,
        '2026-06-07',
        'активен',
        'Демонстрационная ошибка: пустой login'
    );

select map.migrate_partner_customers() as error_demo_migration_run_id;

select status, count(*)
from map.migration_log
group by status
order by status;

select
    source_record_id,
    status,
    stage,
    error_code,
    error_message
from map.migration_log
where status = 'error'
order by created_at, source_record_id;

select 'source_customers' as metric, count(*) from map.customers
union all
select 'migrated_links', count(*) from map.migration_person_link
union all
select 'target_persons_total', count(*) from person_profile
union all
select 'migration_log_rows', count(*) from map.migration_log
union all
select 'unmapped_attributes', count(*) from map.migration_unmapped_attribute
order by metric;
