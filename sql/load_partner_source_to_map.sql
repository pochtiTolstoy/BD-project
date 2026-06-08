create schema if not exists map;
set search_path to map, public;
\i BD2-dump-1/05_source_db_export.sql
set search_path to public;
