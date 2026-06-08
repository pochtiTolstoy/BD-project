insert into dict_gender (code, name) values
    ('MALE', 'Мужской'),
    ('FEMALE', 'Женский'),
    ('UNKNOWN', 'Не указан');

insert into dict_account_status (code, name) values
    ('ACTIVE', 'Активен'),
    ('BLOCKED', 'Заблокирован'),
    ('DELETED', 'Удален'),
    ('PENDING', 'Ожидает подтверждения');

insert into dict_contact_type (code, name) values
    ('EMAIL', 'Email'),
    ('PHONE', 'Телефон'),
    ('TELEGRAM', 'Telegram'),
    ('WHATSAPP', 'WhatsApp');

insert into dict_address_type (code, name) values
    ('DELIVERY', 'Адрес доставки'),
    ('HOME', 'Домашний адрес'),
    ('PICKUP', 'Пункт выдачи');

insert into dict_identifier_type (code, name) values
    ('INN', 'ИНН'),
    ('SNILS', 'СНИЛС'),
    ('LOYALTY_CARD', 'Карта лояльности');

insert into dict_document_type (code, name) values
    ('PASSPORT_RF', 'Паспорт РФ'),
    ('DRIVER_LICENSE', 'Водительское удостоверение'),
    ('MILITARY_ID', 'Военный билет'),
    ('FOREIGN_PASSPORT', 'Заграничный паспорт');

insert into dict_verification_status (code, name) values
    ('NOT_CHECKED', 'Не проверен'),
    ('PENDING', 'На проверке'),
    ('VERIFIED', 'Проверен'),
    ('REJECTED', 'Отклонен');

insert into dict_consent_type (code, name, description) values
    ('PERSONAL_DATA_PROCESSING', 'Обработка персональных данных', 'Согласие на хранение и обработку персональных данных покупателя'),
    ('MARKETING_EMAIL', 'Email-рассылка', 'Согласие на рекламные письма'),
    ('MARKETING_SMS', 'SMS-рассылка', 'Согласие на рекламные SMS'),
    ('DATA_TRANSFER_TO_PARTNERS', 'Передача данных партнерам', 'Согласие на передачу данных службам доставки и партнерам');

insert into user_attribute_type (code, name, value_type, description) values
    ('FAVORITE_TECH_CATEGORY', 'Любимая категория техники', 'text', 'Например смартфоны, ноутбуки, умный дом'),
    ('PREFERRED_BRAND', 'Предпочитаемый бренд', 'text', 'Маркетинговое предпочтение покупателя'),
    ('INSTALLMENT_INTEREST', 'Интерес к рассрочке', 'bool', 'Покупатель интересуется рассрочкой'),
    ('AVG_ORDER_BUDGET', 'Средний бюджет заказа', 'number', 'Примерный бюджет покупки техники'),
    ('HAS_SMART_HOME', 'Есть устройства умного дома', 'bool', 'Гибкий признак покупателя техники'),
    ('DEVICE_ECOSYSTEM', 'Экосистема устройств', 'text', 'Apple, Android, Windows, mixed'),
    ('LOYALTY_LEVEL', 'Уровень лояльности', 'text', 'basic, silver, gold'),
    ('BIOMETRIC_FACE_REF', 'Ссылка на биометрический шаблон лица', 'text', 'Опциональная ссылка на внешний биометрический шаблон');

select create_marketplace_customer(
    p_last_name := 'Иванов',
    p_first_name := 'Иван',
    p_middle_name := 'Иванович',
    p_login := 'ivanov.tech',
    p_birth_date_raw := '5 января 1990 года',
    p_gender_code := 'MALE',
    p_contacts := '[
        {"type":"EMAIL","value":"ivanov@example.ru","raw_value":"ivanov@example.ru, i.ivanov@oldmail.ru","is_primary":true,"is_verified":true},
        {"type":"PHONE","value":"+79991234567","raw_value":"+7 (999) 123-45-67 / tg: @ivan_tech","is_primary":true,"is_verified":false},
        {"type":"TELEGRAM","value":"@ivan_tech","raw_value":"+7 (999) 123-45-67 / tg: @ivan_tech"}
    ]'::jsonb,
    p_addresses := '[
        {"type":"DELIVERY","country":"Россия","region":"Москва","city":"Москва","street":"Тверская","house":"12","flat":"45","postal_code":"125009","raw_address":"Москва, Тверская 12 кв 45, домофон не работает","is_default":true}
    ]'::jsonb,
    p_identifiers := '[
        {"type":"INN","value":" 7701-234567-89 ","raw_value":"ИНН: 7701-234567-89","is_verified":false},
        {"type":"SNILS","value":"123-456-789 00","raw_value":"123-456-789 00","is_verified":false}
    ]'::jsonb,
    p_documents := '[
        {"type":"PASSPORT_RF","series":"4510","number":"123456","issue_date_raw":"10.02.2018","issued_by":"ОВД Тверского района","raw_document_text":"4510 123456 выдан ОВД Тверского района 10.02.2018","verification_status":"VERIFIED"}
    ]'::jsonb,
    p_consents := '[
        {"type":"PERSONAL_DATA_PROCESSING","is_granted":true,"granted_at":"2026-05-06 10:00:00+03","source":"web_form","raw_value":"согласен на обработку ПД"},
        {"type":"MARKETING_EMAIL","is_granted":true,"granted_at":"2026-05-06 10:00:00+03","source":"web_form","raw_value":"да, хочу скидки"}
    ]'::jsonb,
    p_attributes := '{"FAVORITE_TECH_CATEGORY":"смартфоны","PREFERRED_BRAND":"Samsung","INSTALLMENT_INTEREST":true,"AVG_ORDER_BUDGET":65000,"HAS_SMART_HOME":true,"DEVICE_ECOSYSTEM":"Android","LOYALTY_LEVEL":"gold"}'::jsonb
);

select create_marketplace_customer(
    p_last_name := 'Петрова',
    p_first_name := 'Мария',
    p_login := 'm.pet.rova@example.com',
    p_birth_date_raw := '01.05.90',
    p_gender_code := 'FEMALE',
    p_contacts := '[
        {"type":"EMAIL","value":"m.pet.rova@example.com","raw_value":"m.pet.rova@example.com; petrova.work@example.org","is_primary":true},
        {"type":"EMAIL","value":"petrova.work@example.org","raw_value":"m.pet.rova@example.com; petrova.work@example.org"},
        {"type":"PHONE","value":"+79161230000","raw_value":"8-916-123-00-00"}
    ]'::jsonb,
    p_addresses := '[
        {"type":"DELIVERY","country":"Россия","region":"Московская область","city":"Химки","street":"Молодежная","house":"7","building":"2","flat":"101","raw_address":"МО, г Химки, Молодежная 7к2, 101"}
    ]'::jsonb,
    p_documents := '[
        {"type":"DRIVER_LICENSE","series":"77AA","number":"654321","issue_date_raw":"2019-03-15","issued_by":"ГИБДД Москва","raw_document_text":"ВУ 77AA 654321 от 2019-03-15","verification_status":"PENDING"}
    ]'::jsonb,
    p_consents := '[
        {"type":"PERSONAL_DATA_PROCESSING","is_granted":true,"granted_at":"2026-05-07 12:20:00+03","source":"mobile_app","raw_value":"+"},
        {"type":"MARKETING_SMS","is_granted":false,"source":"mobile_app","raw_value":"sms: нет"}
    ]'::jsonb,
    p_attributes := '{"FAVORITE_TECH_CATEGORY":"ноутбуки","PREFERRED_BRAND":"Apple","INSTALLMENT_INTEREST":false,"AVG_ORDER_BUDGET":120000,"DEVICE_ECOSYSTEM":"Apple","LOYALTY_LEVEL":"silver"}'::jsonb
);

select create_marketplace_customer(
    p_last_name := 'Сидоров',
    p_first_name := 'Алексей',
    p_middle_name := 'Павлович',
    p_login := 'alexey.sid',
    p_birth_date_raw := '1995-12-03',
    p_gender_code := 'MALE',
    p_contacts := '[
        {"type":"EMAIL","value":"bad-email-without-at","raw_value":"bad-email-without-at, alexey.sid@mail.ru","is_primary":true},
        {"type":"EMAIL","value":"alexey.sid@mail.ru","raw_value":"bad-email-without-at, alexey.sid@mail.ru"},
        {"type":"WHATSAPP","value":"+79260001122","raw_value":"whatsapp +7 926 000 11 22"}
    ]'::jsonb,
    p_addresses := '[
        {"type":"DELIVERY","country":"Россия","region":"Санкт-Петербург","city":"Санкт-Петербург","street":"Невский проспект","house":"1","flat":"8","raw_address":"СПб Невский 1-8"}
    ]'::jsonb,
    p_identifiers := '[
        {"type":"LOYALTY_CARD","value":"TECH-00077","raw_value":"карта TECH-00077","is_verified":true}
    ]'::jsonb,
    p_documents := '[
        {"type":"PASSPORT_RF","series":"4012","number":"777888","issue_date_raw":"20 марта 2016 года","issued_by":"ТП №1","raw_document_text":"паспорт 4012 777888 кем и когда выдан: ТП №1 20 марта 2016 года","verification_status":"NOT_CHECKED"}
    ]'::jsonb,
    p_consents := '[
        {"type":"PERSONAL_DATA_PROCESSING","is_granted":true,"granted_at":"2026-05-08 09:00:00+03","source":"call_center","raw_value":"оператор отметил согласие"}
    ]'::jsonb,
    p_attributes := '{"FAVORITE_TECH_CATEGORY":"игровые консоли","PREFERRED_BRAND":"Sony","INSTALLMENT_INTEREST":true,"AVG_ORDER_BUDGET":80000,"HAS_SMART_HOME":false,"LOYALTY_LEVEL":"basic"}'::jsonb
);

select create_marketplace_customer(
    p_last_name := 'Кузнецова',
    p_first_name := 'Елена',
    p_login := 'elena_k',
    p_birth_date_raw := '31/02/1988',
    p_gender_code := 'FEMALE',
    p_contacts := '[
        {"type":"PHONE","value":"+79035556677","raw_value":"тел. 9035556677"},
        {"type":"TELEGRAM","value":"@elena_devices","raw_value":"telegram: @elena_devices"}
    ]'::jsonb,
    p_addresses := '[
        {"type":"HOME","country":"Россия","region":"Татарстан","city":"Казань","street":"Баумана","house":"5","flat":"12","postal_code":"420111","raw_address":"Казань, Баумана 5, квартира 12"}
    ]'::jsonb,
    p_documents := '[
        {"type":"MILITARY_ID","series":"МК","number":"009988","issue_date_raw":"01.01.20","issued_by":"военкомат","raw_document_text":"МК 009988 военкомат 01.01.20","verification_status":"REJECTED"}
    ]'::jsonb,
    p_consents := '[
        {"type":"PERSONAL_DATA_PROCESSING","is_granted":true,"source":"paper_form","raw_value":"бумажная анкета: да"},
        {"type":"DATA_TRANSFER_TO_PARTNERS","is_granted":true,"source":"paper_form","raw_value":"передача партнерам: согласна"}
    ]'::jsonb,
    p_attributes := '{"FAVORITE_TECH_CATEGORY":"умный дом","PREFERRED_BRAND":"Xiaomi","INSTALLMENT_INTEREST":true,"AVG_ORDER_BUDGET":30000,"HAS_SMART_HOME":true,"DEVICE_ECOSYSTEM":"mixed","BIOMETRIC_FACE_REF":"face-template://legacy/4451"}'::jsonb
);

select create_marketplace_customer(
    p_last_name := 'Орлов',
    p_first_name := 'Денис',
    p_login := 'denis.orlov@example.net',
    p_birth_date_raw := null,
    p_gender_code := 'UNKNOWN',
    p_contacts := '[
        {"type":"EMAIL","value":"denis.orlov@example.net","is_primary":true,"is_verified":true}
    ]'::jsonb,
    p_addresses := '[
        {"type":"PICKUP","country":"Россия","region":"Новосибирская область","city":"Новосибирск","street":"Красный проспект","house":"30","raw_address":"ПВЗ Новосибирск Красный 30"}
    ]'::jsonb,
    p_consents := '[
        {"type":"PERSONAL_DATA_PROCESSING","is_granted":true,"granted_at":"2026-05-09 17:45:00+03","source":"web_form","raw_value":"accepted"}
    ]'::jsonb,
    p_attributes := '{"FAVORITE_TECH_CATEGORY":"комплектующие","PREFERRED_BRAND":"AMD","INSTALLMENT_INTEREST":false,"AVG_ORDER_BUDGET":45000,"LOYALTY_LEVEL":"basic"}'::jsonb
);

with extra_customers (
    ord,
    last_name,
    first_name,
    middle_name,
    login,
    birth_date_raw,
    gender_code,
    email,
    raw_email,
    phone,
    region_name,
    city_name,
    street_name,
    house,
    flat,
    tech_category,
    brand,
    budget,
    installment_interest
) as (
    values
        (1,  'Смирнов',   'Павел',     'Олегович',    'p.smirnov.tech',       '1989/04/12',            'MALE',    'p.smirnov@example.ru',       'p.smirnov@example.ru, smirnov.old@mail.ru',       '+7 (916) 100-20-30', 'Москва',                'Москва',          'Арбат',              '10', '15',  'ноутбуки',          'Lenovo',  90000,  true),
        (2,  'Васильева', 'Ольга',     'Игоревна',    'olga.v.tech',          '12.09.1991',            'FEMALE',  'olga.v@example.ru',          'olga.v@example.ru',                                '8-926-222-33-44',   'Московская область',   'Подольск',        'Садовая',            '5',  '7',   'смартфоны',         'Apple',   110000, false),
        (3,  'Никитин',   'Роман',     null,          'roman_nikitin',        '7 ноября 1984 года',    'MALE',    'roman.n@example.ru',         'roman.n@example.ru; r.nikitin@work.ru',            '+7 812 333 44 55',  'Санкт-Петербург',      'Санкт-Петербург', 'Литейный проспект',  '44', '21',  'телевизоры',        'LG',      70000,  true),
        (4,  'Медведева', 'Ирина',     'Сергеевна',   'irina.medvedeva',      '03.03.03',              'FEMALE',  'irina.m@example.ru',         'irina.m@example.ru',                                '9035556677',        'Татарстан',            'Казань',          'Кремлевская',        '2',  '11',  'умный дом',         'Xiaomi',  35000,  true),
        (5,  'Алексеев',  'Григорий',  'Андреевич',   'g.alekseev',           '1978-10-30',            'MALE',    'g.alekseev@example.ru',      'g.alekseev@example.ru',                             '+7(383)123-45-67',  'Новосибирская область','Новосибирск',     'Карла Маркса',       '7',  '19',  'комплектующие',     'AMD',     55000,  false),
        (6,  'Романова',  'Дарья',     null,          'd.romanova',           'н/д',                   'FEMALE',  'd.romanova.example.ru',      'd.romanova.example.ru',                             '+7 495 777 88 99',  'Москва',                'Москва',          'Профсоюзная',        '88', '42',  'планшеты',          'Samsung', 50000,  true),
        (7,  'Гаврилов',  'Максим',    'Петрович',    'max.gavrilov',         '14-02-1982',            'MALE',    'max.g@example.ru',           'max.g@example.ru, gavrilov.max@mail.ru',            '8 800 555 35 35',   'Краснодарский край',    'Краснодар',       'Красная',            '135','3',   'игровые консоли',   'Sony',    78000,  true),
        (8,  'Егорова',   'Виктория',  'Алексеевна',  'v.egorova',            '1994-06-30',            'FEMALE',  'v.egorova@example.ru',       'v.egorova@example.ru',                              '+7-917-111-22-33',  'Ростовская область',    'Ростов-На-Дону',  'Большая Садовая',    '15', '304', 'фото',              'Canon',   65000,  false),
        (9,  'Павлов',    'Степан',    'Денисович',   'stepan.pavlov',        'March 5, 1991',         'MALE',    's.pavlov@example.ru',        's.pavlov@example.ru',                               '89161231212',       'Свердловская область',  'Екатеринбург',    'Малышева',           '51', '79',  'ноутбуки',          'HP',      60000,  false),
        (10, 'Фомина',    'Ксения',    null,          'ks.fomina',            '25/12/1970',            'FEMALE',  'ks.fomina@example.ru',       'ks.fomina@example.ru; k.fomina@old.ru',             '+7 921 000 11 22',  'Санкт-Петербург',      'Санкт-Петербург', 'Невский проспект',   '100','200', 'смартфоны',         'Huawei',  42000,  true),
        (11, 'Беляев',    'Матвей',    'Ильич',       'matvey.belyaev',       '2000-01-01',            'MALE',    'matvey.b@example.ru',        'matvey.b@example.ru',                               '+7 999 010 20 30',  'Москва',                'Москва',          'Тверская',           '1',  '8',   'наушники',          'Sony',    22000,  false),
        (12, 'Соловьева', 'Наталья',   'Романовна',   'n.solovieva',          '31/02/1988',            'FEMALE',  'n.solovieva@example.ru',     'n.solovieva@example.ru',                            '+7 903 444 55 66',  'Московская область',   'Химки',           'Юбилейный проспект', '78', '55',  'умный дом',         'Aqara',   28000,  true),
        (13, 'Титов',     'Арсений',   null,          'ars.titov',            '5 января 1991',         'MALE',    'ars.titov@example.ru',       'ars.titov@example.ru',                              '8(901)234-56-78',  'Москва',                'Москва',          'Лесной пер.',        '4',  null,  'комплектующие',     'Intel',   47000,  false),
        (14, 'Миронова',  'Алина',     'Дмитриевна',  'alina.mironova',       '30.06.1994',            'FEMALE',  'alina.m@example.ru',         'alina.m@example.ru',                                '+79269998877',      'Санкт-Петербург',      'Санкт-Петербург', 'Маршала Жукова',     '41', '22',  'бытовая техника',   'Bosch',   52000,  true),
        (15, 'Крылов',    'Федор',     'Вячеславович','fedor.krylov',         '1979-11-30',            'MALE',    'fedorkrylov.mail.ru',        'fedorkrylov.mail.ru',                               '+79123456789',      'Москва',                'Москва',          'Коньково',           '9',  '17',  'телевизоры',        'TCL',     33000,  false),
        (16, 'Зуева',     'Марина',    null,          'marina.zueva',         '15 августа 1967 года',  'FEMALE',  'm.zueva@example.ru',         'm.zueva@example.ru, marina.zueva@work.ru',          '8 800 333 44 55',   'Москва',                'Москва',          '4-й Лесной пер.',    '4',  null,  'смартфоны',         'Xiaomi',  39000,  true),
        (17, 'Ковалев',   'Антон',     'Михайлович',  'anton.kovalev',        null,                    'MALE',    'anton.k@example.ru',         'anton.k@example.ru',                                '+74951234567',      'Краснодарский край',    'Краснодар',       'Северная',           '20', '2',   'игровые консоли',   'Microsoft',85000,  true),
        (18, 'Макарова',  'Юлия',      'Олеговна',    'y.makarova',           '1985/03/15',            'FEMALE',  'y.makarova@example.ru',      'y.makarova@example.ru',                             '+7(863)222-33-44',  'Ростовская область',    'Ростов-На-Дону',  'Ленина',             '15', '304', 'ноутбуки',          'Asus',    95000,  false),
        (19, 'Дорофеев',  'Лев',       null,          'lev.dorofeev',         'ноябрь 1979',           'MALE',    'lev.d@example.ru',           'lev.d@example.ru',                                  '+7 812 333 44 56',  'Санкт-Петербург',      'Санкт-Петербург', 'Кронверкский пр-т',  '7',  '14',  'фото',              'Nikon',   73000,  true),
        (20, 'Борисова',  'Светлана',  'Игоревна',    's.borisova',           '04.07.1996',            'FEMALE',  's.borisova@example.ru',      's.borisova@example.ru',                             '8-926-123-45-67',  'Москва',                'Москва',          'Тверская',           '12', '45',  'умный дом',         'Яндекс',  25000,  false)
)
select create_marketplace_customer(
    p_last_name := last_name,
    p_first_name := first_name,
    p_middle_name := middle_name,
    p_login := login,
    p_birth_date_raw := birth_date_raw,
    p_gender_code := gender_code,
    p_contacts := jsonb_build_array(
        jsonb_build_object('type', 'EMAIL', 'value', email, 'raw_value', raw_email, 'is_primary', true, 'is_verified', email like '%@%'),
        jsonb_build_object('type', 'PHONE', 'value', phone, 'raw_value', phone, 'is_primary', false, 'is_verified', false)
    ),
    p_addresses := jsonb_build_array(
        jsonb_build_object(
            'type', 'DELIVERY',
            'country', 'Россия',
            'region', region_name,
            'city', city_name,
            'street', street_name,
            'house', house,
            'flat', flat,
            'raw_address', city_name || ', ' || street_name || ' ' || house || coalesce(' кв. ' || flat, ''),
            'is_default', true
        )
    ),
    p_identifiers := jsonb_build_array(
        jsonb_build_object('type', 'LOYALTY_CARD', 'value', 'TECH-' || lpad(ord::text, 5, '0'), 'raw_value', 'карта TECH-' || lpad(ord::text, 5, '0'), 'is_verified', true)
    ),
    p_documents := case
        when ord % 3 = 0 then jsonb_build_array(
            jsonb_build_object(
                'type', 'PASSPORT_RF',
                'series', '45' || lpad((10 + ord)::text, 2, '0'),
                'number', lpad((500000 + ord * 37)::text, 6, '0'),
                'issue_date_raw', '10.0' || ((ord % 8) + 1)::text || '.201' || (ord % 10)::text,
                'issued_by', 'ОВД района',
                'raw_document_text', 'паспорт одной строкой: серия 45' || lpad((10 + ord)::text, 2, '0') || ' номер ' || lpad((500000 + ord * 37)::text, 6, '0'),
                'verification_status', 'NOT_CHECKED'
            )
        )
        else '[]'::jsonb
    end,
    p_consents := jsonb_build_array(
        jsonb_build_object('type', 'PERSONAL_DATA_PROCESSING', 'is_granted', true, 'granted_at', '2026-05-10T10:00:00+03:00', 'source', 'seed_bulk', 'raw_value', 'ПД: да'),
        jsonb_build_object('type', 'MARKETING_EMAIL', 'is_granted', ord % 2 = 0, 'source', 'seed_bulk', 'raw_value', case when ord % 2 = 0 then 'email yes' else 'email no' end)
    ),
    p_attributes := jsonb_build_object(
        'FAVORITE_TECH_CATEGORY', tech_category,
        'PREFERRED_BRAND', brand,
        'AVG_ORDER_BUDGET', budget,
        'INSTALLMENT_INTEREST', installment_interest,
        'LOYALTY_LEVEL', case when budget >= 80000 then 'gold' when budget >= 50000 then 'silver' else 'basic' end
    )
)
from extra_customers;
