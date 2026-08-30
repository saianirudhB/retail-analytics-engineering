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

have_creds=0
[[ -f "$HOME/.kaggle/kaggle.json" ]] && have_creds=1
[[ -f "$HOME/.kaggle/access_token" ]] && have_creds=1
[[ -n "${KAGGLE_API_TOKEN:-}" ]] && have_creds=1
[[ -n "${KAGGLE_USERNAME:-}" && -n "${KAGGLE_KEY:-}" ]] && have_creds=1
if [[ "$have_creds" -eq 0 ]]; then
  echo "No Kaggle credentials found." >&2
  echo "See DATA_SETUP.md — provide one of:" >&2
  echo "  ~/.kaggle/kaggle.json  |  ~/.kaggle/access_token  |  KAGGLE_API_TOKEN  |  KAGGLE_USERNAME+KAGGLE_KEY" >&2
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
