# analysis/

Exploratory and business analysis on top of the built marts.

| File | What it is |
|---|---|
| `run_eda.py` | One script, ~20 queries. Prints every figure used in `business-insights.md` and `docs/data-quality.md`. Run: `docker compose run --rm dbt python /workspace/analysis/run_eda.py` |
| `business-insights.md` | The findings, written for a business reader. Every number is traceable to a query in `run_eda.py`. |
| `queries/` | Stand-alone SQL for the headline questions, runnable in any warehouse client. |

Nothing here is hand-computed or estimated — if a number isn't produced by a
query in this folder, it isn't in the writeup.
