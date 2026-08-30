# Data

This project uses the **Brazilian E-Commerce Public Dataset by Olist**.

- Source: <https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce>
- Licence: **CC BY-NC-SA 4.0** — free for non-commercial use with attribution.
- ~100k orders placed on Olist between **September 2016 and October 2018**.

## The raw data is deliberately NOT committed

`data/raw/` is git-ignored. The dataset is ~120 MB unzipped and is not ours to
redistribute. Every contributor pulls it themselves — see
[`../DATA_SETUP.md`](../DATA_SETUP.md).

## Expected files

After setup, `data/raw/` must contain these 9 CSVs:

| File | Grain | Approx rows |
|---|---|---|
| `olist_orders_dataset.csv` | one row per order | 99,441 |
| `olist_order_items_dataset.csv` | one row per order line item | 112,650 |
| `olist_order_payments_dataset.csv` | one row per payment on an order | 103,886 |
| `olist_order_reviews_dataset.csv` | one row per review | 99,224 |
| `olist_customers_dataset.csv` | one row per customer-order identity | 99,441 |
| `olist_products_dataset.csv` | one row per product | 32,951 |
| `olist_sellers_dataset.csv` | one row per seller | 3,095 |
| `olist_geolocation_dataset.csv` | one row per zip-code prefix / lat-long | 1,000,163 |
| `product_category_name_translation.csv` | category PT → EN lookup | 71 |

Row counts above are the published figures for the dataset and are re-checked
by `scripts/load_raw.py` after loading (it fails loudly on a zero-row table).

## Note on `olist_customers_dataset`

Olist issues a **new `customer_id` for every order** and keeps a stable
`customer_unique_id` across a shopper's orders. `dim_customers` is built at the
`customer_unique_id` grain — see [`../docs/data-model.md`](../docs/data-model.md).
