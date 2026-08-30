-- Customer dimension at the STABLE shopper grain (customer_unique_id).
--
-- Why not customer_id? Olist mints a fresh customer_id per order and keeps
-- customer_unique_id constant across a shopper's orders. Modelling on
-- customer_unique_id is what lets us talk about repeat purchase behaviour.
--
-- Location is descriptive and can change between orders; we take the value from
-- the shopper's MOST RECENT order (a type-1 / "current value" attribute — see
-- docs/data-model.md for the SCD discussion).
{{ config(materialized='table') }}

with customers as (
    select * from {{ ref('stg_customers') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

geo as (
    select * from {{ ref('stg_geolocation') }}
),

-- one row per (customer_unique_id, order) with its purchase time
customer_orders as (
    select
        c.customer_unique_id,
        c.customer_id,
        c.customer_city,
        c.customer_state,
        c.customer_zip_code_prefix,
        o.purchased_at,
        row_number() over (
            partition by c.customer_unique_id
            order by o.purchased_at desc, o.order_id
        ) as recency_rank
    from customers c
    join orders o on c.customer_id = o.customer_id
),

latest_attributes as (
    select
        customer_unique_id,
        customer_city    as customer_city,
        customer_state   as customer_state,
        customer_zip_code_prefix
    from customer_orders
    where recency_rank = 1
),

lifecycle as (
    select
        customer_unique_id,
        count(*)                        as lifetime_order_count,
        count(distinct customer_id)     as distinct_customer_ids,
        min(purchased_at)               as first_order_at,
        max(purchased_at)               as most_recent_order_at
    from customer_orders
    group by customer_unique_id
)

select
    {{ dbt_utils.generate_surrogate_key(['la.customer_unique_id']) }} as customer_key,
    la.customer_unique_id,
    la.customer_city,
    la.customer_state,
    {{ brazil_region('la.customer_state') }}                          as customer_region,
    la.customer_zip_code_prefix,
    g.latitude                                                        as customer_latitude,
    g.longitude                                                       as customer_longitude,
    lc.first_order_at,
    lc.most_recent_order_at,
    cast(lc.first_order_at as date)                                   as first_order_date,
    lc.lifetime_order_count,
    lc.distinct_customer_ids,
    case when lc.lifetime_order_count > 1 then true else false end    as is_repeat_customer
from latest_attributes la
join lifecycle lc using (customer_unique_id)
left join geo g on la.customer_zip_code_prefix = g.zip_code_prefix
