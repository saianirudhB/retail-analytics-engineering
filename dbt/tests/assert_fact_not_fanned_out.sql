-- Fanout guard: fact_order_items must have exactly the same number of rows as
-- staging order items. If a dimension or the payments/reviews join fanned out,
-- this count diverges (and every SUM in the project would be inflated).
with fact_count as (
    select count(*) as n from {{ ref('fact_order_items') }}
),

source_count as (
    select count(*) as n from {{ ref('stg_order_items') }}
)

select f.n as fact_rows, s.n as source_rows
from fact_count f
cross join source_count s
where f.n <> s.n
