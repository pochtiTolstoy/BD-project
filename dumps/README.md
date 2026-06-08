# Dumps

Generated database:

```text
marketplace_person
```

Files:

- `marketplace_person_partner.sql` - partner-safe plain SQL dump without owner/privilege statements.
- `marketplace_person_partner.dump` - partner-safe custom-format dump without owner/privilege statements.
- `migration_test_after_partner.sql` - internal plain SQL dump after test migration from partner data.
- `migration_test_after_partner.dump` - internal custom-format dump after test migration from partner data.
- `migration_error_demo.sql` - internal plain SQL dump after the demonstration run with intentional migration errors.
- `migration_error_demo.dump` - internal custom-format dump after the demonstration run with intentional migration errors.

Restore from plain SQL:

```bash
psql -f dumps/marketplace_person_partner.sql
```

Restore from custom dump:

```bash
pg_restore -d postgres --clean --if-exists --create --no-owner --no-privileges dumps/marketplace_person_partner.dump
```

Send `marketplace_person_partner.sql` or `marketplace_person_partner.dump` to the partner.

Recommended partner package:

- `dumps/marketplace_person_partner.sql` or `dumps/marketplace_person_partner.dump`
- `docs/partner_database_description.md`
- `diagrams/person_business_er.png` if the partner needs a visual schema overview

The `migration_test_after_partner.*` files are for our own analysis and demonstration. They include the loaded partner source tables in `map`, migration logs, and migrated target rows.

The `migration_error_demo.*` files are also internal. They include two intentionally invalid partner rows used only to demonstrate `error` handling in `map.migration_log` for the report.
