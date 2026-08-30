-- =============================================================================
-- 02 — RAW tables. Types mirror the source CSVs closely; anything ambiguous is
-- landed as STRING and cast in the dbt staging layer (raw stays faithful to
-- what Olist published). Column names are kept verbatim from the CSV headers.
-- =============================================================================
USE SCHEMA {{DATABASE}}.{{RAW_SCHEMA}};

CREATE TABLE IF NOT EXISTS orders (
    order_id                      STRING,
    customer_id                   STRING,
    order_status                  STRING,
    order_purchase_timestamp      TIMESTAMP_NTZ,
    order_approved_at             TIMESTAMP_NTZ,
    order_delivered_carrier_date  TIMESTAMP_NTZ,
    order_delivered_customer_date TIMESTAMP_NTZ,
    order_estimated_delivery_date TIMESTAMP_NTZ
);

CREATE TABLE IF NOT EXISTS order_items (
    order_id            STRING,
    order_item_id       NUMBER(9,0),
    product_id          STRING,
    seller_id           STRING,
    shipping_limit_date TIMESTAMP_NTZ,
    price               NUMBER(12,2),
    freight_value       NUMBER(12,2)
);

CREATE TABLE IF NOT EXISTS order_payments (
    order_id             STRING,
    payment_sequential   NUMBER(9,0),
    payment_type         STRING,
    payment_installments NUMBER(9,0),
    payment_value        NUMBER(12,2)
);

CREATE TABLE IF NOT EXISTS order_reviews (
    review_id               STRING,
    order_id                STRING,
    review_score            NUMBER(2,0),
    review_comment_title    STRING,
    review_comment_message  STRING,
    review_creation_date    TIMESTAMP_NTZ,
    review_answer_timestamp TIMESTAMP_NTZ
);

CREATE TABLE IF NOT EXISTS customers (
    customer_id              STRING,
    customer_unique_id       STRING,
    customer_zip_code_prefix STRING,
    customer_city            STRING,
    customer_state           STRING
);

CREATE TABLE IF NOT EXISTS products (
    product_id                 STRING,
    product_category_name      STRING,
    product_name_lenght        NUMBER(9,0),   -- sic: misspelled in the source
    product_description_lenght NUMBER(9,0),   -- sic
    product_photos_qty         NUMBER(9,0),
    product_weight_g           NUMBER(12,0),
    product_length_cm          NUMBER(12,0),
    product_height_cm          NUMBER(12,0),
    product_width_cm           NUMBER(12,0)
);

CREATE TABLE IF NOT EXISTS sellers (
    seller_id              STRING,
    seller_zip_code_prefix STRING,
    seller_city            STRING,
    seller_state           STRING
);

CREATE TABLE IF NOT EXISTS geolocation (
    geolocation_zip_code_prefix STRING,
    geolocation_lat             FLOAT,
    geolocation_lng             FLOAT,
    geolocation_city            STRING,
    geolocation_state           STRING
);

CREATE TABLE IF NOT EXISTS product_category_name_translation (
    product_category_name         STRING,
    product_category_name_english STRING
);
