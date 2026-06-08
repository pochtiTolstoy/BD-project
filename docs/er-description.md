## Предметная область

Объект "Человек" в моей модели - покупатель маркетплейса техники.

Модель описывает только персональные данные покупателя: профиль, аккаунт, контакты, адреса доставки, документы для опциональной верификации, согласия и гибкие продуктовые атрибуты. Заказы, товары, корзина и платежи в эту ER-диаграмму не входят.

## ER-диаграмма

Файл актуальной диаграммы основной бизнес-БД:

```text
diagrams/person_business_er.png
```

Исходник актуальной диаграммы:

```text
diagrams/person_business_er.dot
```

Центральная сущность:

```text
person_profile
```

В модели один человек имеет один аккаунт маркетплейса:

```text
person_profile 1 : 1 user_account
```

Основные группы таблиц основной бизнес-БД:

- профиль человека: `person_profile`, `dict_gender`;
- аккаунт маркетплейса: `user_account`, `dict_account_status`;
- контакты: `user_contact`, `dict_contact_type`;
- идентификаторы: `person_identifier`, `dict_identifier_type`;
- адреса через snowflake: `dict_country -> dict_region -> dict_city -> dict_street -> user_address`;
- документы для опциональной верификации: `user_verification_document`, `dict_document_type`, `dict_verification_status`;
- согласия: `user_consent`, `dict_consent_type`;
- business-EAV для атрибутов покупателя техники: `user_attribute_type`, `user_attribute_value`.

Миграционный слой не входит в основную ER-диаграмму. Он будет проектироваться отдельно после получения структуры данных партнера.

## Шаблон процедуры

Основная процедура создания человека в моей интерпретации:

```sql
create_marketplace_customer(...)
```

Она создает покупателя маркетплейса техники и возвращает:

```sql
uuid -- person_id созданного человека
```

Физическая схема БД описана в файле:

```text
sql/schema.sql
```

Функции основной БД, включая входные параметры `create_marketplace_customer(...)`, описаны в файле:

```text
sql/functions.sql
```

Тестовые данные описаны в файле:

```text
sql/seed.sql
```
