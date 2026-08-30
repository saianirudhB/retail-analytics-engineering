# Data dictionary

Analytics-layer models only (schemas `analytics_staging`, `analytics_marts`,
`analytics_metrics`). Raw column definitions are in
[`scripts/snowflake/02_raw_ddl.sql`](../scripts/snowflake/02_raw_ddl.sql).
This file is also generated as browsable HTML by `dbt docs generate`.

Currency: **BRL**. Timestamps: local, no timezone (as published).

---

## marts · `fact_order_items`  — grain: one row per order line item

| Column | Type | Description |
|---|---|---|
| `order_item_key` | varchar | **PK.** `hash(order_id, order_item_id)`. |
| `order_id` | varchar | Degenerate dimension — natural order id. |
| `order_item_number` | int | 1..n sequence within the order; also encodes quantity. |
| `order_status` | varchar | Order lifecycle status (degenerate). |
| `customer_key` | varchar | FK → `dim_customers`. |
| `product_key` | varchar | FK → `dim_products`. |
| `seller_key` | varchar | FK → `dim_sellers`. |
| `order_purchased_date_key` | int | FK → `dim_date` (YYYYMMDD). Purchase date. |
| `order_approved_date_key` | int | FK → `dim_date`. Payment-approval date (nullable). |
| `order_delivered_date_key` | int | FK → `dim_date`. Customer-delivery date (nullable). |
| `order_estimated_delivery_date_key` | int | FK → `dim_date`. Promised delivery date. |
| `purchased_at` | timestamp | Purchase timestamp (degenerate). |
| `delivered_to_customer_at` | timestamp | Delivery timestamp (nullable). |
| `estimated_delivery_at` | timestamp | Promised delivery timestamp. |
| `item_quantity` | int | Always 1. `SUM` = items sold. **Additive.** |
| `item_price` | numeric | Item price excl. freight. **Additive.** |
| `freight_value` | numeric | Freight charged for this item. **Additive.** |
| `item_total_value` | numeric | `item_price + freight_value`. **Additive.** |
| `allocated_payment_value` | numeric | Order paid amount split to this line by value share. **Additive.** |
| `primary_payment_type` | varchar | Order's dominant payment type (order-level). |
| `max_installments` | int | Max instalments on the order (order-level). |
| `review_score` | int | 1–5; one review per order (order-level — do not sum). |
| `delivery_days` | int | Purchase → delivery, days (order-level). |
| `estimated_delivery_days` | int | Purchase → promised date, days (order-level). |
| `delivery_delay_days` | int | Promised → actual, days; negative = early (order-level). |
| `is_delivered` | boolean | `order_status = 'delivered'`. |
| `is_canceled` | boolean | `order_status = 'canceled'`. |
| `is_on_time` | boolean | Delivered on/before promised date; null if not delivered. |
| `is_first_item_in_order` | boolean | True on exactly one line per order — filter for order-level measures. |

## marts · `dim_customers` — grain: `customer_unique_id`

| Column | Type | Description |
|---|---|---|
| `customer_key` | varchar | **PK.** `hash(customer_unique_id)`. |
| `customer_unique_id` | varchar | Stable shopper business key. |
| `customer_city` | varchar | City of most recent order (lower-case, as source). |
| `customer_state` | varchar | Two-letter state code (UF). |
| `customer_region` | varchar | IBGE macro-region (North / Northeast / Central-West / Southeast / South). |
| `customer_zip_code_prefix` | varchar | 5-digit zip prefix of most recent order. |
| `customer_latitude` / `customer_longitude` | double | Centroid of the zip prefix (nullable). |
| `first_order_at` / `most_recent_order_at` | timestamp | Lifecycle bounds. |
| `first_order_date` | date | Cohort date. |
| `lifetime_order_count` | int | Orders placed by this shopper. |
| `distinct_customer_ids` | int | Number of per-order `customer_id`s (≈ order count). |
| `is_repeat_customer` | boolean | `lifetime_order_count > 1`. |

## marts · `dim_products` — grain: `product_id`

| Column | Type | Description |
|---|---|---|
| `product_key` | varchar | **PK.** `hash(product_id)`. |
| `product_id` | varchar | Business key. |
| `product_category` | varchar | English category; `'unknown'` if missing. |
| `product_category_name_pt` | varchar | Original Portuguese category. |
| `product_weight_g` | int | Weight in grams (nullable). |
| `product_length_cm` / `product_height_cm` / `product_width_cm` | int | Dimensions (nullable). |
| `product_volume_litres` | numeric | `l·h·w / 1000` (nullable). |
| `product_photos_qty` | int | Listing photo count. |
| `product_name_length` / `product_description_length` | int | Listing text lengths. |
| `weight_band` | varchar | light / medium / heavy / bulky / unknown. |

## marts · `dim_sellers` — grain: `seller_id`

| Column | Type | Description |
|---|---|---|
| `seller_key` | varchar | **PK.** `hash(seller_id)`. |
| `seller_id` | varchar | Business key. |
| `seller_city` | varchar | Lower-case, as source. |
| `seller_state` | varchar | Two-letter state code. |
| `seller_region` | varchar | IBGE macro-region. |
| `seller_zip_code_prefix` | varchar | 5-digit zip prefix. |
| `seller_latitude` / `seller_longitude` | double | Zip-prefix centroid (nullable). |

## marts · `dim_date` — grain: one calendar day

| Column | Type | Description |
|---|---|---|
| `date_key` | int | **PK.** YYYYMMDD. |
| `date` | date | The day. |
| `year`, `quarter`, `month`, `week_of_year`, `day_of_month` | int | Calendar parts. |
| `quarter_name` | varchar | `Q1`…`Q4`. |
| `year_month` | int | YYYYMM. |
| `month_name`, `day_name` | varchar | Full names. |
| `day_of_week` | int | 0 = Sunday … 6 = Saturday. |
| `is_weekend` | boolean | Saturday/Sunday. |
| `is_first_day_of_month` | boolean | Month-start flag. |

---

## metrics layer (views)

| Model | Grain | Key columns |
|---|---|---|
| `fct_orders` | one row per order | `order_id`, `product_revenue`, `freight_revenue`, `gross_merchandise_value`, `recognised_product_revenue`, `is_revenue_order`, `delivery_days`, `review_score`, `is_on_time` |
| `metrics_orders_daily` | purchase date | `orders`, `revenue_orders`, `product_revenue`, `items_sold`, `avg_order_value`, `cancellation_rate` |
| `metrics_category_performance` | product category | `orders`, `items_sold`, `product_revenue`, `revenue_per_order`, `avg_review_score` |
| `metrics_seller_performance` | seller | `orders`, `product_revenue`, `revenue_per_order`, `avg_delivery_days`, `on_time_delivery_rate`, `avg_review_score` |
| `metrics_delivery_performance` | purchase month | `orders`, `delivered_orders`, `avg_delivery_days`, `avg_promised_days`, `avg_delay_days`, `on_time_delivery_rate`, `late_orders` |
| `metrics_customer_rfm` | customer | `recency_days`, `frequency`, `monetary`, `avg_order_value`, `customer_segment` |
| `metrics_executive_summary` | single row | headline totals + averages for the dashboard header |
