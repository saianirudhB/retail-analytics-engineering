# BI dashboard — specification & build guide

**Tool:** Power BI Desktop (Windows). This repo is developed on macOS, where
Power BI Desktop does not run, so the dashboard is delivered as a **BI-ready
model + full specification + connection guide**. Screenshots go in
`screenshots/` once built on Windows.

The metrics layer is designed so Power BI needs **no DAX beyond trivial
formatting** — every KPI is already computed in dbt.

---

## 1. Connect Power BI to the warehouse

### Snowflake (production)
`Home → Get Data → Snowflake`

| Field | Value |
|---|---|
| Server | `<account>.snowflakecomputing.com` |
| Warehouse | `RETAIL_WH` |
| Database | `RETAIL` |
| Role | `RETAIL_AE_ROLE` (set in *Advanced options*) |
| Connectivity mode | **Import** (dataset is small) |

Load these tables/views from the `ANALYTICS_*` schemas:

- `analytics_marts.fact_order_items`
- `analytics_marts.dim_customers`, `dim_products`, `dim_sellers`, `dim_date`
- `analytics_metrics.metrics_executive_summary`
- `analytics_metrics.metrics_orders_daily`
- `analytics_metrics.metrics_category_performance`
- `analytics_metrics.metrics_seller_performance`
- `analytics_metrics.metrics_delivery_performance`
- `analytics_metrics.metrics_customer_rfm`

### Local (DuckDB, for building offline)
Install the **DuckDB ODBC driver**, point it at `dbt/retail.duckdb`, connect via
`Get Data → ODBC`. Same table list (schemas are lower-case: `analytics_marts`,
`analytics_metrics`).

---

## 2. Data model in Power BI

Star schema — mark `dim_date` as the date table (`date` column).

```
dim_customers  1 ──*  fact_order_items  *── 1  dim_products
dim_sellers    1 ──*  fact_order_items
dim_date       1 ──*  fact_order_items   (on order_purchased_date_key = date_key,
                                          single direction, active)
```

Inactive extra relationships `dim_date → fact_order_items` on
`order_delivered_date_key` and `order_estimated_delivery_date_key` (use
`USERELATIONSHIP` in a measure only if a "by delivery date" view is needed).

The `metrics_*` views are **stand-alone report tables** (not related to the
star) — each page binds to one of them directly. `metrics_customer_rfm` relates
to `dim_customers` on `customer_key` if a combined view is wanted.

### The only measures you need

```DAX
Product Revenue      = SUM ( fact_order_items[item_price] )
Freight Revenue      = SUM ( fact_order_items[freight_value] )
Items Sold           = SUM ( fact_order_items[item_quantity] )
Orders               = DISTINCTCOUNT ( fact_order_items[order_id] )
Avg Order Value      = DIVIDE ( [Product Revenue], [Orders] )
On-Time Delivery %   = AVERAGE ( metrics_delivery_performance[on_time_delivery_rate] )
```

(Revenue-status filtering is already baked into the metrics views; on
`fact_order_items` add a visual-level filter `order_status in {delivered,
shipped, invoiced}` if measuring off the fact directly.)

---

## 3. Pages

### Page 1 — Executive Overview
| Visual | Field(s) | Source |
|---|---|---|
| KPI cards ×6 | Product revenue, Orders, AOV, Items sold, On-time %, Avg review score | `metrics_executive_summary` |
| Line chart | `product_revenue` by `year_month` | `metrics_orders_daily` (+ `dim_date`) |
| Line chart | `orders` by `year_month` | `metrics_orders_daily` |
| Card + sparkline | Cancellation rate trend | `metrics_orders_daily` |
| Slicer | `dim_date[year]`, `dim_customers[customer_region]` | — |

### Page 2 — Product Performance
| Visual | Field(s) | Source |
|---|---|---|
| Bar (Top 15) | `product_revenue` by `product_category` | `metrics_category_performance` |
| Scatter | x = `product_revenue`, y = `avg_review_score`, size = `items_sold` | `metrics_category_performance` |
| Table | category, orders, items, revenue, revenue_per_order, avg_review_score | `metrics_category_performance` |
| Bar | `freight_pct_of_product_rev` by category (calc: `freight_revenue / product_revenue`) | `metrics_category_performance` |

### Page 3 — Operations / Delivery
| Visual | Field(s) | Source |
|---|---|---|
| Line (dual axis) | `avg_delivery_days` & `on_time_delivery_rate` by `year_month` | `metrics_delivery_performance` |
| Column | `late_orders` by `year_month` | `metrics_delivery_performance` |
| Column | avg review score by on-time vs late (from `fct_orders`, needs import of `fct_orders`) | `analytics_metrics.fct_orders` |
| Map | orders / on-time % by `customer_state` | `fact_order_items` + `dim_customers` |
| KPI cards | Avg delivery days, On-time %, Avg delay days | `metrics_executive_summary` |

### Page 4 — Seller Performance
| Visual | Field(s) | Source |
|---|---|---|
| Table (sortable) | seller_id, state, orders, product_revenue, revenue_per_order, on_time_delivery_rate, avg_review_score | `metrics_seller_performance` |
| Pareto (line+column) | cumulative % revenue by seller rank | `metrics_seller_performance` |
| Bar | avg `on_time_delivery_rate` by `seller_region` | `metrics_seller_performance` |
| Scatter | x = revenue, y = avg_review_score, size = orders | `metrics_seller_performance` |

### Page 5 — Customers (optional)
| Visual | Field(s) | Source |
|---|---|---|
| Donut | customers by `customer_segment` | `metrics_customer_rfm` |
| Column | revenue by `customer_region` | `fct_orders` + `dim_customers` |
| Card | Repeat-customer % | `dim_customers[is_repeat_customer]` |

---

## 4. Formatting

- Currency: BRL, no decimals on cards, thousands separator.
- Rates: percentage, 1 decimal.
- Theme: neutral; one accent colour for revenue, one for operations.
- Every page: `dim_date[year]` slicer + last-refresh text box.

## 5. Deliverables checklist

- [ ] `retail_analytics.pbix` committed (or in Releases if >50 MB)
- [ ] `screenshots/01_executive.png` … `05_customers.png`
- [ ] Data source set to **Import**, scheduled refresh documented
