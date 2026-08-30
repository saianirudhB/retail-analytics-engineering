-- Collapse reviews to ONE row per order so it can be joined onto the fact
-- without fanout. ~99% of orders have a single review; where there are several,
-- keep the most recently created one.
with reviews as (
    select * from {{ ref('stg_order_reviews') }}
),

ranked as (
    select
        *,
        row_number() over (
            partition by order_id
            order by review_created_at desc, review_id
        ) as rn
    from reviews
)

select
    order_id,
    review_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_created_at,
    review_answered_at
from ranked
where rn = 1
