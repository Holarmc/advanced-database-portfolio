# Normalisation report — MedCore Hospital Group

## Scope and method
The PostgreSQL model is designed largely toward Third Normal Form (3NF). Normalisation is assessed against intended functional dependencies, rather than inferred from table names alone. The practical examples below illustrate *why* the chosen decomposition is appropriate; they do not claim that every possible semantic dependency has been formally proven.

## Unnormalised illustrative source (not an implemented table)
Imagine a single patient visit spreadsheet with columns: `patient_id, patient_name, appointment_id, branch_city, clinician_name, prescribed_drugs=[(drug, strength, qty), ...], lab_tests=[(test, result), ...]`. The repeating collections make updates and individual item queries difficult.

## 1NF: atomic fields and repeated rows
Store each medication in its own `pharmacy.prescription_items` row linked to one `pharmacy.prescriptions` header. Store laboratory tests in `lab.order_items` linked to `lab.orders`. Each table row holds separately addressable values rather than embedded comma-separated lists. (Text fields such as encounter notes can remain atomic domain values for this relational application.)

## 2NF: full-key dependency
The composite primary key of `clinical.patient_branch_registrations` is `(patient_id, branch_id)`, and `registered_at` describes the specific registration of that patient at that branch, not the patient alone or branch alone. Patient name is stored in `clinical.patients`, while branch name and city are in `org.branches`, avoiding partial-key dependencies. Most other tables have a single-column surrogate primary key, so 2NF follows when non-key fields are atomic and depend on the row key.

## 3NF: removing transitive dependencies
- Medication names, strength and form are stored in `pharmacy.medications`; `prescription_items` references `medication_id` rather than copying medication descriptions into each transaction.
- Branch name and city are stored once in `org.branches`; `appointments` and `inventory_batches` reference `branch_id`.
- Patient demographics are stored in `clinical.patients`; `encounters` and `appointments` reference `patient_id`.
- Laboratory test descriptions are kept in `lab.tests`, with order lines referencing `test_id`.
This limits update anomalies: changing a branch name or catalogue test description does not require rewriting historic appointment or order items.

## Deliberate redundancies / trade-offs
- `pharmacy.inventory_batches.quantity_available` is a mutable operational balance; `inventory_movements` provides movement events. This requires transactional reconciliation and is not an automatically proven single-source-of-truth ledger in the starter.
- `pharmacy.dispensation_items` stores `medication_id` and `branch_id` as well as IDs linking to a batch and dispensation. These support composite foreign keys that prove *batch/medication/branch* and *dispensation/branch* agreement, but a separate check is still required to ensure its `prescription_item_id` belongs to the same prescription and medication.
- `clinical.encounters` repeats patient and branch context alongside an optional appointment reference; matching them to appointment values is not yet enforced.
- Free-text results and diagnoses deliberately simplify clinical terminologies.

## Conclusion
The model applies the principles of 1NF–3NF for the main master, lookup, junction and transaction structures, while retaining a few consistency-sensitive operational fields. Such fields require explicit business rules and tests, and should be documented rather than described as a mathematically proven strict 3NF implementation.
