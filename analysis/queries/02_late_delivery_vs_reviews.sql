-- Does late delivery drive bad reviews? (delivered orders with a review)
select
    case when o.is_on_time = 1 then 'on time' else 'late' end as delivery_outcome,
    count(*)                                                  as orders,
    round(avg(o.review_score), 3)                             as avg_review_score,
    round(avg(o.delivery_delay_days), 1)                      as avg_delay_days
from analytics_metrics.fct_orders o
where o.is_delivered = 1
  and o.review_score is not null
  and o.is_on_time is not null
group by 1;
