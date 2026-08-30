# Dimensional data model

## Star schema

```mermaid
erDiagram
    dim_customers ||--o{ fact_order_items : "customer_key"
    dim_products  ||--o{ fact_order_items : "product_key"
    dim_sellers   ||--o{ fact_order_items : "seller_key"
    dim_date      ||--o{ fact_order_items : "order_purchased_date_key"
    dim_date      ||--o{ fact_order_items : "order_delivered_date_key"
    dim_date      ||--o{ fact_order_items : "order_estimated_delivery_date_key"

    fact_order_items {
        varchar  order_item_key PK
        varchar  order_id "degenerate"
        int      order_item_number "degenerate"
        varchar  order_status "degenerate"
        varchar  customer_key FK
        varchar  product_key FK
        varchar  seller_key FK
        int      order_purchased_date_key FK
        int      order_delivered_date_key FK
        int      order_estimated_delivery_date_key FK
        numeric  item_price "additive"
        numeric  freight_value "additive"
        numeric  item_total_value "additive"
        int      item_quantity "additive"
        numeric  allocated_payment_value "additive"
        int      delivery_days "order-level"
        int      delivery_delay_days "order-level"
        int      review_score "order-level"
        boolean  is_delivered
        boolean  is_on_time
        boolean  is_first_item_in_order
    }

    dim_customers {
        varchar customer_key PK
        varchar customer_unique_id "business key"
        varchar customer_state
        varchar customer_region
        date    first_order_date
        int     lifetime_order_count
        boolean is_repeat_customer
    }
    dim_products {
        varchar product_key PK
        varchar product_id "business key"
        varchar product_category
        numeric product_volume_litres
        varchar weight_band
    }
    dim_sellers {
        varchar seller_key PK
        varchar seller_id "business key"
        varchar seller_state
        varchar seller_region
    }
    dim_date {
        int  date_key PK
        date date
        int  year
        int  quarter
        int  month
        varchar month_name
        int  day_of_week
        boolean is_weekend
    }
```

## Fact grain

**`fact_order_items` = one row per order line item**, keyed by
`order_item_key = hash(order_id, order_item_id)`.

`order_item_id` in the source runs `1..n` within an order and also encodes
quantity: two units of the same product on one order appear as two rows
(`order_item_number` 1 and 2). So `count(*)` = items sold and
`sum(item_price)` = product revenue, both at line grain.

### Measure additivity

| Measure | Additive across… | Notes |
|---|---|---|
| `item_price`, `freight_value`, `item_total_value` | any dimension | core revenue measures |
| `item_quantity` (always 1) | any dimension | `sum` = items sold |
| `allocated_payment_value` | any dimension | order paid amount split across its lines by value share; ties back to the order within rounding |
| `delivery_days`, `estimated_delivery_days`, `delivery_delay_days` | **orders only** | identical on every line of an order; `avg` per order — filter `is_first_item_in_order` or aggregate via `fct_orders` |
| `review_score` | **orders only** | one review per order; same caveat |

### Fanout control

Every dimension join from the fact is many-to-one:

- one line → one product, one seller, one order → one customer;
- **payments** are pre-aggregated to order grain in `int_payments_by_order`
  (one row per order) before joining;
- **reviews** are de-duped to one row per order in `int_order_reviews`
  (latest review wins) before joining.

`assert_fact_not_fanned_out` enforces `count(fact) == count(stg_order_items)`
and `assert_revenue_reconciles_across_grains` enforces
`sum(line.item_price) == sum(order.product_revenue)`.

## Dimensions

### dim_customers — grain `customer_unique_id`
Olist issues a fresh `customer_id` per order and keeps `customer_unique_id`
stable per shopper. Building on the stable key is what enables repeat-purchase
analysis. `fact_order_items` links order → `customer_id` → `customer_unique_id`
→ `customer_key`.

### SCD treatment
All dimensions are **Type 1 (current value)**. Customer/seller location can
change between orders; we keep the value from the shopper's/seller's most
recent order. The dataset is a static historical extract, so no snapshot is
maintained. If this were a live feed, `dim_customers` location and
`dim_products` category would be the candidates for Type 2 history — a
`snapshots/` folder is scaffolded for that.

### dim_date — grain one calendar day
Generated with `dbt_utils.date_spine` over the `date_start`/`date_end` vars.
Supplies year, quarter, month (+ name), week, day, day-of-week, weekend flag.
