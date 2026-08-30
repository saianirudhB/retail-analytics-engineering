# Data setup

The Olist dataset is not in this repo. Get it one of two ways.

---

## Option A — automated (Kaggle API)  ✅ recommended

1. Create a Kaggle account, then go to **Account → Settings → API → "Create New Token"**.
   This downloads `kaggle.json`.
2. Put it where the Kaggle client looks for it:

   ```bash
   mkdir -p ~/.kaggle
   mv ~/Downloads/kaggle.json ~/.kaggle/kaggle.json
   chmod 600 ~/.kaggle/kaggle.json
   ```

3. Download + unzip into `data/raw/`:

   ```bash
   make data          # wraps scripts/download_data.sh
   ```

   (or run `./scripts/download_data.sh` directly).

The script accepts the token from `~/.kaggle/kaggle.json` **or** from
`KAGGLE_USERNAME` / `KAGGLE_KEY` in your `.env`.

---

## Option B — manual download

1. Open <https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce>.
2. Click **Download** (top right) — you get `archive.zip`.
3. Unzip **all 9 CSVs** directly into `data/raw/` (no nested folder):

   ```bash
   unzip ~/Downloads/archive.zip -d data/raw/
   ls data/raw/          # should list 9 .csv files
   ```

---

## Verify

```bash
make load               # loads data/raw/ into the DuckDB RAW schema and checks row counts
```

You should see a table of 9 tables with non-zero row counts and a final
`✅ all raw tables loaded and validated` line. If a count is zero or a file is
missing the script exits non-zero.
