# =============================================================================
# Developer entrypoints. Everything runs through the dbt container so results
# are identical on any machine. Override the warehouse with `make DBT_TARGET=snowflake <goal>`.
# =============================================================================
DBT_TARGET ?= duckdb
DC         := docker compose run --rm -e DBT_TARGET=$(DBT_TARGET) dbt
DBT        := $(DC) dbt --no-use-colors

.DEFAULT_GOAL := help

.PHONY: help build image data load debug deps seed run test build-all docs clean shell fmt

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

image: ## Build the dbt Docker image
	docker compose build

data: ## Download the Olist dataset from Kaggle into data/raw/ (needs ~/.kaggle/kaggle.json)
	./scripts/download_data.sh

load: ## Load data/raw/*.csv into the warehouse RAW schema ($(DBT_TARGET))
	$(DC) python /workspace/scripts/load_raw.py --target $(DBT_TARGET)

debug: ## dbt debug — verify the warehouse connection
	$(DBT) debug

deps: ## Install dbt packages
	$(DBT) deps

seed: ## Load dbt seeds (product category translation)
	$(DBT) seed

run: ## Run all models
	$(DBT) run

test: ## Run all tests
	$(DBT) test

build-all: ## deps + seed + run + test in one DAG pass
	$(DBT) build

docs: ## Generate dbt docs (writes dbt/target/)
	$(DBT) docs generate

shell: ## Open a shell in the dbt container
	$(DC) bash

fmt: ## Check SQL formatting with sqlfluff
	$(DC) sqlfluff lint models || true

clean: ## Remove dbt artefacts and the local DuckDB file
	rm -rf dbt/target dbt/dbt_packages dbt/logs dbt/retail.duckdb
