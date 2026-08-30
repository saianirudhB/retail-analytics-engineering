-- =============================================================================
-- 03 — CSV file format + internal stage used by the COPY INTO load.
-- =============================================================================
USE SCHEMA {{DATABASE}}.{{RAW_SCHEMA}};

CREATE FILE FORMAT IF NOT EXISTS OLIST_CSV
    TYPE = CSV
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF = ('', 'NULL', 'null')
    EMPTY_FIELD_AS_NULL = TRUE
    TRIM_SPACE = TRUE
    ESCAPE_UNENCLOSED_FIELD = NONE
    -- review comments contain embedded newlines inside quotes
    MULTI_LINE = TRUE
    COMMENT = 'Olist public dataset CSV layout';

CREATE STAGE IF NOT EXISTS RAW_STAGE
    FILE_FORMAT = OLIST_CSV
    COMMENT = 'Internal stage: local Olist CSVs are PUT here, then COPY INTO the raw tables';
