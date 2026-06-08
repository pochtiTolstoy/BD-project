# Dumps

Generated database:

```text
marketplace_person
```

Files:

- `marketplace_person_partner.sql` - partner-safe plain SQL dump without owner/privilege statements.
- `marketplace_person_partner.dump` - partner-safe custom-format dump without owner/privilege statements.

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
- final report / database description, if it is sent separately
