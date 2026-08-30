-- Single-row executive KPI snapshot for the top of the dashboard.
-- Every figure here is derived from fct_orders so it ties out to the detailed
-- metric models.
with orders as (
    select * from {{ ref('fct_orders') }}
),

items as (
    select * from {{ ref('fact_order_items') }}
)

select
    (select count(*) from orders)                                       as total_orders,
    (select sum(is_revenue_order) from orders)                          as revenue_orders,
    (select count(distinct customer_key) from orders)                   as total_customers,
    (select count(*) from items)                                        as total_line_items,
    (select sum(item_count) from orders)                                as total_items_sold,

    (select round(sum(recognised_product_revenue), 2) from orders)      as total_product_revenue,
    (select round(sum(case when is_revenue_order = 1 then freight_revenue else 0 end), 2)
       from orders)                                                     as total_freight_revenue,
    (select round(sum(recognised_product_revenue)
                  / nullif(sum(is_revenue_order), 0), 2) from orders)   as avg_order_value,

    (select round(avg(case when is_delivered = 1 then cast(delivery_days as double) end), 2)
       from orders)                                                     as avg_delivery_days,
    (select round(avg(case when is_delivered = 1 then cast(delivery_delay_days as double) end), 2)
       from orders)                                                     as avg_delivery_delay_days,
    (select round(avg(case when is_on_time is null then null
                           else cast(is_on_time as double) end), 4) from orders)
                                                                        as on_time_delivery_rate,
    (select round(cast(sum(is_canceled) as double)
                  / nullif(count(*), 0), 4) from orders)                as cancellation_rate,
    (select round(avg(cast(review_score as double)), 3) from orders)    as avg_review_score,

    (select min(cast(purchased_at as date)) from orders)                as first_order_date,
    (select max(cast(purchased_at as date)) from orders)                as last_order_date
