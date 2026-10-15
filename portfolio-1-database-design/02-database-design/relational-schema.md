# Relational schema inventory

Source of truth: `../03-sql-scripts/01_schema.sql`. Every table below is created by the original SQL script.

| PostgreSQL schema | Table | Primary key | Purpose |
|---|---|---|---|
| `org` | `branches` | `branch_id` | Hospital branches |
| `org` | `staff` | `staff_id` | Staff records and professional role |
| `org` | `staff_assignments` | `assignment_id` | Employment assignments to branches |
| `clinical` | `patients` | `patient_id` | Group-wide patient records |
| `clinical` | `patient_branch_registrations` | `(patient_id, branch_id)` | Patient-to-branch registration |
| `clinical` | `doctors` | `staff_id` | Doctor specialisation |
| `clinical` | `doctor_schedules` | `schedule_id` | Clinician availability windows |
| `clinical` | `appointments` | `appointment_id` | Planned consultations |
| `clinical` | `encounters` | `encounter_id` | Clinical visits |
| `clinical` | `diagnoses` | `diagnosis_id` | Encounter diagnoses |
| `lab` | `tests` | `test_id` | Laboratory test catalogue |
| `lab` | `orders` | `order_id` | Laboratory orders |
| `lab` | `order_items` | `order_item_id` | Tests in laboratory orders |
| `lab` | `results` | `result_id` | Results of ordered tests |
| `pharmacy` | `medications` | `medication_id` | Medication catalogue |
| `pharmacy` | `prescriptions` | `prescription_id` | Prescription headers |
| `pharmacy` | `prescription_items` | `prescription_item_id` | Prescribed medications and quantities |
| `pharmacy` | `inventory_batches` | `batch_id` | Batch-level branch inventory |
| `pharmacy` | `dispensations` | `dispensation_id` | Dispensing headers |
| `pharmacy` | `dispensation_items` | `dispensation_item_id` | Dispensed prescription lines |
| `supply` | `suppliers` | `supplier_id` | Supplier catalogue |
| `supply` | `purchase_orders` | `purchase_order_id` | Procurement order headers |
| `supply` | `purchase_order_items` | `purchase_order_item_id` | Procurement order lines |
| `supply` | `stock_transfers` | `transfer_id` | Inter-branch transfer headers |
| `supply` | `stock_transfer_items` | `transfer_item_id` | Transfer item lines |
| `pharmacy` | `inventory_movements` | `movement_id` | Stock movement ledger entries |

## Relationship and constraint verification

All physical foreign keys, unique constraints, checks and exclusion constraints should be verified by running `04_catalog_verification.sql`. Table definitions above are an inventory, not a substitute for checking the implementation.

## Schema design principles

- Separate organisational master data from encounters and transactional details.
- Represent many-to-many registration/assignment through junction tables.
- Use header/item structures for orders, prescriptions and dispensing.
- Use branch- and batch-specific medication stock rather than one group-wide balance.
- Use unique, check, referential and exclusion constraints as appropriate.
