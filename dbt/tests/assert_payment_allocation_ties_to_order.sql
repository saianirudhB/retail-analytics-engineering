-- The per-line allocated_payment_value is a split of the order's paid amount.
-- Summed back to the order it must equal the order's total payment value
-- (within rounding). Orders with zero item value are excluded (nothing to
-- allocate against) as are orders with no payment record.
{{ config(severity='warn') }}

with allocated as (
    select
        order_id,
        sum(allocated_payment_value) as allocated_total
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
    a.allocated_total
from paid p
join allocated a on p.order_id = a.order_id
where a.allocated_total is not null
  and abs(a.allocated_total - p.order_paid_amount) > 0.05
