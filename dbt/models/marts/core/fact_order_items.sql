-- =============================================================================
-- fact_order_items
--
-- GRAIN: exactly one row per order line item — (order_id, order_item_number).
--        `order_item_key` is the surrogate PK and is unique.
--
-- Additive measures (safe to SUM at any grain):
--     item_price, freight_value, item_total_value, item_quantity,
--     allocated_payment_value
--
-- Order-level measures (repeated on every line of an order — AVERAGE per order,
-- never SUM across lines): delivery_days, estimated_delivery_days,
-- delivery_delay_days, review_score, and the *_flag columns.
-- Use `is_first_item_in_order` to pick one line per order when aggregating these.
--
-- Fanout control: every dimension join is many-to-one. Payments are pre-
-- aggregated to order grain (int_payments_by_order) and reviews are de-duped to
-- one row per order (int_order_reviews), so neither fans out the line grain.
-- =============================================================================
{{ config(
    materialized='table',
    unique_key='order_item_key'
) }}

with items as (
    select * from {{ ref('stg_order_items') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

customers as (
    select customer_id, customer_unique_id from {{ ref('stg_customers') }}
),

dim_customers as (
    select customer_key, customer_unique_id from {{ ref('dim_customers') }}
),

dim_products as (
    select product_key, product_id from {{ ref('dim_products') }}
),

dim_sellers as (
    select seller_key, seller_id from {{ ref('dim_sellers') }}
),

payments as (
    select * from {{ ref('int_payments_by_order') }}
),

reviews as (
    select * from {{ ref('int_order_reviews') }}
),

-- share of each line in its order, for allocating the order-level paid amount
order_item_totals as (
    select
        order_id,
        sum(item_total_value) as order_items_total_value,
        count(*)              as order_line_count
    from items
    group by order_id
),

joined as (
    select
        i.order_item_key,
        i.order_id,
        i.order_item_number,
        o.order_status,

        -- ---- foreign keys ------------------------------------------------
        dc.customer_key,
        dp.product_key,
        ds.seller_key,
        {{ date_to_key('o.purchased_at') }}             as order_purchased_date_key,
        {{ date_to_key('o.approved_at') }}              as order_approved_date_key,
        {{ date_to_key('o.delivered_to_customer_at') }} as order_delivered_date_key,
        {{ date_to_key('o.estimated_delivery_at') }}    as order_estimated_delivery_date_key,

        -- ---- degenerate timestamps ------------------------------------
        o.purchased_at,
        o.delivered_to_customer_at,
        o.estimated_delivery_at,

        -- ---- additive measures --------------------------------------
        1                                                       as item_quantity,
        i.item_price,
        i.freight_value,
        i.item_total_value,
        case
            when coalesce(oit.order_items_total_value, 0) > 0
            then round(
                coalesce(pay.order_paid_amount, 0)
                * (i.item_total_value / oit.order_items_total_value), 2)
            else null
        end                                                     as allocated_payment_value,

        -- ---- order-level measures (repeated per line) --------------
        pay.primary_payment_type,
        pay.max_installments,
        rv.review_score,

        case
            when o.delivered_to_customer_at is not null and o.purchased_at is not null
            then {{ dbt.datediff('cast(o.purchased_at as date)',
                                 'cast(o.delivered_to_customer_at as date)', 'day') }}
        end                                                     as delivery_days,
        case
            when o.estimated_delivery_at is not null and o.purchased_at is not null
            then {{ dbt.datediff('cast(o.purchased_at as date)',
                                 'cast(o.estimated_delivery_at as date)', 'day') }}
        end                                                     as estimated_delivery_days,
        case
            when o.delivered_to_customer_at is not null and o.estimated_delivery_at is not null
            then {{ dbt.datediff('cast(o.estimated_delivery_at as date)',
                                 'cast(o.delivered_to_customer_at as date)', 'day') }}
        end                                                     as delivery_delay_days,

        -- ---- flags ------------------------------------------------
        case when o.order_status = 'delivered' then true else false end as is_delivered,
        case when o.order_status = 'canceled'  then true else false end as is_canceled,
        case
            when o.order_status = 'delivered'
             and o.delivered_to_customer_at is not null
             and o.estimated_delivery_at   is not null
            then case when o.delivered_to_customer_at <= o.estimated_delivery_at
                      then true else false end
        end                                                     as is_on_time,
        case
            when row_number() over (partition by i.order_id
                                    order by i.order_item_number) = 1
            then true else false end                            as is_first_item_in_order

    from items i
    inner join orders     o   on i.order_id  = o.order_id
    left  join customers  cu  on o.customer_id = cu.customer_id
    left  join dim_customers dc on cu.customer_unique_id = dc.customer_unique_id
    left  join dim_products  dp on i.product_id = dp.product_id
    left  join dim_sellers   ds on i.seller_id  = ds.seller_id
    left  join order_item_totals oit on i.order_id = oit.order_id
    left  join payments      pay on i.order_id = pay.order_id
    left  join reviews       rv  on i.order_id = rv.order_id
)

select * from joined
