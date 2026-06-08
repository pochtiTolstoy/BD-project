\set ON_ERROR_STOP on

\i sql/schema.sql
\i sql/functions.sql
\i sql/seed.sql
\i sql/load_partner_source_to_map.sql
\i sql/migration_schema.sql

select map.migrate_partner_customers() as migration_run_id;

select status, count(*)
from map.migration_log
group by status
order by status;

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
