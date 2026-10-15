BEGIN;

WITH 
-- ============================================================================
-- 1. ORG SCHEMA SEEDING
-- ============================================================================
inserted_branches AS (
    INSERT INTO org.branches (code, name, city) 
    VALUES 
        ('LOS', 'MedCore Lagos', 'Lagos'),
        ('ABV', 'MedCore Abuja', 'Abuja'),
        ('PHC', 'MedCore Port Harcourt', 'Port Harcourt')
    RETURNING branch_id, code
),
inserted_staff AS (
    INSERT INTO org.staff (full_name, professional_role, licence_number) 
    VALUES 
        ('Dr Ada Sample', 'doctor', 'DEMO-D001'),
        ('Pharm Bayo Sample', 'pharmacist', 'DEMO-P001'),
        ('Dr Zainab Sample', 'doctor', 'DEMO-D002')
    RETURNING staff_id, licence_number
),
inserted_assignments AS (
    INSERT INTO org.staff_assignments (staff_id, branch_id, start_date) 
    VALUES 
        ((SELECT staff_id FROM inserted_staff WHERE licence_number = 'DEMO-D001'), (SELECT branch_id FROM inserted_branches WHERE code = 'LOS'), '2026-01-01'),
        ((SELECT staff_id FROM inserted_staff WHERE licence_number = 'DEMO-P001'), (SELECT branch_id FROM inserted_branches WHERE code = 'LOS'), '2026-01-01'),
        ((SELECT staff_id FROM inserted_staff WHERE licence_number = 'DEMO-D002'), (SELECT branch_id FROM inserted_branches WHERE code = 'ABV'), '2026-01-01')
    RETURNING assignment_id, staff_id, branch_id
),
_inserted_doctors AS (
    INSERT INTO clinical.doctors (staff_id, specialty) 
    VALUES 
        ((SELECT staff_id FROM inserted_staff WHERE licence_number = 'DEMO-D001'), 'General Practice'),
        ((SELECT staff_id FROM inserted_staff WHERE licence_number = 'DEMO-D002'), 'Internal Medicine')
),

-- ============================================================================
-- 2. CLINICAL SCHEMA SEEDING
-- ============================================================================
inserted_patients AS (
    INSERT INTO clinical.patients (hospital_number, full_name, date_of_birth, sex_at_registration) 
    VALUES 
        ('MC-0001', 'Patient Example One', '1995-04-20', 'female'),
        ('MC-0002', 'Patient Example Two', '1988-09-10', 'male')
    RETURNING patient_id, hospital_number
),
_inserted_registrations AS (
    INSERT INTO clinical.patient_branch_registrations (patient_id, branch_id) 
    VALUES 
        ((SELECT patient_id FROM inserted_patients WHERE hospital_number = 'MC-0001'), (SELECT branch_id FROM inserted_branches WHERE code = 'LOS')),
        ((SELECT patient_id FROM inserted_patients WHERE hospital_number = 'MC-0002'), (SELECT branch_id FROM inserted_branches WHERE code = 'ABV'))
),
inserted_schedules AS (
    INSERT INTO clinical.doctor_schedules (assignment_id, starts_at, ends_at) 
    VALUES 
        (
            (SELECT assignment_id FROM inserted_assignments WHERE staff_id = (SELECT staff_id FROM inserted_staff WHERE licence_number = 'DEMO-D001')), 
            '2026-11-02 09:00+01', 
            '2026-11-02 17:00+01'
        )
),
inserted_appointments AS (
    INSERT INTO clinical.appointments (patient_id, branch_id, doctor_assignment_id, starts_at, ends_at) 
    VALUES 
        (
            (SELECT patient_id FROM inserted_patients WHERE hospital_number = 'MC-0001'), 
            (SELECT branch_id FROM inserted_branches WHERE code = 'LOS'), 
            (SELECT assignment_id FROM inserted_assignments WHERE staff_id = (SELECT staff_id FROM inserted_staff WHERE licence_number = 'DEMO-D001')), 
            '2026-11-02 10:00+01', 
            '2026-11-02 10:30+01'
        )
    RETURNING appointment_id, patient_id, branch_id
),
inserted_encounters AS (
    INSERT INTO clinical.encounters (patient_id, branch_id, appointment_id, clinician_assignment_id, summary) 
    VALUES 
        (
            (SELECT patient_id FROM inserted_appointments), 
            (SELECT branch_id FROM inserted_appointments), 
            (SELECT appointment_id FROM inserted_appointments), 
            (SELECT doctor_assignment_id FROM inserted_appointments), 
            'Synthetic outpatient encounter'
        )
    RETURNING encounter_id
),
_inserted_diagnoses AS (
    INSERT INTO clinical.diagnoses (encounter_id, diagnosis_code, description, is_primary) 
    VALUES 
        ((SELECT encounter_id FROM inserted_encounters), 'DEMO-001', 'Fictional demonstration diagnosis', true)
),

-- ============================================================================
-- 3. LAB SCHEMA SEEDING
-- ============================================================================
inserted_tests AS (
    INSERT INTO lab.tests (code, name, default_unit) 
    VALUES ('DEMO-HB', 'Haemoglobin', 'g/dL')
    RETURNING test_id
),
inserted_lab_orders AS (
    INSERT INTO lab.orders (encounter_id, ordered_by_assignment_id) 
    VALUES 
        (
            (SELECT encounter_id FROM inserted_encounters), 
            (SELECT assignment_id FROM inserted_assignments WHERE staff_id = (SELECT staff_id FROM inserted_staff WHERE licence_number = 'DEMO-D001'))
        )
    RETURNING order_id
),
inserted_lab_order_items AS (
    INSERT INTO lab.order_items (order_id, test_id) 
    VALUES ((SELECT order_id FROM inserted_lab_orders), (SELECT test_id FROM inserted_tests))
    RETURNING order_item_id
),
_inserted_lab_results AS (
    INSERT INTO lab.results (order_item_id, result_text, unit) 
    VALUES ((SELECT order_item_id FROM inserted_lab_order_items), '13.2', 'g/dL')
),

-- ============================================================================
-- 4. PHARMACY SCHEMA SEEDING
-- ============================================================================
inserted_medications AS (
    INSERT INTO pharmacy.medications (generic_name, strength, dosage_form) 
    VALUES ('Paracetamol', '500 mg', 'tablet')
    RETURNING medication_id
),
inserted_prescriptions AS (
    INSERT INTO pharmacy.prescriptions (encounter_id, prescribed_by_assignment_id) 
    VALUES 
        (
            (SELECT encounter_id FROM inserted_encounters), 
            (SELECT assignment_id FROM inserted_assignments WHERE staff_id = (SELECT staff_id FROM inserted_staff WHERE licence_number = 'DEMO-D001'))
        )
    RETURNING prescription_id
),
_inserted_prescription_items AS (
    INSERT INTO pharmacy.prescription_items (prescription_id, medication_id, dose_instructions, quantity_prescribed) 
    VALUES ((SELECT prescription_id FROM inserted_prescriptions), (SELECT medication_id FROM inserted_medications), 'One tablet as directed', 10)
),
_inserted_inventory_batches AS (
    INSERT INTO pharmacy.inventory_batches (branch_id, medication_id, batch_number, expiry_date, quantity_available) 
    VALUES ((SELECT branch_id FROM inserted_branches WHERE code = 'LOS'), (SELECT medication_id FROM inserted_medications), 'DEMO-BATCH-01', '2027-12-31', 10)
),

-- ============================================================================
-- 5. SUPPLY SCHEMA SEEDING
-- ============================================================================
inserted_suppliers AS (
    INSERT INTO supply.suppliers (name) 
    VALUES ('Synthetic Medical Supplies Ltd')
    RETURNING supplier_id
),
inserted_purchase_orders AS (
    INSERT INTO supply.purchase_orders (branch_id, supplier_id) 
    VALUES ((SELECT branch_id FROM inserted_branches WHERE code = 'LOS'), (SELECT supplier_id FROM inserted_suppliers))
    RETURNING purchase_order_id
),
_inserted_purchase_order_items AS (
    INSERT INTO supply.purchase_order_items (purchase_order_id, medication_id, quantity_ordered) 
    VALUES ((SELECT purchase_order_id FROM inserted_purchase_orders), (SELECT medication_id FROM inserted_medications), 50)
),
inserted_stock_transfers AS (
    INSERT INTO supply.stock_transfers (source_branch_id, destination_branch_id) 
    VALUES ((SELECT branch_id FROM inserted_branches WHERE code = 'LOS'), (SELECT branch_id FROM inserted_branches WHERE code = 'ABV'))
    RETURNING transfer_id
)
INSERT INTO supply.stock_transfer_items (transfer_id, medication_id, quantity) 
VALUES ((SELECT transfer_id FROM inserted_stock_transfers), (SELECT medication_id FROM inserted_medications), 5);

COMMIT;

