# Описание базы данных для обмена

## Назначение базы

База данных описывает объект "Человек" в предметной области маркетплейса техники.

Под человеком понимается покупатель маркетплейса. Модель хранит данные о профиле покупателя, аккаунте, контактах, адресах, идентификаторах, документах для опциональной верификации, согласиях и дополнительных покупательских признаках.

Товары, заказы, корзина, складские остатки, доставка как бизнес-процесс и платежи в эту модель не входят.

## Состав дампа

Для обмена предназначены файлы:

```text
dumps/marketplace_person_partner.sql
dumps/marketplace_person_partner.dump
```

Оба файла содержат одну и ту же бизнес-БД:

- структуру таблиц;
- справочники;
- функции основной БД;
- тестовые данные покупателей.

Файл `.sql` удобен для просмотра и восстановления через `psql`.

Файл `.dump` является PostgreSQL custom-format дампом и удобен для восстановления через `pg_restore`.

Дамп не содержит миграционные таблицы и результаты тестовой миграции из другой БД. Миграционный слой проектируется отдельно при переносе данных партнера.

## Основные сущности

Центральная таблица:

```text
person_profile
```

Она хранит базовые данные человека:

- ФИО;
- дату рождения;
- исходное значение даты рождения, если дата была грязной или неоднозначной;
- пол через справочник.

Связанные таблицы:

- `user_account` - аккаунт покупателя в маркетплейсе;
- `user_contact` - контакты покупателя: email, телефон, мессенджер и другие каналы связи;
- `user_address` - адреса покупателя;
- `person_identifier` - идентификаторы человека, например ИНН или СНИЛС;
- `user_verification_document` - документы для опциональной проверки личности;
- `user_consent` - согласия пользователя;
- `user_attribute_value` - гибкие дополнительные признаки покупателя техники.

## Справочники

В модели используются отдельные таблицы-справочники:

- `dict_gender`;
- `dict_account_status`;
- `dict_contact_type`;
- `dict_address_type`;
- `dict_country`;
- `dict_region`;
- `dict_city`;
- `dict_street`;
- `dict_identifier_type`;
- `dict_document_type`;
- `dict_verification_status`;
- `dict_consent_type`;
- `user_attribute_type`.

Адреса сделаны в snowflake-структуре:

```text
dict_country -> dict_region -> dict_city -> dict_street -> user_address
```

Это означает, что страна, регион, город и улица вынесены в отдельные связанные справочники.

## Гибкие признаки покупателя

Для дополнительных признаков используется business-EAV:

```text
user_attribute_type
user_attribute_value
```

`user_attribute_type` описывает тип признака, например любимую категорию техники, предпочитаемый бренд, бюджет покупки или интерес к рассрочке.

`user_attribute_value` хранит значение признака для конкретного человека.

Такой подход нужен потому, что дополнительные покупательские признаки могут отличаться от человека к человеку и не всегда являются обязательными.

## Количество тестовых данных

В текущем дампе находится 25 тестовых покупателей.

Данные специально включают разные случаи:

- нормальные заполненные профили;
- частично заполненные профили;
- несколько контактов у одного человека;
- адреса в структурированном и сыром виде;
- документы только у части покупателей;
- согласия с разными статусами;
- дополнительные EAV-признаки;
- грязные или неоднозначные значения, которые полезны для проверки миграции.

Все данные являются учебными тестовыми данными.

## Как восстановить дамп

### Вариант 1: восстановление из SQL-файла

```bash
psql -f dumps/marketplace_person_partner.sql
```

Если нужно явно указать базу:

```bash
psql -d postgres -f dumps/marketplace_person_partner.sql
```

SQL-дамп сам создает базу:

```text
marketplace_person
```

### Вариант 2: восстановление из custom dump

```bash
pg_restore -d postgres --clean --if-exists --create dumps/marketplace_person_partner.dump
```

Этот вариант удалит уже существующие объекты с такими же именами при восстановлении.

## Как посмотреть данные после восстановления

Подключиться к базе:

```bash
psql -d marketplace_person
```

Проверить список таблиц:

```sql
\dt
```

Посмотреть покупателей:

```sql
select person_id, last_name, first_name, middle_name, birth_date, birth_date_raw
from person_profile
order by created_at;
```

Посмотреть контакты:

```sql
select p.last_name, p.first_name, ct.code as contact_type, c.contact_value, c.raw_value
from user_contact c
join person_profile p on p.person_id = c.person_id
join dict_contact_type ct on ct.contact_type_id = c.contact_type_id
order by p.last_name, p.first_name;
```

Посмотреть дополнительные признаки:

```sql
select p.last_name, p.first_name, at.code as attribute_code,
       av.value_text, av.value_number, av.value_date, av.value_bool, av.raw_value
from user_attribute_value av
join person_profile p on p.person_id = av.person_id
join user_attribute_type at on at.attribute_type_id = av.attribute_type_id
order by p.last_name, p.first_name, at.code;
```

## Файлы схемы

Исходные SQL-файлы проекта:

```text
sql/schema.sql
sql/functions.sql
sql/seed.sql
```

ER-диаграмма:

```text
diagrams/person_business_er.png
diagrams/person_business_er.dot
```
