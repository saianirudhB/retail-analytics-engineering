# =============================================================================
# dbt runtime. Pinned Python so the project is reproducible regardless of the
# host's Python version (the local machine runs 3.14, which dbt does not yet
# support). Bundles both adapters so the same image runs the local DuckDB
# target and the Snowflake target.
# =============================================================================
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    DBT_PROFILES_DIR=/workspace/dbt \
    DBT_PROJECT_DIR=/workspace/dbt

RUN apt-get update \
    && apt-get install -y --no-install-recommends git make \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

COPY requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt

# Project is bind-mounted at runtime (see docker-compose.yml) so model edits
# on the host take effect without rebuilding.
CMD ["bash"]
