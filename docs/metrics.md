# Metrics / KPI definitions

Every metric below is implemented once in the `metrics` layer and should not be
re-derived in BI. The canonical grain for order/revenue metrics is
[`fct_orders`](../dbt/models/marts/metrics/fct_orders.sql).

## Conventions

- **Currency:** all monetary values are in Brazilian Real (BRL), as published.
- **Revenue orders:** an order counts toward revenue when
  `order_status ∈ {delivered, shipped, invoiced}` (dbt var
  `revenue_order_statuses`). `canceled`, `unavailable`, `created`, `approved`,
  `processing` are excluded — the goods were not (or not yet) dispatched.
- **Dates:** metrics are bucketed by **order purchase date** unless stated.
- **Recency:** measured against the last purchase date in the dataset
  (2018-10), not the current date — the data is a fixed historical extract.

## Core metrics

| Metric | Definition | Model |
|---|---|---|
| **Orders** | distinct count of `order_id` | `metrics_orders_daily.orders` |
| **Revenue orders** | orders in a revenue status | `…revenue_orders` |
| **Product revenue** | `SUM(item_price)` over revenue orders (excludes freight) | `…product_revenue` |
| **Freight revenue** | `SUM(freight_value)` over revenue orders | `…freight_revenue` |
| **GMV** | product revenue + freight revenue | `…gross_merchandise_value` |
| **Items sold** | `SUM(item_quantity)` (one per line item) | `…items_sold` |
| **Average Order Value (AOV)** | product revenue ÷ revenue orders | `…avg_order_value` |
| **Cancellation rate** | canceled orders ÷ all orders | `…cancellation_rate` |

## Delivery / operations

| Metric | Definition | Model |
|---|---|---|
| **Delivery time (days)** | `delivered_to_customer_at − purchased_at` in days, delivered orders only | `metrics_delivery_performance.avg_delivery_days` |
| **Promised time (days)** | `estimated_delivery_at − purchased_at` | `…avg_promised_days` |
| **Delivery delay (days)** | `delivered_to_customer_at − estimated_delivery_at` (negative = early) | `…avg_delay_days` |
| **On-time delivery %** | share of delivered orders with `delivered_to_customer_at ≤ estimated_delivery_at` | `…on_time_delivery_rate` |
| **Late orders** | delivered orders with delay > 0 days | `…late_orders` |

## Category / seller

| Metric | Definition | Model |
|---|---|---|
| **Revenue by category** | `SUM(item_price)` over revenue lines, grouped by `dim_products.product_category` | `metrics_category_performance` |
| **Revenue per order (category)** | category product revenue ÷ distinct orders containing the category | `…revenue_per_order` |
| **Seller revenue** | `SUM(item_price)` over revenue lines the seller fulfilled | `metrics_seller_performance.product_revenue` |
| **Seller on-time %** | on-time rate across the seller's delivered lines | `…on_time_delivery_rate` |
| **Avg review score** | mean `review_score` (order-level, de-duped) attributed to the category/seller | `…avg_review_score` |

## Customer

| Metric | Definition | Model |
|---|---|---|
| **Frequency** | lifetime count of orders per `customer_unique_id` | `metrics_customer_rfm.frequency` |
| **Monetary** | lifetime recognised product revenue | `…monetary` |
| **Recency (days)** | days from the customer's last order to the dataset's last order date | `…recency_days` |
| **Repeat customer** | `lifetime_order_count > 1` | `dim_customers.is_repeat_customer` |
| **Segment** | loyal (≥3 orders) / returning (2) / recent one-time (≤90d) / lapsed one-time | `…customer_segment` |

## Assumptions & caveats

- Olist provides **no quantity column**; quantity is inferred from repeated
  `order_item_id` rows. This matches how the dataset is documented.
- A small number of `delivered` orders have a null delivery timestamp — they
  are excluded from delivery-time metrics (see [data-quality.md](data-quality.md)).
- `payment_value` can exceed item + freight totals (installment interest,
  vouchers); `allocated_payment_value` is a proportional split for analysis, not
  an accounting figure.
- Review score is attributed to **every** line/category/seller in the order —
  reviews are not line-specific in the source.
