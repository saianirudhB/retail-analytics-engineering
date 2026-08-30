-- Delivery operations KPIs by purchase month. One row per calendar month.
-- Only delivered orders contribute to duration / delay / on-time figures.
with orders as (
    select * from {{ ref('fct_orders') }}
),

dates as (
    select date_key, year, month, year_month
    from {{ ref('dim_date') }}
),

monthly as (
    select
        d.year_month,
        d.year,
        d.month,
        count(*)                                                  as orders,
        sum(o.is_delivered)                                       as delivered_orders,
        avg(case when o.is_delivered = 1 then cast(o.delivery_days as double) end)
                                                                 as avg_delivery_days,
        avg(case when o.is_delivered = 1 then cast(o.estimated_delivery_days as double) end)
                                                                 as avg_promised_days,
        avg(case when o.is_delivered = 1 then cast(o.delivery_delay_days as double) end)
                                                                 as avg_delay_days,
        avg(case when o.is_on_time is null then null
                 else cast(o.is_on_time as double) end)          as on_time_rate,
        sum(case when o.delivery_delay_days > 0 then 1 else 0 end) as late_orders
    from orders o
    join dates d on o.order_purchased_date_key = d.date_key
    group by d.year_month, d.year, d.month
)

select
    year_month,
    year,
    month,
    orders,
    delivered_orders,
    round(avg_delivery_days, 2)  as avg_delivery_days,
    round(avg_promised_days, 2)  as avg_promised_days,
    round(avg_delay_days, 2)     as avg_delay_days,
    round(on_time_rate, 4)       as on_time_delivery_rate,
    late_orders
from monthly
