-- Order-grain roll-up of fact_order_items: ONE row per order.
--
-- This is the building block every order-level metric model reads from, so the
-- "what counts as an order / as revenue" rules live here once. Line-level
-- additive measures are summed; order-level measures are identical across an
-- order's lines by construction, so max() just picks that single value.
-- Portable aggregates only (no bool_or / BOOLOR_AGG).
with items as (
    select * from {{ ref('fact_order_items') }}
),

order_level as (
    select
        order_id,
        max(order_status)                      as order_status,
        max(customer_key)                      as customer_key,
        max(order_purchased_date_key)          as order_purchased_date_key,
        min(purchased_at)                      as purchased_at,
        max(delivered_to_customer_at)          as delivered_to_customer_at,
        max(estimated_delivery_at)             as estimated_delivery_at,

        count(*)                               as line_count,
        sum(item_quantity)                     as item_count,
        count(distinct product_key)            as distinct_product_count,
        count(distinct seller_key)             as distinct_seller_count,

        sum(item_price)                        as product_revenue,
        sum(freight_value)                     as freight_revenue,
        sum(item_total_value)                  as gross_merchandise_value,
        sum(allocated_payment_value)           as paid_amount,

        max(delivery_days)                     as delivery_days,
        max(estimated_delivery_days)           as estimated_delivery_days,
        max(delivery_delay_days)               as delivery_delay_days,
        max(review_score)                      as review_score,
        max(primary_payment_type)              as primary_payment_type,
        max(max_installments)                  as max_installments,

        max(case when is_delivered then 1 else 0 end) as is_delivered,
        max(case when is_canceled  then 1 else 0 end) as is_canceled,
        max(case when is_on_time   then 1 else 0 end) as is_on_time
    from items
    group by order_id
)

select
    *,
    case when order_status in {{ status_list(var('revenue_order_statuses')) }}
         then product_revenue else 0 end       as recognised_product_revenue,
    case when order_status in {{ status_list(var('revenue_order_statuses')) }}
         then 1 else 0 end                     as is_revenue_order
from order_level
