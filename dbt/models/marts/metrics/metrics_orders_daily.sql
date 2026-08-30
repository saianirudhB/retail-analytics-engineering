-- Daily company-level KPIs. One row per purchase date.
-- Every downstream time-series chart (revenue trend, order trend, AOV trend)
-- reads from here so the numbers reconcile.
with orders as (
    select * from {{ ref('fct_orders') }}
),

daily as (
    select
        order_purchased_date_key                          as date_key,
        cast(purchased_at as date)                         as order_date,

        count(*)                                           as orders,
        sum(is_revenue_order)                              as revenue_orders,
        sum(is_canceled)                                   as canceled_orders,
        sum(item_count)                                    as items_sold,

        sum(recognised_product_revenue)                    as product_revenue,
        sum(case when is_revenue_order = 1 then freight_revenue else 0 end)
                                                          as freight_revenue,
        sum(case when is_revenue_order = 1 then gross_merchandise_value else 0 end)
                                                          as gross_merchandise_value
    from orders
    group by 1, 2
)

select
    *,
    round(product_revenue
          / nullif(revenue_orders, 0), 2)                 as avg_order_value,
    round(cast(canceled_orders as double)
          / nullif(orders, 0), 4)                         as cancellation_rate
from daily
