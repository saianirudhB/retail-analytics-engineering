#!/usr/bin/env python3
"""
Exploratory / validation queries over the built warehouse.

    docker compose run --rm dbt python /workspace/analysis/run_eda.py

Reads the DuckDB target read-only and prints the figures used in
analysis/business-insights.md and docs/data-quality.md. Every number in those
docs comes from here — nothing is hand-typed.
"""
import textwrap
import duckdb

con = duckdb.connect("/workspace/dbt/retail.duckdb", read_only=True)


def show(title: str, sql: str) -> None:
    print("\n" + "=" * 78)
    print(title)
    print("-" * 78)
    print(con.sql(textwrap.dedent(sql)).df().to_string(index=False))


show("Row counts by layer", """
    select 'stg_order_items' as model, count(*) as n from analytics_staging.stg_order_items
    union all select 'fact_order_items', count(*) from analytics_marts.fact_order_items
    union all select 'dim_customers', count(*) from analytics_marts.dim_customers
    union all select 'dim_products', count(*) from analytics_marts.dim_products
    union all select 'dim_sellers', count(*) from analytics_marts.dim_sellers
    union all select 'dim_date', count(*) from analytics_marts.dim_date
    union all select 'fct_orders', count(*) from analytics_metrics.fct_orders
""")

show("Fact grain integrity", """
    select
        count(*)                                             as fact_rows,
        count(distinct order_item_key)                       as distinct_keys,
        count(*) - count(distinct order_item_key)            as key_dupes,
        (select count(*) from analytics_staging.stg_order_items) as stg_rows
    from analytics_marts.fact_order_items
""")

show("Null foreign keys in fact", """
    select
        sum(case when customer_key is null then 1 else 0 end) as null_customer_key,
        sum(case when product_key  is null then 1 else 0 end) as null_product_key,
        sum(case when seller_key   is null then 1 else 0 end) as null_seller_key,
        sum(case when order_purchased_date_key is null then 1 else 0 end) as null_date_key
    from analytics_marts.fact_order_items
""")

show("Executive summary (single row, transposed)", """
    select * from analytics_metrics.metrics_executive_summary
""")

show("Revenue reconciliation: line grain vs order grain", """
    select
        (select round(sum(item_price),2) from analytics_marts.fact_order_items)  as line_grain_revenue,
        (select round(sum(product_revenue),2) from analytics_metrics.fct_orders) as order_grain_revenue
""")

show("Orders by status", """
    select order_status, count(*) as orders,
           round(100.0*count(*)/sum(count(*)) over (), 2) as pct
    from analytics_metrics.fct_orders group by 1 order by 2 desc
""")

show("Top 10 categories by product revenue", """
    select product_category, orders, items_sold,
           round(product_revenue,2) as product_revenue,
           round(avg_review_score,2) as avg_review_score
    from analytics_metrics.metrics_category_performance
    order by product_revenue desc limit 10
""")

show("Monthly revenue & orders trend", """
    select year_month,
           orders,
           revenue_orders,
           round(product_revenue,2) as product_revenue,
           round(avg_order_value,2) as aov
    from (
        select floor(order_purchased_date_key/100) as year_month,
               count(*) as orders,
               sum(is_revenue_order) as revenue_orders,
               sum(recognised_product_revenue) as product_revenue,
               round(sum(recognised_product_revenue)/nullif(sum(is_revenue_order),0),2) as avg_order_value
        from analytics_metrics.fct_orders group by 1
    ) t order by year_month
""")

show("Delivery performance by month (delivered orders)", """
    select year_month, orders, delivered_orders,
           avg_delivery_days, avg_promised_days, avg_delay_days,
           on_time_delivery_rate, late_orders
    from analytics_metrics.metrics_delivery_performance
    order by year_month
""")

show("On-time delivery vs review score", """
    select
        case when is_on_time = 1 then 'on time' else 'late' end as delivery,
        count(*) as orders,
        round(avg(review_score),3) as avg_review_score
    from analytics_metrics.fct_orders
    where is_delivered = 1 and review_score is not null and is_on_time is not null
    group by 1
""")

show("Customer repeat behaviour", """
    select
        is_repeat_customer,
        count(*) as customers,
        round(100.0*count(*)/sum(count(*)) over (), 2) as pct
    from analytics_marts.dim_customers group by 1
""")

show("Revenue by customer region", """
    select c.customer_region,
           count(distinct o.order_id) as orders,
           round(sum(o.recognised_product_revenue),2) as product_revenue
    from analytics_metrics.fct_orders o
    join analytics_marts.dim_customers c on o.customer_key = c.customer_key
    group by 1 order by product_revenue desc
""")

show("Payment type mix", """
    select primary_payment_type, count(*) as orders,
           round(avg(max_installments),2) as avg_max_installments
    from analytics_metrics.fct_orders
    group by 1 order by orders desc
""")

show("DATA QUALITY: delivered orders missing delivery timestamp", """
    select count(*) as delivered_without_timestamp
    from analytics_staging.stg_orders
    where order_status = 'delivered' and delivered_to_customer_at is null
""")

show("DATA QUALITY: payment allocation vs true order payment total (> 0.05 BRL)", """
    with a as (
        select order_id, sum(allocated_payment_value) as allocated,
               count(*) as line_count
        from analytics_marts.fact_order_items group by 1
    ),
    p as (
        select o.order_id, p.payment_value as paid
        from analytics_staging.stg_orders o
        join (select order_id, sum(payment_value) as payment_value
              from analytics_staging.stg_order_payments group by 1) p using (order_id)
    )
    select p.order_id, round(p.paid,2) as true_paid,
           round(a.allocated,2) as allocated,
           round(a.allocated - p.paid, 2) as diff, a.line_count
    from p join a using (order_id)
    where a.allocated is not null and p.paid > 0
      and abs(a.allocated - p.paid) > 0.05
""")

show("DATA QUALITY: orders with no line items (in orders, not in order_items)", """
    select count(*) as orders_without_items
    from analytics_staging.stg_orders o
    left join analytics_staging.stg_order_items i on o.order_id = i.order_id
    where i.order_id is null
""")

show("DATA QUALITY: negative / zero financials in fact", """
    select
        sum(case when item_price <= 0 then 1 else 0 end)   as non_positive_price,
        sum(case when freight_value < 0 then 1 else 0 end) as negative_freight
    from analytics_marts.fact_order_items
""")

print("\n" + "=" * 78)
print("done")
