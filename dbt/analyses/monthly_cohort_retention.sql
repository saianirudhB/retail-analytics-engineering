-- dbt analysis (compiled by `dbt compile`, never materialised).
--
-- Monthly acquisition cohort retention: of the customers first seen in month M,
-- what share place another order in each subsequent month. Referenced in
-- analysis/business-insights.md as the recommended follow-up to the 3% repeat rate.
--
-- Run the compiled SQL from target/compiled/... against the warehouse, or paste
-- into a Snowflake / DuckDB worksheet.

with orders as (
    select
        customer_key,
        cast(purchased_at as date) as order_date
    from {{ ref('fct_orders') }}
    where customer_key is not null
),

first_order as (
    select
        customer_key,
        date_trunc('month', min(order_date)) as cohort_month
    from orders
    group by customer_key
),

activity as (
    select
        f.cohort_month,
        date_trunc('month', o.order_date) as activity_month,
        o.customer_key
    from orders o
    join first_order f using (customer_key)
),

cohort_size as (
    select cohort_month, count(*) as customers
    from first_order
    group by cohort_month
)

select
    a.cohort_month,
    a.activity_month,
    {{ dbt.datediff('a.cohort_month', 'a.activity_month', 'month') }} as month_number,
    count(distinct a.customer_key)                                    as active_customers,
    cs.customers                                                      as cohort_customers,
    round(100.0 * count(distinct a.customer_key) / cs.customers, 2)   as retention_pct
from activity a
join cohort_size cs on a.cohort_month = cs.cohort_month
group by a.cohort_month, a.activity_month, cs.customers
order by a.cohort_month, a.activity_month
