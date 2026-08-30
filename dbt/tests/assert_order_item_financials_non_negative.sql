-- Business rule: a line item can never have a negative price or freight, and
-- the total must equal price + freight. A failure means a load/cast bug or a
-- corrupt source row — either way revenue would be wrong.
select
    order_item_key,
    item_price,
    freight_value,
    item_total_value
from {{ ref('fact_order_items') }}
where item_price < 0
   or freight_value < 0
   or abs(item_total_value - (item_price + freight_value)) > 0.01
