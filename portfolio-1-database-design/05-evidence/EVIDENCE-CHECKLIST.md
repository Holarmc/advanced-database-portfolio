# Evidence capture checklist

All results must come from your own PostgreSQL environment. Do not add invented screenshots or execution results.

- [ ] `01-schema-created.png`: database object listing after successful schema creation (can use `04_catalog_verification.sql`, query 1).
- [ ] `02-tables-and-columns.png`: sample of column inventory (query 2).
- [ ] `03-key-constraints.png`: primary, foreign, unique and check constraints (query 3).
- [ ] `04-exclusion-index.png`: appointment GiST exclusion and/or partial unique diagnosis index (queries 3–4).
- [ ] `05-sample-data.png`: synthetic records/branch counts from `05_data_validation.sql` query B.
- [ ] `06-data-consistency.png`: actual results of validation queries C–F, including any unexpected rows.
- [ ] `07-er-diagram.png`: export of the Mermaid ER diagram.
- [ ] `validation-results.md`: document date, database PostgreSQL version, counts, exact SQL executed, checks passed/failed, observed problems and fixes.

Never assert that a query returned zero rows until you have executed it. Screenshots should not expose real patient information.
