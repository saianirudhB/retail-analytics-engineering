-- One row per order line item. Grain = (order_id, order_item_id).
-- order_item_id is a 1..n sequence within an order and also encodes quantity
-- (two units of the same product => two rows, item ids 1 and 2).
with source as (
    select * from {{ source('olist', 'order_items') }}
),

renamed as (
    select
        {{ dbt_utils.generate_surrogate_key(['order_id', 'order_item_id']) }} as order_item_key,
        order_id,
        cast(order_item_id as integer)                as order_item_number,
        product_id,
        seller_id,
        cast(shipping_limit_date as timestamp)        as shipping_limit_at,
        cast(price as {{ dbt.type_numeric() }})       as item_price,
        cast(freight_value as {{ dbt.type_numeric() }}) as freight_value,
        cast(price as {{ dbt.type_numeric() }})
            + cast(freight_value as {{ dbt.type_numeric() }}) as item_total_value
    from source
)

select * from renamed
