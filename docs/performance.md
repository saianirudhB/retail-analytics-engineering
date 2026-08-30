# Performance & optimisation decisions

The dataset is small (112k line items, ~1M geolocation rows) so absolute
runtimes are tiny on both targets. The decisions below are about **shape** —
the choices that keep the project cheap and fast as data grows, and that would
matter on a real Snowflake bill.

## Materialisation strategy

| Layer | Materialisation | Reasoning |
|---|---|---|
| `staging` | **view** | Thin renames/casts over raw. Materialising would double storage and add a refresh step for zero query benefit — the warehouse inlines the view. |
| `intermediate` | **ephemeral** | `int_order_reviews`, `int_payments_by_order` exist for readability. Compiled directly into `fact_order_items` as CTEs — no object created, no extra scan. |
| `marts/core` (`dim_*`, `fact_order_items`) | **table** | Queried repeatedly by BI and by the metrics layer. Pay the build cost once, read many times. On Snowflake these get natural micro-partition pruning on the date keys. |
| `marts/metrics` | **view** | Cheap aggregations over already-materialised tables. Views keep them always-fresh and free to store. If a metrics query became a dashboard bottleneck the fix is a one-line `+materialized: table` override. |

## Specific optimisations made

1. **Collapsed `geolocation` early.** Raw geolocation is ~1M rows (many points
   per zip prefix). `stg_geolocation` reduces it to one row per prefix (~19k)
   with a centroid. Downstream joins to customers/sellers are then 1:1 instead
   of many-to-many — this is the single biggest fanout risk in the source and
   it is removed before any mart touches it.

2. **Pre-aggregated payments and reviews to order grain** in ephemeral models
   before joining the fact. Joining raw `order_payments` (103k rows, multiple
   per order) directly onto line items would multiply revenue. Aggregating
   first keeps every fact join many-to-one.

3. **Allocated payment once, in the fact.** `allocated_payment_value` is
   computed with a single window-free aggregate (`order_item_totals` CTE) and a
   division — not a correlated subquery per row.

4. **Surrogate keys via `dbt_utils.generate_surrogate_key`** (hash) rather than
   window-numbered sequences, so dimension builds are non-blocking and parallel.

5. **`dim_date` generated, not queried.** `dbt_utils.date_spine` builds 1,460
   rows with no source scan; every date FK in the fact is a precomputed
   `YYYYMMDD` integer, so time-series joins are integer equality (partition- and
   join-friendly on Snowflake).

6. **Portable date math via dbt macros** (`dbt.datediff`, `date_to_key`) instead
   of engine-specific functions — avoids per-row UDF-style calls and compiles to
   native operators on each warehouse.

## Snowflake-specific notes (for when the Snowflake target is run)

- Warehouse is `XSMALL` with `AUTO_SUSPEND = 60s` — the marts build in seconds;
  no reason to hold a warehouse open.
- `dim_date.date_key` and `fact_order_items.order_purchased_date_key` give the
  optimiser a clustering-friendly column without an explicit `CLUSTER BY`
  (unnecessary at this size; documented as the first lever if the fact grew
  100×).
- `query-comment` is enabled in `dbt_project.yml`, so every model's SQL is
  tagged in `SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY` for cost attribution.

## Incremental models — deliberately not used

`fact_order_items` is a full rebuild. An incremental model is only worth its
complexity when a full refresh is slow or expensive; here it takes ~0.6s. The
code is structured so that switching `fact_order_items` to
`materialized='incremental'` with `unique_key='order_item_key'` and an
`is_incremental()` filter on `purchased_at` would be a localised change — noted
here rather than implemented for a buzzword.

## Measured build (DuckDB target, local)

```
dbt run   → 20 models   ~1.3s
dbt build → 20 models + 124 tests   ~2.2s
```

Snowflake before/after numbers are **NOT VERIFIED** — no Snowflake account is
connected yet. `docs/performance.md` will be updated with real
`QUERY_HISTORY` timings once it is.
