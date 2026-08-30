-- Aggregate payment instruments to ONE row per order.
-- Used to attach order-level payment context to the fact without fanning out
-- the line-item grain.
with payments as (
    select * from {{ ref('stg_order_payments') }}
),

primary_type as (
    -- the payment type carrying the largest share of the order value
    select
        order_id,
        payment_type,
        row_number() over (
            partition by order_id
            order by sum(payment_value) desc, payment_type
        ) as rn
    from payments
    group by order_id, payment_type
),

aggregated as (
    select
        order_id,
        sum(payment_value)                                as order_paid_amount,
        count(*)                                          as payment_instrument_count,
        max(payment_installments)                         as max_installments,
        max(case when payment_type = 'voucher'     then 1 else 0 end) = 1 as used_voucher,
        max(case when payment_type = 'credit_card' then 1 else 0 end) = 1 as used_credit_card
    from payments
    group by order_id
)

select
    a.order_id,
    a.order_paid_amount,
    a.payment_instrument_count,
    a.max_installments,
    a.used_voucher,
    a.used_credit_card,
    p.payment_type as primary_payment_type
from aggregated a
left join primary_type p
    on a.order_id = p.order_id and p.rn = 1
