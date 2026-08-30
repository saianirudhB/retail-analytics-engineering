# scripts/

| Script | What it does |
|---|---|
| `download_data.sh` | Pull the Olist dataset from Kaggle into `data/raw/` (needs `~/.kaggle/kaggle.json` or `KAGGLE_*` env). |
| `load_raw.py` | Load `data/raw/*.csv` into the warehouse **RAW** schema. `--target duckdb` (default) or `--target snowflake`. Validates row counts and exits non-zero on any problem. |
| `snowflake/01_setup.sql` | Warehouse, database, `RAW` + `ANALYTICS` schemas, project role and grants. |
| `snowflake/02_raw_ddl.sql` | `RAW` table definitions (column names verbatim from the CSVs). |
| `snowflake/03_file_format_stage.sql` | `OLIST_CSV` file format + `RAW_STAGE` internal stage. |
| `snowflake/04_copy_into.sql` | Reference `COPY INTO` statements (the Python loader runs the equivalent). |
| `snowflake/05_validate.sql` | Row-count + integrity spot checks to run in a worksheet. |

## Typical order

```bash
make data                       # download  (once)
make load                       # -> DuckDB RAW  (local, no credentials)
make DBT_TARGET=snowflake load  # -> Snowflake RAW  (after SNOWFLAKE_SETUP.md)
```

`load_raw.py` on the Snowflake target runs `01`–`03`, then `PUT` + `COPY INTO`
for every table, then the validation query. `04`/`05` are the hand-run equivalents.
