# BD Person Migration Project

Учебный проект по миграции персональных данных объекта "Человек" между базами данных партнеров.

Предметная область целевой БД: человек как покупатель маркетплейса техники.

## Структура проекта

```text
BD2-dump-1/
  05_source_db_export.sql       -- фактический SQL-дамп/скрипт исходной БД партнера
  target_subject_area.txt       -- описание БД партнера

sql/
  schema.sql                    -- бизнес-схема целевой БД
  functions.sql                 -- функции основной БД
  seed.sql                      -- справочники и тестовые данные нашей БД
  load_partner_source_to_map.sql -- загрузка данных партнера в map-схему
  migration_schema.sql          -- map-таблицы, migration_log и функции миграции
  run_partner_migration.sql     -- полный успешный прогон миграции
  run_partner_migration_error_demo.sql -- прогон с демонстрационными error-строками

dumps/
  marketplace_person_partner.sql/.dump -- дамп нашей БД для партнера
  migration_test_after_partner.sql/.dump -- внутренний дамп после тестовой миграции
  migration_error_demo.sql/.dump -- внутренний дамп после error-demo прогона

diagrams/
  person_business_er.png/.dot   -- ER целевой бизнес-БД
  partner_source_er.png/.dot    -- ER фактической исходной БД партнера

docs/
  subject_area.md
  partner_database_description.md
  migration_analysis.md
  er-description.md
```
