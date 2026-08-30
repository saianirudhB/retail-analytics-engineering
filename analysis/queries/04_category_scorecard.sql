-- Category scorecard: revenue leaders vs review performance and freight load.
select
    c.product_category,
    c.orders,
    c.items_sold,
    round(c.product_revenue, 2)                         as product_revenue,
    round(c.freight_revenue, 2)                         as freight_revenue,
    round(100.0 * c.freight_revenue
          / nullif(c.product_revenue, 0), 1)            as freight_pct_of_product_rev,
    round(c.avg_review_score, 2)                        as avg_review_score
from analytics_metrics.metrics_category_performance c
where c.orders > 200
order by c.product_revenue desc;
