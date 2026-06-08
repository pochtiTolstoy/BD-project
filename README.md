# BD Person Migration Project

Учебный проект по миграции персональных данных объекта "Человек" между базами данных партнеров.

Предметная область целевой БД: человек как покупатель маркетплейса техники.

Финальный отчет, ER-диаграммы и скриншоты прикладываются отдельно. В этом репозитории оставлены только SQL-скрипты, исходные данные партнера и дамп нашей БД для обмена.

## Структура проекта

```text
BD2-dump-1/
  05_source_db_export.sql        -- фактический SQL-скрипт исходной БД партнера
  target_subject_area.txt        -- описание БД партнера

sql/
  schema.sql                     -- бизнес-схема нашей БД
  functions.sql                  -- функции основной БД
  seed.sql                       -- справочники и тестовые данные нашей БД
  load_partner_source_to_map.sql -- загрузка БД партнера в отдельную map-схему
  migration_schema.sql           -- таблицы и функции миграционного слоя
  run_partner_migration.sql      -- полный успешный прогон миграции
  run_partner_migration_error_demo.sql -- прогон с демонстрацией error-строк

dumps/
  marketplace_person_partner.sql -- plain SQL дамп нашей БД для партнера
  marketplace_person_partner.dump -- custom-format дамп нашей БД для партнера
```

## Требования

- PostgreSQL 16+ или совместимая версия.
- Расширение `pgcrypto`, создается автоматически в `sql/schema.sql`.

## Запуск основной миграции

Создать тестовую базу:

```bash
dropdb --if-exists migration_test_after_partner
createdb migration_test_after_partner
```

Запустить полный сценарий:

```bash
psql -d migration_test_after_partner -v ON_ERROR_STOP=1 -f sql/run_partner_migration.sql
```

Ожидаемые статусы:

```text
success: 13
warning: 12
```

Ожидаемые метрики:

```text
source_customers: 25
migrated_links: 25
target_persons_total: 37
migration_log_rows: 25
unmapped_attributes: 25
```

## Демонстрация ошибок

Создать отдельную базу:

```bash
dropdb --if-exists migration_error_demo
createdb migration_error_demo
```

Запустить сценарий с двумя намеренно некорректными строками:

```bash
psql -d migration_error_demo -v ON_ERROR_STOP=1 -f sql/run_partner_migration_error_demo.sql
```

Ожидаемые статусы:

```text
success: 13
warning: 12
skipped: 25
error: 2
```

Error-строки нужны для демонстрации обработки ошибок в `map.migration_log`.

## Дамп для партнера

Партнеру можно отправить один из файлов:

```text
dumps/marketplace_person_partner.sql
dumps/marketplace_person_partner.dump
```

Восстановление plain SQL дампа:

```bash
psql -f dumps/marketplace_person_partner.sql
```

Восстановление custom-format дампа:

```bash
pg_restore -d postgres --clean --if-exists --create --no-owner --no-privileges dumps/marketplace_person_partner.dump
```
