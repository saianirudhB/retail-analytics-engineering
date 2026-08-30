-- Monthly orders, revenue and AOV. Runs against the metrics layer.
select
    d.year_month,
    count(*)                                        as orders,
    sum(o.is_revenue_order)                         as revenue_orders,
    round(sum(o.recognised_product_revenue), 2)     as product_revenue,
    round(sum(o.recognised_product_revenue)
          / nullif(sum(o.is_revenue_order), 0), 2)  as avg_order_value
from analytics_metrics.fct_orders o
join analytics_marts.dim_date d
  on o.order_purchased_date_key = d.date_key
group by d.year_month
order by d.year_month;
