# dbt lineage

Browsable version: `make docs` then `docker compose run --rm --service-ports dbt dbt docs serve --host 0.0.0.0`
→ <http://localhost:8080> (the interactive DAG from `dbt docs generate`).

Static overview of the DAG:

```mermaid
flowchart LR
    subgraph raw["source: olist (RAW)"]
        s_orders[[orders]]
        s_items[[order_items]]
        s_pay[[order_payments]]
        s_rev[[order_reviews]]
        s_cust[[customers]]
        s_prod[[products]]
        s_sell[[sellers]]
        s_geo[[geolocation]]
        s_cat[[category_translation]]
    end

    subgraph stg["staging (views)"]
        stg_orders
        stg_order_items
        stg_order_payments
        stg_order_reviews
        stg_customers
        stg_products
        stg_sellers
        stg_geolocation
    end

    subgraph int["intermediate (ephemeral)"]
        int_order_reviews
        int_payments_by_order
    end

    subgraph core["marts / core (tables)"]
        dim_date
        dim_customers
        dim_products
        dim_sellers
        fact_order_items
    end

    subgraph met["marts / metrics (views)"]
        fct_orders
        metrics_orders_daily
        metrics_category_performance
        metrics_seller_performance
        metrics_delivery_performance
        metrics_customer_rfm
        metrics_executive_summary
    end

    s_orders --> stg_orders
    s_items --> stg_order_items
    s_pay --> stg_order_payments
    s_rev --> stg_order_reviews
    s_cust --> stg_customers
    s_prod --> stg_products
    s_cat --> stg_products
    s_sell --> stg_sellers
    s_geo --> stg_geolocation

    stg_order_reviews --> int_order_reviews
    stg_order_payments --> int_payments_by_order

    stg_customers --> dim_customers
    stg_orders --> dim_customers
    stg_geolocation --> dim_customers
    stg_products --> dim_products
    stg_sellers --> dim_sellers
    stg_geolocation --> dim_sellers

    stg_order_items --> fact_order_items
    stg_orders --> fact_order_items
    stg_customers --> fact_order_items
    dim_customers --> fact_order_items
    dim_products --> fact_order_items
    dim_sellers --> fact_order_items
    int_order_reviews --> fact_order_items
    int_payments_by_order --> fact_order_items

    fact_order_items --> fct_orders
    dim_date --> metrics_delivery_performance
    fct_orders --> metrics_orders_daily
    fct_orders --> metrics_delivery_performance
    fct_orders --> metrics_customer_rfm
    fct_orders --> metrics_executive_summary
    fact_order_items --> metrics_category_performance
    fact_order_items --> metrics_seller_performance
    fact_order_items --> metrics_executive_summary
    dim_products --> metrics_category_performance
    dim_sellers --> metrics_seller_performance
    dim_customers --> metrics_customer_rfm
```
