-- Delivery operations KPIs by month. One row per purchase month.
-- Only delivered orders contribute to duration/delay/on-time figures.
with orders as (
    select * from {{ ref('fct_orders') }}
),

monthly as (
    select
        (order_purchased_date_key / 100)                           as year_month,  -- YYYYMM
        count(*)                                                   as orders,
        sum(is_delivered)                                          as delivered_orders,
        avg(case when is_delivered = 1 then cast(delivery_days as double) end)
                                                                  as avg_delivery_days,
        avg(case when is_delivered = 1 then cast(estimated_delivery_days as double) end)
                                                                  as avg_promised_days,
        avg(case when is_delivered = 1 then cast(delivery_delay_days as double) end)
                                                                  as avg_delay_days,
        avg(case when is_on_time is null then null
                 else cast(is_on_time as double) end)              as on_time_rate,
        sum(case when delivery_delay_days > 0 then 1 else 0 end)   as late_orders
    from orders
    group by 2
)

select
    year_month,
    orders,
    delivered_orders,
    round(avg_delivery_days, 2)  as avg_delivery_days,
    round(avg_promised_days, 2)  as avg_promised_days,
    round(avg_delay_days, 2)     as avg_delay_days,
    round(on_time_rate, 4)       as on_time_delivery_rate,
    late_orders
from monthly
