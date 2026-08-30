# snapshots/

Empty on purpose. The Olist dataset is a **static historical extract**, so there
is no changing source to snapshot and adding a snapshot now would only capture a
single unchanging state.

This folder marks where **Type-2 slowly-changing-dimension** history would go if
this pipeline were fed by a live system. The two candidates
(from [`../../docs/data-model.md`](../../docs/data-model.md)):

- **`dim_customers` location** — a shopper's city/state/zip can change between
  orders; today we keep the most-recent value (Type 1).
- **`dim_products` category** — sellers re-categorise listings.

Planned implementation:

```sql
-- snapshots/scd_customer_location.sql
{% snapshot scd_customer_location %}
{{ config(
    target_schema='snapshots',
    unique_key='customer_unique_id',
    strategy='check',
    check_cols=['customer_city', 'customer_state', 'customer_zip_code_prefix']
) }}
select customer_unique_id, customer_city, customer_state, customer_zip_code_prefix
from {{ ref('stg_customers') }}
{% endsnapshot %}
```

`fact_order_items` would then join on the snapshot valid for
`purchased_at` (`dbt_valid_from` / `dbt_valid_to`) instead of the current-value
dimension.
