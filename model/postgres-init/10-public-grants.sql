-- Restore pre-PG15 default so Origam's app role can CREATE tables in public.
-- Apply to template1 so any database Composer creates afterwards inherits it.
\connect template1
GRANT ALL ON SCHEMA public TO PUBLIC;

-- Also apply to the current (postgres) database for good measure.
\connect postgres
GRANT ALL ON SCHEMA public TO PUBLIC;
