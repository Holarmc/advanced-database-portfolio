-- ============================================================================
-- 1. Appointment Counts Grouped by Branch Location
-- ============================================================================
SELECT 
    b.city,
    COUNT(a.appointment_id) AS total_appointments
FROM org.branches b 
LEFT JOIN clinical.appointments a 
    ON a.branch_id = b.branch_id
GROUP BY 
    b.branch_id, 
    b.city 
ORDER BY 
    b.city ASC;

-- ============================================================================
-- 2. Patient Primary Encounter Diagnoses Pipeline
-- ============================================================================
SELECT 
    p.hospital_number, 
    a.starts_at AS appointment_time, 
    d.description AS diagnosis_description
FROM clinical.patients p
INNER JOIN clinical.appointments a 
    ON a.patient_id = p.patient_id
INNER JOIN clinical.encounters e 
    ON e.appointment_id = a.appointment_id
INNER JOIN clinical.diagnoses d 
    ON d.encounter_id = e.encounter_id;

-- ============================================================================
-- 3. Pharmacy Stock Volume by Location
-- ============================================================================
SELECT 
    b.city, 
    m.generic_name, 
    i.batch_number, 
    i.quantity_available
FROM pharmacy.inventory_batches i 
INNER JOIN org.branches b 
    ON b.branch_id = i.branch_id
INNER JOIN pharmacy.medications m 
    ON m.medication_id = i.medication_id;

-- ============================================================================
-- 4. Constraint Inspection Ledger (Includes Exclusion Constraints)
-- ============================================================================
SELECT 
    conrelid::regclass AS table_name, 
    conname AS constraint_name, 
    CASE contype
        WHEN 'p' THEN 'PRIMARY KEY'
        WHEN 'f' THEN 'FOREIGN KEY'
        WHEN 'u' THEN 'UNIQUE'
        WHEN 'c' THEN 'CHECK'
        WHEN 'x' THEN 'EXCLUSION'
        ELSE contype
    END AS constraint_type
FROM pg_constraint 
WHERE connamespace IN (
    'clinical'::regnamespace, 
    'pharmacy'::regnamespace
)
ORDER BY 
    table_name ASC, 
    constraint_name ASC;

