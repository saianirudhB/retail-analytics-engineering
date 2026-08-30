-- Customer value + RFM segmentation. One row per customer (customer_key).
-- Recency is measured against the last purchase date in the dataset (static
-- public data), not today's date.
with orders as (
    select * from {{ ref('fct_orders') }}
),

customers as (
    select customer_key, customer_unique_id, customer_state, customer_region
    from {{ ref('dim_customers') }}
),

dataset_bounds as (
    select max(cast(purchased_at as date)) as last_date from orders
),

per_customer as (
    select
        o.customer_key,
        count(*)                                    as frequency,
        sum(o.recognised_product_revenue)           as monetary,
        max(cast(o.purchased_at as date))           as last_order_date,
        min(cast(o.purchased_at as date))           as first_order_date
    from orders o
    where o.customer_key is not null
    group by o.customer_key
),

scored as (
    select
        pc.*,
        c.customer_unique_id,
        c.customer_state,
        c.customer_region,
        {{ dbt.datediff('pc.last_order_date', '(select last_date from dataset_bounds)', 'day') }} as recency_days
    from per_customer pc
    join customers c on pc.customer_key = c.customer_key
)

select
    customer_key,
    customer_unique_id,
    customer_state,
    customer_region,
    first_order_date,
    last_order_date,
    recency_days,
    frequency,
    round(monetary, 2)                              as monetary,
    round(monetary / nullif(frequency, 0), 2)       as avg_order_value,
    case
        when frequency >= 3                      then 'loyal'
        when frequency = 2                       then 'returning'
        when recency_days <= 90                  then 'recent one-time'
        else 'lapsed one-time'
    end                                             as customer_segment
from scored
