# Snowflake setup

The project runs end-to-end on the local **DuckDB** target with zero
credentials. This guide switches it to **Snowflake** (the production target).

Nothing here is verified against a live account yet — where a step needs your
input it is called out. Report back after step 2 and the rest is automated.

---

## 1. Get a Snowflake account  *(you)*

A **30-day free trial** is enough: <https://signup.snowflake.com/> →
choose *Standard* edition, any cloud/region. After signup note:

- **Account identifier** — in the URL `https://app.snowflake.com/<org>/<account>/...`
  it is `<org>-<account>`; for the connector use the form
  `<account_locator>.<region>.<cloud>` (Snowsight → *Admin → Accounts* shows it,
  or *… → Connect a tool to Snowflake*).
- The **username / password** you set.

## 2. Put credentials in `.env`  *(you)*

```bash
cp .env.example .env
```

Fill in:

```
DBT_TARGET=snowflake
SNOWFLAKE_ACCOUNT=ab12345.eu-west-2.aws      # your value
SNOWFLAKE_USER=...                            # your value
SNOWFLAKE_PASSWORD=...                        # your value
SNOWFLAKE_ROLE=RETAIL_AE_ROLE
SNOWFLAKE_WAREHOUSE=RETAIL_WH
SNOWFLAKE_DATABASE=RETAIL
SNOWFLAKE_RAW_SCHEMA=RAW
SNOWFLAKE_ANALYTICS_SCHEMA=ANALYTICS
```

`.env` is git-ignored. **Tell me when this is done.**

## 3. Create the objects  *(automated — `make`)*

```bash
make DBT_TARGET=snowflake load
```

This runs, as your user:

1. `scripts/snowflake/01_setup.sql` — `RETAIL_WH` (XSMALL, auto-suspend 60s),
   `RETAIL` database, `RAW` + `ANALYTICS` schemas, `RETAIL_AE_ROLE` + grants.
2. `scripts/snowflake/02_raw_ddl.sql` — the 9 raw tables.
3. `scripts/snowflake/03_file_format_stage.sql` — `OLIST_CSV` format + `RAW_STAGE`.
4. `PUT` each local CSV to the stage, `COPY INTO` the raw tables.
5. Row-count validation (same check as the DuckDB path).

> If your trial user cannot create a role/warehouse, run `01_setup.sql` once in a
> Snowsight worksheet as `ACCOUNTADMIN`, then re-run `make … load`.

## 4. Build + test on Snowflake  *(automated)*

```bash
make DBT_TARGET=snowflake debug
make DBT_TARGET=snowflake build
make DBT_TARGET=snowflake docs
```

## 5. What lands where

| Object | Location |
|---|---|
| Raw tables | `RETAIL.RAW.*` |
| Staging views | `RETAIL.ANALYTICS_STAGING.*` |
| Dimensions + fact | `RETAIL.ANALYTICS_MARTS.*` |
| Metric views | `RETAIL.ANALYTICS_METRICS.*` |

## Cost

XSMALL warehouse, auto-suspend 60s, full build in seconds → a full
load+build+test cycle is well under one credit. The trial includes $400 of
credits.
