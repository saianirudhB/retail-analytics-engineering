-- One row per per-order customer identity (customer_id).
-- customer_unique_id is the stable shopper key used downstream in dim_customers.
with source as (
    select * from {{ source('olist', 'customers') }}
),

renamed as (
    select
        customer_id,
        customer_unique_id,
        lpad(cast(customer_zip_code_prefix as varchar), 5, '0') as customer_zip_code_prefix,
        lower(trim(customer_city))                              as customer_city,
        upper(trim(customer_state))                             as customer_state
    from source
)

select * from renamed
