#!/usr/bin/env python3
"""
Load the raw Olist CSVs into the warehouse RAW schema.

    python scripts/load_raw.py --target duckdb      # local, default
    python scripts/load_raw.py --target snowflake   # cloud

DuckDB path:   creates schema RAW and one table per CSV via read_csv (types inferred;
               the raw layer stays faithful to the source, casting happens in staging).
Snowflake path: runs scripts/snowflake/*.sql for DDL + file format + stage, PUTs the
               local CSVs to the stage, COPY INTO each table, then validates.

Both paths finish with a row-count check against EXPECTED_ROWS and exit non-zero
on any missing file or zero-row table. Nothing is reported as "loaded" unless the
count check passes.
"""
from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = ROOT / "data" / "raw"

# file stem (no .csv)  ->  (raw table name, published row count)
TABLES: dict[str, tuple[str, int]] = {
    "olist_orders_dataset":                 ("orders", 99_441),
    "olist_order_items_dataset":            ("order_items", 112_650),
    "olist_order_payments_dataset":         ("order_payments", 103_886),
    "olist_order_reviews_dataset":          ("order_reviews", 99_224),
    "olist_customers_dataset":              ("customers", 99_441),
    "olist_products_dataset":               ("products", 32_951),
    "olist_sellers_dataset":                ("sellers", 3_095),
    "olist_geolocation_dataset":            ("geolocation", 1_000_163),
    "product_category_name_translation":    ("product_category_name_translation", 71),
}

# Allow small drift vs the published figures (Kaggle has re-published minor fixes).
TOLERANCE = 0.02


def _load_dotenv() -> None:
    env = ROOT / ".env"
    if not env.exists():
        return
    for line in env.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        os.environ.setdefault(k.strip(), v.strip())


def _check_files() -> list[Path]:
    missing = [f"{stem}.csv" for stem in TABLES if not (RAW_DIR / f"{stem}.csv").exists()]
    if missing:
        sys.exit(
            "Missing raw files in data/raw/:\n  - "
            + "\n  - ".join(missing)
            + "\n\nRun `make data` or see DATA_SETUP.md."
        )
    return [RAW_DIR / f"{stem}.csv" for stem in TABLES]


def _report(counts: dict[str, int]) -> None:
    print(f"\n{'table':<40}{'rows':>12}{'expected':>12}   status")
    print("-" * 80)
    bad = []
    for stem, (table, expected) in TABLES.items():
        got = counts.get(table, 0)
        ok = got > 0 and abs(got - expected) <= expected * TOLERANCE
        print(f"{table:<40}{got:>12,}{expected:>12,}   {'OK' if ok else 'CHECK'}")
        if not ok:
            bad.append(table)
    if bad:
        sys.exit(f"\n❌ row-count check failed for: {', '.join(bad)}")
    print("\n✅ all raw tables loaded and validated")


# --------------------------------------------------------------------------- #
# DuckDB
# --------------------------------------------------------------------------- #
def load_duckdb() -> None:
    import duckdb

    db_path = os.environ.get("DUCKDB_PATH", str(ROOT / "dbt" / "retail.duckdb"))
    # normalise the container path if we're running on the host
    if db_path.startswith("/workspace/") and not Path("/workspace").exists():
        db_path = str(ROOT / db_path[len("/workspace/"):])
    Path(db_path).parent.mkdir(parents=True, exist_ok=True)
    print(f"DuckDB → {db_path}")

    con = duckdb.connect(db_path)
    con.execute("CREATE SCHEMA IF NOT EXISTS raw")
    counts: dict[str, int] = {}
    for stem, (table, _) in TABLES.items():
        csv = (RAW_DIR / f"{stem}.csv").as_posix()
        con.execute(f"CREATE OR REPLACE TABLE raw.{table} AS "
                    f"SELECT * FROM read_csv(?, header=true, sample_size=-1)", [csv])
        counts[table] = con.execute(f"SELECT count(*) FROM raw.{table}").fetchone()[0]
        print(f"  loaded raw.{table}")
    con.close()
    _report(counts)


# --------------------------------------------------------------------------- #
# Snowflake
# --------------------------------------------------------------------------- #
def load_snowflake() -> None:
    try:
        import snowflake.connector
    except ModuleNotFoundError:
        sys.exit("snowflake-connector-python not installed. `pip install snowflake-connector-python`")

    required = ["SNOWFLAKE_ACCOUNT", "SNOWFLAKE_USER", "SNOWFLAKE_PASSWORD"]
    missing = [v for v in required if not os.environ.get(v)]
    if missing:
        sys.exit("Missing Snowflake env vars: " + ", ".join(missing) + "\nSee .env.example / SNOWFLAKE_SETUP.md")

    db = os.environ.get("SNOWFLAKE_DATABASE", "RETAIL")
    raw_schema = os.environ.get("SNOWFLAKE_RAW_SCHEMA", "RAW")
    wh = os.environ.get("SNOWFLAKE_WAREHOUSE", "RETAIL_WH")
    role = os.environ.get("SNOWFLAKE_ROLE", "RETAIL_AE_ROLE")

    con = snowflake.connector.connect(
        account=os.environ["SNOWFLAKE_ACCOUNT"],
        user=os.environ["SNOWFLAKE_USER"],
        password=os.environ["SNOWFLAKE_PASSWORD"],
        role=role,
        warehouse=wh,
    )
    cur = con.cursor()

    def run_sql_file(name: str) -> None:
        path = ROOT / "scripts" / "snowflake" / name
        print(f"  running {name}")
        sql = path.read_text()
        sql = (sql.replace("{{DATABASE}}", db)
                  .replace("{{RAW_SCHEMA}}", raw_schema)
                  .replace("{{ANALYTICS_SCHEMA}}", os.environ.get("SNOWFLAKE_ANALYTICS_SCHEMA", "ANALYTICS"))
                  .replace("{{WAREHOUSE}}", wh)
                  .replace("{{ROLE}}", role))
        for stmt in [s.strip() for s in sql.split(";") if s.strip()]:
            cur.execute(stmt)

    for f in ("01_setup.sql", "02_raw_ddl.sql", "03_file_format_stage.sql"):
        run_sql_file(f)

    cur.execute(f"USE SCHEMA {db}.{raw_schema}")
    for stem, (table, _) in TABLES.items():
        local = (RAW_DIR / f"{stem}.csv").as_posix()
        print(f"  PUT {stem}.csv → @RAW_STAGE/{table}/")
        cur.execute(f"PUT 'file://{local}' @RAW_STAGE/{table}/ OVERWRITE=TRUE AUTO_COMPRESS=TRUE")
        cur.execute(
            f"COPY INTO {table} FROM @RAW_STAGE/{table}/ "
            f"FILE_FORMAT = (FORMAT_NAME = OLIST_CSV) "
            f"ON_ERROR = ABORT_STATEMENT PURGE = FALSE"
        )

    counts: dict[str, int] = {}
    for _stem, (table, _) in TABLES.items():
        cur.execute(f"SELECT count(*) FROM {db}.{raw_schema}.{table}")
        counts[table] = cur.fetchone()[0]
    cur.close()
    con.close()
    _report(counts)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--target", choices=["duckdb", "snowflake"],
                    default=os.environ.get("DBT_TARGET", "duckdb"))
    args = ap.parse_args()

    _load_dotenv()
    _check_files()
    print(f"target: {args.target}")
    (load_snowflake if args.target == "snowflake" else load_duckdb)()


if __name__ == "__main__":
    main()
