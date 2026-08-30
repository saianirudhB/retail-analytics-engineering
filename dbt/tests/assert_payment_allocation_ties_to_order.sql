-- The per-line allocated_payment_value is a proportional split of the order's
-- paid amount. Summed back to the order it must equal the order's total payment
-- value, allowing 1 cent of rounding per line (each line is rounded to 2 dp).
-- Orders with zero item value or no payment record are excluded.
with allocated as (
    select
        order_id,
        sum(allocated_payment_value) as allocated_total,
        count(*)                     as line_count
    from {{ ref('fact_order_items') }}
    group by order_id
),

paid as (
    select order_id, order_paid_amount
    from {{ ref('int_payments_by_order') }}
    where order_paid_amount > 0
)

select
    p.order_id,
    p.order_paid_amount,
    a.allocated_total,
    a.line_count
from paid p
join allocated a on p.order_id = a.order_id
where a.allocated_total is not null
  and abs(a.allocated_total - p.order_paid_amount) > 0.01 * a.line_count + 0.01
