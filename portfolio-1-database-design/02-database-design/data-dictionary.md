# Data dictionary (generated from current schema SQL)

Authoritative types and nullability come from `01_schema.sql`; this inventory is an aid to review.

## `org.branches`

| Column | Declared type | Notes |
|---|---|---|
| `branch_id` | `bigint` | PK |
| `code` | `text` | Required, Unique |
| `name` | `text` | Required |
| `city` | `text` | Required |

## `org.staff`

| Column | Declared type | Notes |
|---|---|---|
| `staff_id` | `bigint` | PK |
| `full_name` | `text` | Required |
| `professional_role` | `text` | Required, Check |
| `licence_number` | `text` | Unique |

## `org.staff_assignments`

| Column | Declared type | Notes |
|---|---|---|
| `assignment_id` | `bigint` | PK |
| `staff_id` | `bigint` | FK, Required |
| `branch_id` | `bigint` | FK, Required |
| `start_date` | `date` | Required |
| `end_date` | `date` | — |

## `clinical.patients`

| Column | Declared type | Notes |
|---|---|---|
| `patient_id` | `bigint` | PK |
| `hospital_number` | `text` | Required, Unique |
| `full_name` | `text` | Required |
| `date_of_birth` | `date` | Required |
| `sex_at_registration` | `text` | Check |

## `clinical.patient_branch_registrations`

| Column | Declared type | Notes |
|---|---|---|
| `patient_id` | `bigint` | FK, Required |
| `branch_id` | `bigint` | FK, Required |
| `registered_at` | `timestamptz` | Required, Default |

## `clinical.doctors`

| Column | Declared type | Notes |
|---|---|---|
| `staff_id` | `bigint` | PK, FK |
| `specialty` | `text` | Required |

## `clinical.doctor_schedules`

| Column | Declared type | Notes |
|---|---|---|
| `schedule_id` | `bigint` | PK |
| `assignment_id` | `bigint` | FK, Required |
| `starts_at` | `timestamptz` | Required |
| `ends_at` | `timestamptz` | Required |

## `clinical.appointments`

| Column | Declared type | Notes |
|---|---|---|
| `appointment_id` | `bigint` | PK |
| `patient_id` | `bigint` | FK, Required |
| `branch_id` | `bigint` | FK, Required |
| `doctor_assignment_id` | `bigint` | Required |
| `starts_at` | `timestamptz` | Required |
| `ends_at` | `timestamptz` | Required |
| `status` | `text` | Required, Check, Default |

## `clinical.encounters`

| Column | Declared type | Notes |
|---|---|---|
| `encounter_id` | `bigint` | PK |
| `patient_id` | `bigint` | FK, Required |
| `branch_id` | `bigint` | FK, Required |
| `appointment_id` | `bigint` | FK, Unique |
| `clinician_assignment_id` | `bigint` | Required |
| `occurred_at` | `timestamptz` | Required, Default |
| `summary` | `text` | — |

## `clinical.diagnoses`

| Column | Declared type | Notes |
|---|---|---|
| `diagnosis_id` | `bigint` | PK |
| `encounter_id` | `bigint` | FK, Required |
| `diagnosis_code` | `text` | Required |
| `description` | `text` | Required |
| `is_primary` | `boolean` | Required, Default |

## `lab.tests`

| Column | Declared type | Notes |
|---|---|---|
| `test_id` | `bigint` | PK |
| `code` | `text` | Required, Unique |
| `name` | `text` | Required |
| `default_unit` | `text` | — |

## `lab.orders`

| Column | Declared type | Notes |
|---|---|---|
| `order_id` | `bigint` | PK |
| `encounter_id` | `bigint` | FK, Required |
| `ordered_by_assignment_id` | `bigint` | FK, Required |
| `ordered_at` | `timestamptz` | Required, Default |
| `status` | `text` | Required, Check, Default |

## `lab.order_items`

| Column | Declared type | Notes |
|---|---|---|
| `order_item_id` | `bigint` | PK |
| `order_id` | `bigint` | FK, Required |
| `test_id` | `bigint` | FK, Required |
| `status` | `text` | Required, Check, Default |

## `lab.results`

| Column | Declared type | Notes |
|---|---|---|
| `result_id` | `bigint` | PK |
| `order_item_id` | `bigint` | FK, Required, Unique |
| `result_text` | `text` | Required |
| `unit` | `text` | — |
| `reference_range` | `text` | — |
| `verified_by_assignment_id` | `bigint` | FK |
| `verified_at` | `timestamptz` | — |

## `pharmacy.medications`

| Column | Declared type | Notes |
|---|---|---|
| `medication_id` | `bigint` | PK |
| `generic_name` | `text` | Required |
| `strength` | `text` | Required |
| `dosage_form` | `text` | Required |

## `pharmacy.prescriptions`

| Column | Declared type | Notes |
|---|---|---|
| `prescription_id` | `bigint` | PK |
| `encounter_id` | `bigint` | FK, Required |
| `prescribed_by_assignment_id` | `bigint` | FK, Required |
| `prescribed_at` | `timestamptz` | Required, Default |

## `pharmacy.prescription_items`

| Column | Declared type | Notes |
|---|---|---|
| `prescription_item_id` | `bigint` | PK |
| `prescription_id` | `bigint` | FK, Required |
| `medication_id` | `bigint` | FK, Required |
| `dose_instructions` | `text` | Required |
| `quantity_prescribed` | `integer` | Required, Check |

## `pharmacy.inventory_batches`

| Column | Declared type | Notes |
|---|---|---|
| `batch_id` | `bigint` | PK |
| `branch_id` | `bigint` | FK, Required |
| `medication_id` | `bigint` | FK, Required |
| `batch_number` | `text` | Required |
| `expiry_date` | `date` | Required |
| `quantity_available` | `integer` | Required, Check |

## `pharmacy.dispensations`

| Column | Declared type | Notes |
|---|---|---|
| `dispensation_id` | `bigint` | PK |
| `prescription_id` | `bigint` | FK, Required |
| `branch_id` | `bigint` | FK, Required |
| `dispensed_by_assignment_id` | `bigint` | Required |
| `dispensed_at` | `timestamptz` | Required, Default |

## `pharmacy.dispensation_items`

| Column | Declared type | Notes |
|---|---|---|
| `dispensation_item_id` | `bigint` | PK |
| `dispensation_id` | `bigint` | Required |
| `branch_id` | `bigint` | Required |
| `prescription_item_id` | `bigint` | FK, Required |
| `medication_id` | `bigint` | FK, Required |
| `batch_id` | `bigint` | Required |
| `quantity_dispensed` | `integer` | Required, Check |

## `supply.suppliers`

| Column | Declared type | Notes |
|---|---|---|
| `supplier_id` | `bigint` | PK |
| `name` | `text` | Required, Unique |

## `supply.purchase_orders`

| Column | Declared type | Notes |
|---|---|---|
| `purchase_order_id` | `bigint` | PK |
| `branch_id` | `bigint` | FK, Required |
| `supplier_id` | `bigint` | FK, Required |
| `ordered_at` | `timestamptz` | Required, Default |
| `status` | `text` | Required, Check, Default |

## `supply.purchase_order_items`

| Column | Declared type | Notes |
|---|---|---|
| `purchase_order_item_id` | `bigint` | PK |
| `purchase_order_id` | `bigint` | FK, Required |
| `medication_id` | `bigint` | FK, Required |
| `quantity_ordered` | `integer` | Required, Check |

## `supply.stock_transfers`

| Column | Declared type | Notes |
|---|---|---|
| `transfer_id` | `bigint` | PK |
| `source_branch_id` | `bigint` | FK, Required |
| `destination_branch_id` | `bigint` | FK, Required |
| `status` | `text` | Required, Check, Default |

## `supply.stock_transfer_items`

| Column | Declared type | Notes |
|---|---|---|
| `transfer_item_id` | `bigint` | PK |
| `transfer_id` | `bigint` | FK, Required |
| `medication_id` | `bigint` | FK, Required |
| `quantity` | `integer` | Required, Check |

## `pharmacy.inventory_movements`

| Column | Declared type | Notes |
|---|---|---|
| `movement_id` | `bigint` | PK |
| `batch_id` | `bigint` | FK, Required |
| `quantity_delta` | `integer` | Required, Check |
| `reason` | `text` | Required, Check |
| `recorded_at` | `timestamptz` | Required, Default |
| `reference_id` | `bigint` | — |

## Caution

Some constraints are table-level and therefore are not repeated in every column row. See the SQL and catalog verification output for composite foreign keys, multi-column uniqueness and the appointment exclusion constraint.
