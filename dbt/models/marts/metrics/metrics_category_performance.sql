-- Product-category performance. One row per product category.
-- Revenue is measured at the line-item grain (a category's share of an order).
with items as (
    select * from {{ ref('fact_order_items') }}
),

products as (
    select product_key, product_category from {{ ref('dim_products') }}
),

joined as (
    select
        p.product_category,
        i.order_id,
        i.item_price,
        i.freight_value,
        i.item_quantity,
        i.review_score,
        case when i.order_status in {{ status_list(var('revenue_order_statuses')) }}
             then 1 else 0 end as is_revenue_line
    from items i
    join products p on i.product_key = p.product_key
)

select
    product_category,
    count(distinct order_id)                               as orders,
    sum(item_quantity)                                     as items_sold,
    sum(case when is_revenue_line = 1 then item_price else 0 end)     as product_revenue,
    sum(case when is_revenue_line = 1 then freight_value else 0 end)  as freight_revenue,
    round(sum(case when is_revenue_line = 1 then item_price else 0 end)
          / nullif(count(distinct order_id), 0), 2)        as revenue_per_order,
    round(avg(cast(review_score as double)), 3)            as avg_review_score
from joined
group by product_category
