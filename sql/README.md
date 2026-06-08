# SQL Scripts

Business database run order:

1. `schema.sql` - creates the clean business schema.
2. `functions.sql` - creates functions used by the application/database.
3. `seed.sql` - inserts dictionaries and generated test data.

Partner migration run order:

1. `load_partner_source_to_map.sql` - loads the partner source dump into the separate `map` schema.
2. `migration_schema.sql` - creates migration logs, link tables, unmapped-attribute storage, mapping helpers, and the migration function.
3. `run_partner_migration.sql` - runs the full scenario from clean target schema to migration metrics.
4. `run_partner_migration_error_demo.sql` - runs the full scenario, adds two intentionally invalid partner rows, and demonstrates `error` rows in `map.migration_log`.

The business schema intentionally does not include migration tables. Migration is implemented as a separate `map` layer that parses partner data and calls the business functions.
