# MedCore Hospital Group — Case Study and Requirements

**Course:** MIT 8103 Advanced Database Systems — Portfolio 1

**Organisation:** MedCore Hospital Group, a fictional Nigerian hospital group with branches in Lagos, Abuja and Port Harcourt. All demonstration data must be synthetic.

## Nature and purpose
The database supports an integrated multi-branch hospital workflow: registering patients, scheduling doctor appointments, recording encounters and diagnoses, placing laboratory orders and recording results, prescribing and dispensing medication, and tracking batch inventory, procurement and transfers. Its purpose in this assessment is to demonstrate an appropriately normalised relational design, declarative constraints and verifiable SQL implementation—not to claim a production-ready electronic health record.

## Users and permitted work (conceptual requirements)
- Registration staff: register patients, manage branch registrations and appointments.
- Doctors: view authorised clinical histories, record encounters and diagnoses, request tests and issue prescriptions.
- Laboratory personnel: manage test orders and verify laboratory results.
- Pharmacists: review prescriptions, dispense medication and monitor stock.
- Inventory/procurement officers: receive stock, track batches, record purchases and transfers.
- Administrators/auditors: inspect operational and integrity records subject to access controls.

**Important:** Roles above are *requirements*, not proof of implemented row-level security. Authentication, authorisation and audit policies are out of scope of the current starter schema.

## Data managed
Organisation and staff assignments; patients and branch registrations; doctors, schedules, appointments, encounters and diagnoses; laboratory tests, orders, items and results; medications, prescriptions, inventory batches and dispensing; suppliers, purchase orders, inter-branch stock transfers and inventory movements.

## Business rules implemented by the starter schema
1. Patient hospital numbers and branch codes are unique.
2. Appointment and schedule end timestamps must follow their start timestamps.
3. Active bookings for the same doctor assignment cannot overlap (GiST exclusion constraint; `btree_gist` extension).
4. Encounters may exist without an appointment; an appointment can reference at most one encounter through `UNIQUE` on `encounters.appointment_id`.
5. At most one diagnosis is marked primary per encounter (partial unique index).
6. Inventory quantities cannot be negative; dispensing item quantities must be positive.
7. Dispensing items reference a matching batch, medication and branch through a composite foreign key.
8. Inter-branch transfers cannot use identical source and destination branches.

## Known limitations / proposed later improvements
- A doctor's `staff_assignments` record is not currently checked to confirm their professional role or `clinical.doctors` membership.
- Doctor schedule existence/coverage is not checked when booking.
- `encounters.appointment_id` does not enforce matching patient and branch fields.
- A lab order's requester, or prescription's prescriber, is not checked against encounter branch/role.
- The prescribed medication link and dispensed prescription item link require additional consistency logic across tables.
- Inventory expiry, sufficient stock, movement reconciliation, auditing and confidentiality policy require transaction logic/triggers/security architecture beyond this baseline.
- The seed script assumes an empty database with identity values starting at 1 and must not be rerun on populated data.

These limitations should be disclosed rather than claiming the database enforces business rules it does not.
