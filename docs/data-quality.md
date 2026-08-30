# Data quality

All figures below are produced by
[`analysis/run_eda.py`](../analysis/run_eda.py) against the built DuckDB
warehouse (Olist snapshot, orders Sep 2016 – Oct 2018) and are re-checked by dbt
tests on every `dbt build`.

## Test suite result (latest local run, DuckDB target)

```
dbt build  →  PASS=143  WARN=1  ERROR=0  SKIP=0   (144 tests)
```

- **124 generic tests** — `not_null`, `unique`, `relationships`,
  `accepted_values`, `accepted_range`, `unique_combination_of_columns`.
- **6 singular business-rule tests** — see `dbt/tests/`.
- **1 warning**, described below. It is a real, documented property of the
  public dataset, not a pipeline defect, so it is `severity: warn`.

## Known data issues

| # | Issue | Count | Handling |
|---|---|---:|---|
| 1 | Orders with `order_status = 'delivered'` but no `order_delivered_customer_date` | **8** | `assert_delivered_orders_have_delivery_date` → **warn**. Excluded from delivery-time / on-time KPIs (the metric SQL filters on a non-null delivery date). |
| 2 | Orders present in `orders` with no rows in `order_items` | **775** | Expected — these are almost all `canceled` / `unavailable` / `created`. `fact_order_items` is an inner join to items, so they carry no revenue. `fct_orders` (built from the fact) therefore has 98,666 orders vs 99,441 raw. |
| 3 | `order_reviews.review_id` is not unique | ~800 dupes | Reviews de-duped to one row per order in `int_order_reviews` (latest `review_creation_date` wins) before joining the fact — prevents fanout. |
| 4 | `geolocation` lat/long points outside Brazil's bounding box | ~55 rows | Filtered in `stg_geolocation` (`lat between -34 and 6`, `lng between -74 and -33`). |
| 5 | One order purchased 2016-12-23, next activity months later; a few 2016-09/10 orders | handful | Left as-is — genuine early-pilot orders. `dim_date` spans 2016-2019 so they key correctly. |
| 6 | `payment_value` totals can differ from item + freight (installment interest, vouchers) | many | Expected. `allocated_payment_value` is a proportional split for analysis only; `assert_payment_allocation_ties_to_order` allows 1 cent rounding per line. |
| 7 | ~610 products have null category / dimensions | 610 | `product_category` coalesced to `'unknown'` in `stg_products`; null physical dims flow through as null (weight_band = `'unknown'`). |

## Integrity checks that pass

- **Fact grain:** 112,650 rows = 112,650 distinct `order_item_key` = `count(stg_order_items)`. No fanout (`assert_fact_not_fanned_out`).
- **Cross-grain revenue:** `SUM(fact_order_items.item_price)` = `SUM(fct_orders.product_revenue)` = **13,591,643.70 BRL** to the cent (`assert_revenue_reconciles_across_grains`).
- **Foreign keys:** 0 null `customer_key` / `product_key` / `seller_key` / `date_key` in the fact; all `relationships` tests pass.
- **Financials:** 0 non-positive `item_price`, 0 negative `freight_value` (`assert_order_item_financials_non_negative`).
- **Time logic:** 0 orders delivered before purchase (`assert_delivery_not_before_purchase`).
