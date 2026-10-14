# MedCore Hospital Group — Portfolio 1

MIT 8103 Advanced Database Systems. Synthetic case study with three branches (Lagos, Abuja, Port Harcourt).

## Scope
Patient registration, multi-branch clinician assignments, appointment booking, encounters and diagnoses, laboratory orders and results, prescriptions, batch inventory, dispensing, procurement and stock transfers.

## Run
Requires PostgreSQL 15+ and `psql`:

```bash
createdb medcore
psql -v ON_ERROR_STOP=1 -d medcore -f 01_schema.sql
psql -v ON_ERROR_STOP=1 -d medcore -f 02_seed.sql
psql -v ON_ERROR_STOP=1 -d medcore -f 03_validation.sql
```

All records are synthetic. No real patient information should be inserted.

## Architecture and integrity notes
- Shared patient identifiers across branches; clinician assignments are branch-specific.
- Appointment slots are non-overlapping per clinician/branch through PostgreSQL exclusion constraints. Inactive bookings do not reserve slots.
- Prescription, laboratory and dispensing records reference encounters; inventory is held by batch and branch.
- A positive stock balance is a safety constraint, but dispensing must use a transaction with row locks and validated stock decrements (Portfolio 3).
- Clinical access policy, audit triggers, authorisation, retention, encryption and replication are **not yet implemented** in this first schema; they are subsequent milestones.
- Patient identity deduplication, medication dose checking, specimen workflows, inter-branch stock transfer fulfilment and appointment availability are simplified for the assessment.

## Normalisation
The design targets 3NF: separate catalogues (medications, lab tests), master records (patients, staff, branches), transactional headers and line items, and junction tables for staff-branch assignments. Non-key attributes generally depend on the key, the whole key and no other non-key attribute. Batch quantity is deliberately maintained as an operational balance, with inventory movements as an audit-oriented ledger; reconciliation is a later exercise.

## Evidence to collect
ER diagram, SQL creation output, validation output, pg_catalog constraint inspection, screenshots, and progressive commits. The assessment requires individual understanding and an AI-use declaration where applicable.
