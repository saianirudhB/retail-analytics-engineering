#!/usr/bin/env bash
# Download the Olist dataset from Kaggle into data/raw/.
# Auth: ~/.kaggle/kaggle.json  OR  KAGGLE_USERNAME + KAGGLE_KEY (env / .env).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RAW_DIR="$ROOT/data/raw"
DATASET="olistbr/brazilian-ecommerce"

# Load .env if present (without clobbering already-exported vars)
if [[ -f "$ROOT/.env" ]]; then
  set -a; # shellcheck disable=SC1091
  source "$ROOT/.env"; set +a
fi

if ! command -v kaggle >/dev/null 2>&1; then
  echo "kaggle CLI not found. Install with:  pip install kaggle==1.6.17" >&2
  echo "or run this through Docker:  docker compose run --rm dbt ./scripts/download_data.sh" >&2
  exit 1
fi

if [[ ! -f "$HOME/.kaggle/kaggle.json" && ( -z "${KAGGLE_USERNAME:-}" || -z "${KAGGLE_KEY:-}" ) ]]; then
  echo "No Kaggle credentials found." >&2
  echo "See DATA_SETUP.md — put kaggle.json at ~/.kaggle/kaggle.json or set KAGGLE_USERNAME/KAGGLE_KEY." >&2
  exit 1
fi

mkdir -p "$RAW_DIR"
echo "Downloading $DATASET → $RAW_DIR"
kaggle datasets download -d "$DATASET" -p "$RAW_DIR" --unzip

echo
echo "Files in data/raw/:"
ls -1 "$RAW_DIR"/*.csv
echo
echo "✅ download complete — now run:  make load"
