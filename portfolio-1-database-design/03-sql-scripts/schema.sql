BEGIN;

CREATE EXTENSION IF NOT EXISTS btree_gist;

-- ============================================================================
-- SCHEMA SETUP
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS org;
CREATE SCHEMA IF NOT EXISTS clinical;
CREATE SCHEMA IF NOT EXISTS lab;
CREATE SCHEMA IF NOT EXISTS pharmacy;
CREATE SCHEMA IF NOT EXISTS supply;

-- ============================================================================
-- ORG SCHEMA
-- ============================================================================
CREATE TABLE org.branches (
    branch_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code text NOT NULL UNIQUE,
    name text NOT NULL,
    city text NOT NULL
);

CREATE TABLE org.staff (
    staff_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name text NOT NULL,
    professional_role text NOT NULL CHECK (professional_role IN ('doctor', 'pharmacist', 'lab_scientist', 'nurse', 'inventory_officer', 'administrator')),
    licence_number text UNIQUE
);

CREATE TABLE org.staff_assignments (
    assignment_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    staff_id bigint NOT NULL REFERENCES org.staff(staff_id),
    branch_id bigint NOT NULL REFERENCES org.branches(branch_id),
    start_date date NOT NULL,
    end_date date,
    CHECK (end_date IS NULL OR end_date >= start_date),
    UNIQUE (staff_id, branch_id, start_date),
    UNIQUE (assignment_id, branch_id)
);

-- ============================================================================
-- CLINICAL SCHEMA
-- ============================================================================
CREATE TABLE clinical.patients (
    patient_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    hospital_number text NOT NULL UNIQUE,
    full_name text NOT NULL,
    date_of_birth date NOT NULL,
    sex_at_registration text CHECK (sex_at_registration IN ('female', 'male', 'other', 'unknown'))
);

CREATE TABLE clinical.patient_branch_registrations (
    patient_id bigint NOT NULL REFERENCES clinical.patients(patient_id),
    branch_id bigint NOT NULL REFERENCES org.branches(branch_id),
    registered_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (patient_id, branch_id)
);

CREATE TABLE clinical.doctors (
    staff_id bigint PRIMARY KEY REFERENCES org.staff(staff_id),
    specialty text NOT NULL
);

CREATE TABLE clinical.doctor_schedules (
    schedule_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    assignment_id bigint NOT NULL REFERENCES org.staff_assignments(assignment_id),
    starts_at timestamptz NOT NULL,
    ends_at timestamptz NOT NULL,
    CHECK (ends_at > starts_at)
);

CREATE TABLE clinical.appointments (
    appointment_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id bigint NOT NULL REFERENCES clinical.patients(patient_id),
    branch_id bigint NOT NULL REFERENCES org.branches(branch_id),
    doctor_assignment_id bigint NOT NULL,
    starts_at timestamptz NOT NULL,
    ends_at timestamptz NOT NULL,
    status text NOT NULL DEFAULT 'booked' CHECK (status IN ('booked', 'checked_in', 'completed', 'cancelled', 'no_show')),
    CHECK (ends_at > starts_at),
    FOREIGN KEY (doctor_assignment_id, branch_id) REFERENCES org.staff_assignments(assignment_id, branch_id),
    EXCLUDE USING gist (doctor_assignment_id WITH =, tstzrange(starts_at, ends_at, '[)') WITH &&) WHERE (status IN ('booked', 'checked_in'))
);

CREATE TABLE clinical.encounters (
    encounter_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id bigint NOT NULL REFERENCES clinical.patients(patient_id),
    branch_id bigint NOT NULL REFERENCES org.branches(branch_id),
    appointment_id bigint UNIQUE REFERENCES clinical.appointments(appointment_id),
    clinician_assignment_id bigint NOT NULL,
    occurred_at timestamptz NOT NULL DEFAULT now(),
    summary text,
    FOREIGN KEY (clinician_assignment_id, branch_id) REFERENCES org.staff_assignments(assignment_id, branch_id)
);

CREATE TABLE clinical.diagnoses (
    diagnosis_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    encounter_id bigint NOT NULL REFERENCES clinical.encounters(encounter_id),
    diagnosis_code text NOT NULL,
    description text NOT NULL,
    is_primary boolean NOT NULL DEFAULT false
);

CREATE UNIQUE INDEX one_primary_diagnosis_per_encounter 
ON clinical.diagnoses(encounter_id) WHERE is_primary;

-- ============================================================================
-- LAB SCHEMA
-- ============================================================================
CREATE TABLE lab.tests (
    test_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code text NOT NULL UNIQUE,
    name text NOT NULL,
    default_unit text
);

CREATE TABLE lab.orders (
    order_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    encounter_id bigint NOT NULL REFERENCES clinical.encounters(encounter_id),
    ordered_by_assignment_id bigint NOT NULL REFERENCES org.staff_assignments(assignment_id),
    ordered_at timestamptz NOT NULL DEFAULT now(),
    status text NOT NULL DEFAULT 'ordered' CHECK (status IN ('ordered', 'collected', 'processing', 'completed', 'cancelled'))
);

CREATE TABLE lab.order_items (
    order_item_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id bigint NOT NULL REFERENCES lab.orders(order_id),
    test_id bigint NOT NULL REFERENCES lab.tests(test_id),
    status text NOT NULL DEFAULT 'ordered' CHECK (status IN ('ordered', 'collected', 'processing', 'completed', 'cancelled'))
);

CREATE TABLE lab.results (
    result_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_item_id bigint NOT NULL UNIQUE REFERENCES lab.order_items(order_item_id),
    result_text text NOT NULL,
    unit text,
    reference_range text,
    verified_by_assignment_id bigint REFERENCES org.staff_assignments(assignment_id),
    verified_at timestamptz,
    CHECK ((verified_at IS NULL) = (verified_by_assignment_id IS NULL))
);

-- ============================================================================
-- PHARMACY SCHEMA
-- ============================================================================
CREATE TABLE pharmacy.medications (
    medication_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    generic_name text NOT NULL,
    strength text NOT NULL,
    dosage_form text NOT NULL,
    UNIQUE (generic_name, strength, dosage_form)
);

CREATE TABLE pharmacy.prescriptions (
    prescription_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    encounter_id bigint NOT NULL REFERENCES clinical.encounters(encounter_id),
    prescribed_by_assignment_id bigint NOT NULL REFERENCES org.staff_assignments(assignment_id),
    prescribed_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE pharmacy.prescription_items (
    prescription_item_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    prescription_id bigint NOT NULL REFERENCES pharmacy.prescriptions(prescription_id),
    medication_id bigint NOT NULL REFERENCES pharmacy.medications(medication_id),
    dose_instructions text NOT NULL,
    quantity_prescribed integer NOT NULL CHECK (quantity_prescribed > 0)
);

CREATE TABLE pharmacy.inventory_batches (
    batch_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    branch_id bigint NOT NULL REFERENCES org.branches(branch_id),
    medication_id bigint NOT NULL REFERENCES pharmacy.medications(medication_id),
    batch_number text NOT NULL,
    expiry_date date NOT NULL,
    quantity_available integer NOT NULL CHECK (quantity_available >= 0),
    UNIQUE (branch_id, medication_id, batch_number),
    UNIQUE (batch_id, medication_id, branch_id)
);

CREATE TABLE pharmacy.dispensations (
    dispensation_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    prescription_id bigint NOT NULL REFERENCES pharmacy.prescriptions(prescription_id),
    branch_id bigint NOT NULL REFERENCES org.branches(branch_id),
    dispensed_by_assignment_id bigint NOT NULL,
    dispensed_at timestamptz NOT NULL DEFAULT now(),
    FOREIGN KEY (dispensed_by_assignment_id, branch_id) REFERENCES org.staff_assignments(assignment_id, branch_id),
    UNIQUE (dispensation_id, branch_id)
);

CREATE TABLE pharmacy.dispensation_items (
    dispensation_item_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    dispensation_id bigint NOT NULL,
    branch_id bigint NOT NULL,
    prescription_item_id bigint NOT NULL REFERENCES pharmacy.prescription_items(prescription_item_id),
    medication_id bigint NOT NULL REFERENCES pharmacy.medications(medication_id),
    batch_id bigint NOT NULL,
    quantity_dispensed integer NOT NULL CHECK (quantity_dispensed > 0),
    FOREIGN KEY (dispensation_id, branch_id) REFERENCES pharmacy.dispensations(dispensation_id, branch_id),
    FOREIGN KEY (batch_id, medication_id, branch_id) REFERENCES pharmacy.inventory_batches(batch_id, medication_id, branch_id)
);

-- ============================================================================
-- SUPPLY SCHEMA
-- ============================================================================
CREATE TABLE supply.suppliers (
    supplier_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text NOT NULL UNIQUE
);

CREATE TABLE supply.purchase_orders (
    purchase_order_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    branch_id bigint NOT NULL REFERENCES org.branches(branch_id),
    supplier_id bigint NOT NULL REFERENCES supply.suppliers(supplier_id),
    ordered_at timestamptz NOT NULL DEFAULT now(),
    status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'submitted', 'received', 'cancelled'))
);

CREATE TABLE supply.purchase_order_items (
    purchase_order_item_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    purchase_order_id bigint NOT NULL REFERENCES supply.purchase_orders(purchase_order_id),
    medication_id bigint NOT NULL REFERENCES pharmacy.medications(medication_id),
    quantity_ordered integer NOT NULL CHECK (quantity_ordered > 0)
);

-- ============================================================================
-- SUPPLY SCHEMA (CONCLUDED)
-- ============================================================================
CREATE TABLE supply.stock_transfers (
    transfer_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_branch_id bigint NOT NULL REFERENCES org.branches(branch_id),
    destination_branch_id bigint NOT NULL REFERENCES org.branches(branch_id),
    status text NOT NULL DEFAULT 'requested' CHECK (status IN ('requested', 'dispatched', 'received', 'cancelled')),
    CHECK (source_branch_id <> destination_branch_id)
);

CREATE TABLE supply.stock_transfer_items (
    transfer_item_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transfer_id bigint NOT NULL REFERENCES supply.stock_transfers(transfer_id),
    medication_id bigint NOT NULL REFERENCES pharmacy.medications(medication_id),
    quantity integer NOT NULL CHECK (quantity > 0)
);

-- ============================================================================
-- PHARMACY SCHEMA (AUDIT LAYER)
-- ============================================================================
CREATE TABLE pharmacy.inventory_movements (
    movement_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    batch_id bigint NOT NULL REFERENCES pharmacy.inventory_batches(batch_id),
    quantity_delta integer NOT NULL CHECK (quantity_delta <> 0),
    reason text NOT NULL CHECK (reason IN ('receipt', 'dispense', 'transfer_out', 'transfer_in', 'adjustment')),
    recorded_at timestamptz NOT NULL DEFAULT now(),
    reference_id bigint -- Tracks the originating entity (e.g., dispensation_item_id, transfer_item_id, etc.)
);

COMMIT;

