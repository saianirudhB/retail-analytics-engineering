-- Business rule: an order in status 'delivered' must carry a customer delivery
-- timestamp. If this fails, on-time / delivery-time KPIs silently drop orders.
-- (Documented known issue: see docs/data-quality.md — a small, fixed count in
-- the public dataset, so this is a WARN not an ERROR.)
{{ config(severity='warn') }}

select
    order_id,
    order_status,
    delivered_to_customer_at
from {{ ref('stg_orders') }}
where order_status = 'delivered'
  and delivered_to_customer_at is null
