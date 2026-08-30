-- =============================================================================
-- 01 — Warehouse, database, schemas, role, grants.
-- Run once as a role that can create these objects (ACCOUNTADMIN or SYSADMIN +
-- SECURITYADMIN). Placeholders {{...}} are substituted by scripts/load_raw.py
-- from your .env; you can also replace them by hand and run in a worksheet.
-- =============================================================================

-- ---- Warehouse: small, auto-suspend fast to keep a trial account cheap -------
CREATE WAREHOUSE IF NOT EXISTS {{WAREHOUSE}}
  WAREHOUSE_SIZE = XSMALL
  AUTO_SUSPEND   = 60
  AUTO_RESUME    = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT = 'Retail Analytics Engineering — dbt + ad-hoc';

-- ---- Database + schemas -----------------------------------------------------
CREATE DATABASE IF NOT EXISTS {{DATABASE}}
  COMMENT = 'Retail analytics: raw Olist data + dbt-built analytics layer';

CREATE SCHEMA IF NOT EXISTS {{DATABASE}}.{{RAW_SCHEMA}}
  COMMENT = 'Landing zone — Olist CSVs loaded as-is, no transformation';

CREATE SCHEMA IF NOT EXISTS {{DATABASE}}.{{ANALYTICS_SCHEMA}}
  COMMENT = 'dbt target — staging views + dimensional marts + metrics';

-- ---- Role + grants --------------------------------------------------------
-- A dedicated role for dbt / this project rather than running as an admin role.
CREATE ROLE IF NOT EXISTS {{ROLE}};

GRANT USAGE  ON WAREHOUSE {{WAREHOUSE}} TO ROLE {{ROLE}};
GRANT OPERATE ON WAREHOUSE {{WAREHOUSE}} TO ROLE {{ROLE}};

GRANT USAGE ON DATABASE {{DATABASE}} TO ROLE {{ROLE}};
GRANT USAGE, CREATE TABLE, CREATE VIEW, CREATE STAGE, CREATE FILE FORMAT
  ON SCHEMA {{DATABASE}}.{{RAW_SCHEMA}} TO ROLE {{ROLE}};
GRANT USAGE, CREATE TABLE, CREATE VIEW
  ON SCHEMA {{DATABASE}}.{{ANALYTICS_SCHEMA}} TO ROLE {{ROLE}};

-- dbt reads from RAW, writes to ANALYTICS
GRANT SELECT ON ALL TABLES    IN SCHEMA {{DATABASE}}.{{RAW_SCHEMA}} TO ROLE {{ROLE}};
GRANT SELECT ON FUTURE TABLES IN SCHEMA {{DATABASE}}.{{RAW_SCHEMA}} TO ROLE {{ROLE}};

-- Attach the role to the current user and make it the default for the session.
SET current_user_name = (SELECT CURRENT_USER());
GRANT ROLE {{ROLE}} TO USER IDENTIFIER($current_user_name);
