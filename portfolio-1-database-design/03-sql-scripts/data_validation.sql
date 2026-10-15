-- READ ONLY: produce evidence from your actual database.
-- A: Counts for all portfolio tables (estimates, may lag until ANALYZE).
SELECT schemaname, relname AS table_name, n_live_tup AS estimated_rows
FROM pg_stat_user_tables
WHERE schemaname IN ('org','clinical','lab','pharmacy','supply')
ORDER BY schemaname, relname;

-- B: Number of branches and registered patients
SELECT (SELECT count(*) FROM org.branches) AS branches,
       (SELECT count(*) FROM clinical.patients) AS patients,
       (SELECT count(*) FROM clinical.appointments) AS appointments,
       (SELECT count(*) FROM clinical.encounters) AS encounters;

-- C: Appointment-to-encounter mismatch audit; EXPECT zero rows.
SELECT e.encounter_id, e.appointment_id, e.patient_id AS encounter_patient,
       a.patient_id AS appointment_patient, e.branch_id AS encounter_branch,
       a.branch_id AS appointment_branch
FROM clinical.encounters e
JOIN clinical.appointments a ON a.appointment_id=e.appointment_id
WHERE e.patient_id<>a.patient_id OR e.branch_id<>a.branch_id;

-- D: Dispensed medication does not match prescription item; EXPECT zero rows.
SELECT di.dispensation_item_id, di.medication_id AS dispensed_medication,
       pi.medication_id AS prescribed_medication
FROM pharmacy.dispensation_items di
JOIN pharmacy.prescription_items pi ON pi.prescription_item_id=di.prescription_item_id
WHERE di.medication_id<>pi.medication_id;

-- E: Item belongs to another prescription than dispensation header; EXPECT zero rows.
SELECT di.dispensation_item_id, d.prescription_id AS dispensation_prescription,
       pi.prescription_id AS item_prescription
FROM pharmacy.dispensation_items di
JOIN pharmacy.dispensations d ON d.dispensation_id=di.dispensation_id
JOIN pharmacy.prescription_items pi ON pi.prescription_item_id=di.prescription_item_id
WHERE d.prescription_id<>pi.prescription_id;

-- F: Negative quantities should be impossible through CHECK constraint; EXPECT zero.
SELECT batch_id, quantity_available FROM pharmacy.inventory_batches WHERE quantity_available < 0;

-- G: Existence of primary/foreign/check/exclusion constraints per domain
SELECT n.nspname AS schema_name, con.contype, COUNT(*) AS constraint_count
FROM pg_constraint con JOIN pg_class c ON c.oid=con.conrelid
JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname IN ('org','clinical','lab','pharmacy','supply')
GROUP BY n.nspname, con.contype ORDER BY schema_name, con.contype;
