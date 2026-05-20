# Bronze Ingestion Summary

## Objective

This document summarizes the Bronze Layer ingestion for the VietDist Analytics project.

The raw sample dataset is stored locally under:

```text
data/raw/
```

The `data/` folder is excluded from GitHub using `.gitignore`.

## Ingestion Approach

This project version uses local sample files to ensure reproducibility and simplify environment setup.

Current flow:

```text
Local raw files → Python parser → PostgreSQL raw schema → ingest_log
```

The ingestion logic is designed in a modular way, allowing cloud-based connectors such as Google Drive and OneDrive to be integrated as future enhancements without changing the downstream Bronze, Silver, and Gold layer logic.

## Bronze Tables Loaded

| Source File | Raw Table | Rows Loaded | Status |
|---|---|---:|---|
| SRC01_sales_transactions.csv | raw.sales_transactions | 119101 | SUCCESS |
| SRC02_sales_target_plan.xlsx | raw.sales_target_plan | 1332 | SUCCESS |
| SRC03_customer_master.csv | raw.customer_master | 2000 | SUCCESS |
| SRC04_product_master.xlsx | raw.product_master | 100 | SUCCESS |
| SRC05_distributor_orders.xlsx | raw.distributor_orders | 35945 | SUCCESS |
| SRC06_distributor_master.csv | raw.distributor_master | 138 | SUCCESS |
| SRC07_employee_master.xlsx | raw.employee_master | 114 | SUCCESS |
| SRC08_territory_mapping.xlsx | raw.territory_mapping | 1843 | SUCCESS |
| SRC09_return_transactions.csv | raw.return_transactions | 3665 | SUCCESS |
| SRC10_promotion_program.xlsx | raw.promotion_program | 40 | SUCCESS |

## Validation

Bronze tables were validated using:

```bash
python 01_ingestion/check_bronze_tables.py
```

The validation script checks:

- Row counts for all expected raw tables
- Latest ingestion logs from `raw.ingest_log`
- SUCCESS status for each loaded source

## Notes

- Bronze layer stores raw data with minimal transformation.
- Metadata columns were added during ingestion:
  - `_source_file`
  - `_source_platform`
  - `_ingested_at`
  - `_batch_id`
- All non-timestamp columns are loaded as text to avoid type issues at the Bronze stage.
- Type casting and data cleaning will be handled in the Silver layer.
- The current implementation focuses on local sample-file ingestion for reproducibility, while keeping the pipeline structure extensible for future cloud-source automation.