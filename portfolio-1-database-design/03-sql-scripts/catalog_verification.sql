-- READ ONLY. PostgreSQL SQL editor compatible. Run each query or the whole file.
-- 1. Object inventory
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema IN ('org','clinical','lab','pharmacy','supply')
  AND table_type = 'BASE TABLE'
ORDER BY table_schema, table_name;

-- 2. Columns, types and nullability
SELECT table_schema, table_name, ordinal_position, column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema IN ('org','clinical','lab','pharmacy','supply')
ORDER BY table_schema, table_name, ordinal_position;

-- 3. Constraints (P=primary, F=foreign, U=unique, C=check, X=exclusion)
SELECT n.nspname AS schema_name, c.relname AS table_name,
       con.conname AS constraint_name, con.contype AS constraint_type,
       pg_get_constraintdef(con.oid) AS definition
FROM pg_constraint con
JOIN pg_class c ON c.oid=con.conrelid
JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname IN ('org','clinical','lab','pharmacy','supply')
ORDER BY schema_name, table_name, constraint_name;

-- 4. Indexes, including exclusion and partial unique index
SELECT schemaname, tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname IN ('org','clinical','lab','pharmacy','supply')
ORDER BY schemaname, tablename, indexname;

-- 5. Extension required by appointment exclusion constraint
SELECT name, installed_version
FROM pg_available_extensions WHERE name = 'btree_gist';
