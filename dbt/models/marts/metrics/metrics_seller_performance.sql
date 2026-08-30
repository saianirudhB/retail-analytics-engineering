-- Seller scorecard. One row per seller: volume, revenue, delivery and review
-- performance for the lines they fulfilled.
with items as (
    select * from {{ ref('fact_order_items') }}
),

sellers as (
    select seller_key, seller_id, seller_state, seller_region from {{ ref('dim_sellers') }}
),

joined as (
    select
        s.seller_id,
        s.seller_state,
        s.seller_region,
        i.order_id,
        i.item_price,
        i.freight_value,
        i.item_quantity,
        i.delivery_days,
        i.is_on_time,
        i.review_score,
        case when i.order_status in {{ status_list(var('revenue_order_statuses')) }}
             then 1 else 0 end as is_revenue_line
    from items i
    join sellers s on i.seller_key = s.seller_key
)

select
    seller_id,
    seller_state,
    seller_region,
    count(distinct order_id)                                        as orders,
    sum(item_quantity)                                              as items_sold,
    sum(case when is_revenue_line = 1 then item_price else 0 end)    as product_revenue,
    round(sum(case when is_revenue_line = 1 then item_price else 0 end)
          / nullif(count(distinct order_id), 0), 2)                 as revenue_per_order,
    round(avg(cast(delivery_days as double)), 1)                    as avg_delivery_days,
    round(avg(case when is_on_time is null then null
                   when is_on_time then 1.0 else 0.0 end), 4)       as on_time_delivery_rate,
    round(avg(cast(review_score as double)), 3)                     as avg_review_score
from joined
group by seller_id, seller_state, seller_region
