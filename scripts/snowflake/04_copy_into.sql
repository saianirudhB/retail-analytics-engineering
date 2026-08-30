-- =============================================================================
-- 04 — Reference COPY INTO statements.
--
-- scripts/load_raw.py already runs the PUT + COPY for every table. This file is
-- the hand-run equivalent: after PUTting the CSVs to @RAW_STAGE/<table>/, run
-- these in a worksheet. Column order in each CSV matches the DDL in 02_raw_ddl.sql,
-- so a positional COPY is safe.
-- =============================================================================
USE SCHEMA {{DATABASE}}.{{RAW_SCHEMA}};

COPY INTO orders          FROM @RAW_STAGE/orders/          FILE_FORMAT=(FORMAT_NAME=OLIST_CSV) ON_ERROR=ABORT_STATEMENT;
COPY INTO order_items     FROM @RAW_STAGE/order_items/     FILE_FORMAT=(FORMAT_NAME=OLIST_CSV) ON_ERROR=ABORT_STATEMENT;
COPY INTO order_payments  FROM @RAW_STAGE/order_payments/  FILE_FORMAT=(FORMAT_NAME=OLIST_CSV) ON_ERROR=ABORT_STATEMENT;
COPY INTO order_reviews   FROM @RAW_STAGE/order_reviews/   FILE_FORMAT=(FORMAT_NAME=OLIST_CSV) ON_ERROR=ABORT_STATEMENT;
COPY INTO customers       FROM @RAW_STAGE/customers/       FILE_FORMAT=(FORMAT_NAME=OLIST_CSV) ON_ERROR=ABORT_STATEMENT;
COPY INTO products        FROM @RAW_STAGE/products/        FILE_FORMAT=(FORMAT_NAME=OLIST_CSV) ON_ERROR=ABORT_STATEMENT;
COPY INTO sellers         FROM @RAW_STAGE/sellers/         FILE_FORMAT=(FORMAT_NAME=OLIST_CSV) ON_ERROR=ABORT_STATEMENT;
COPY INTO geolocation     FROM @RAW_STAGE/geolocation/     FILE_FORMAT=(FORMAT_NAME=OLIST_CSV) ON_ERROR=ABORT_STATEMENT;
COPY INTO product_category_name_translation
                          FROM @RAW_STAGE/product_category_name_translation/
                          FILE_FORMAT=(FORMAT_NAME=OLIST_CSV) ON_ERROR=ABORT_STATEMENT;
