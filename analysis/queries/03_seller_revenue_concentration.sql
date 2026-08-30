-- Revenue concentration across sellers (Pareto).
with ranked as (
    select
        seller_id,
        product_revenue,
        row_number() over (order by product_revenue desc) as rnk,
        sum(product_revenue) over ()                       as total_revenue
    from analytics_metrics.metrics_seller_performance
)
select
    case
        when rnk <= 100 then 'top 100'
        when rnk <= 500 then 'rank 101-500'
        else 'rank 501+'
    end                                                     as seller_bucket,
    count(*)                                                as sellers,
    round(sum(product_revenue), 2)                          as product_revenue,
    round(100.0 * sum(product_revenue) / max(total_revenue), 1) as pct_of_revenue
from ranked
group by 1
order by product_revenue desc;
