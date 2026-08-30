-- Business rule: an order cannot be delivered to the customer before it was
-- purchased. Rows here indicate bad timestamps in the source and would produce
-- negative delivery durations.
select
    order_id,
    purchased_at,
    delivered_to_customer_at
from {{ ref('stg_orders') }}
where delivered_to_customer_at is not null
  and delivered_to_customer_at < purchased_at
