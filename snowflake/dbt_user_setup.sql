/* =============================================================================
   dbt_user_setup.sql   (run ONCE in Snowsight as ACCOUNTADMIN)
   -----------------------------------------------------------------------------
   dbt needs its own login. Same idea as S2C_INGEST_SVC for GitHub uploads:
   a SERVICE user with key-pair auth and the least-privilege role S2C_TRANSFORMER
   (read RAW / AUDIT / STREAMING, build STAGING / INTERMEDIATE / SNAPSHOTS / MARTS).

   For this project we reuse the key pair you already made (~/.ssh/snowflake/rsa_key.p8).
   In a company each service user gets its own key.
   ============================================================================= */

USE ROLE ACCOUNTADMIN;

CREATE USER IF NOT EXISTS S2C_DBT_SVC
  TYPE = SERVICE
  DEFAULT_ROLE = S2C_TRANSFORMER
  DEFAULT_WAREHOUSE = S2C_WH
  DEFAULT_NAMESPACE = 'S2C_DEV.STAGING'
  COMMENT = 'dbt Core: builds STAGING / INTERMEDIATE / SNAPSHOTS / MARTS';

GRANT ROLE S2C_TRANSFORMER TO USER S2C_DBT_SVC;

-- also let YOUR user switch to the dbt role in Snowsight (to look at what dbt built)
SET my_user = CURRENT_USER();
GRANT ROLE S2C_TRANSFORMER TO USER IDENTIFIER($my_user);

-- dbt reads the audit views and the speed-layer tables
GRANT SELECT ON ALL VIEWS  IN SCHEMA S2C_DEV.AUDIT     TO ROLE S2C_TRANSFORMER;
GRANT SELECT ON ALL TABLES IN SCHEMA S2C_DEV.AUDIT     TO ROLE S2C_TRANSFORMER;
GRANT SELECT ON ALL TABLES IN SCHEMA S2C_DEV.STREAMING TO ROLE S2C_TRANSFORMER;
GRANT SELECT ON ALL TABLES IN SCHEMA S2C_DEV.RAW       TO ROLE S2C_TRANSFORMER;

-- analysts read Gold
GRANT USAGE ON SCHEMA S2C_DEV.MARTS TO ROLE S2C_ANALYST;

-- Paste the SAME public key you used for S2C_INGEST_SVC. Easiest: in the terminal run
--   echo "ALTER USER S2C_DBT_SVC SET RSA_PUBLIC_KEY = '$(grep -v 'PUBLIC KEY' ~/.ssh/snowflake/rsa_key.pub | tr -d '\n')';" | pbcopy
-- then paste here and run that one line:
-- ALTER USER S2C_DBT_SVC SET RSA_PUBLIC_KEY = 'MIIB...';

DESC USER S2C_DBT_SVC;
