-- Consistency rule: total product revenue computed at the line grain
-- (fact_order_items) must equal the total computed at the order grain
-- (fct_orders). A mismatch means the roll-up lost or duplicated rows.
with line_grain as (
    select sum(item_price) as revenue
    from {{ ref('fact_order_items') }}
),

order_grain as (
    select sum(product_revenue) as revenue
    from {{ ref('fct_orders') }}
)

select
    l.revenue as line_grain_revenue,
    o.revenue as order_grain_revenue
from line_grain l
cross join order_grain o
where abs(l.revenue - o.revenue) > 0.01
