# Bronze Ingestion Summary

## Objective

This document summarizes the local Bronze Layer ingestion for the VietDist Analytics project.

The raw dataset was manually downloaded to the local machine and placed under:

```text
data/raw/
```

The `data/` folder is excluded from GitHub using `.gitignore`.

## Ingestion Approach

At this stage, data ingestion is done from local files instead of Google Drive or OneDrive connectors.

Current flow:

```text
Local raw files → Python parser → PostgreSQL raw schema → ingest_log
```

Automation from Google Drive and OneDrive will be implemented later.

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
- Local ingestion is used first to complete and validate the pipeline logic before implementing automated Google Drive and OneDrive ingestion.