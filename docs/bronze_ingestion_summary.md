# Bronze Ingestion Summary

## Objective

This document summarizes the Bronze Layer ingestion for the VietDist Analytics project.

The Bronze Layer stores raw source data in PostgreSQL with minimal transformation. Its main purpose is to preserve source-level data and metadata so that downstream Silver and Gold models can be traced back to the original ingestion batch.

The raw sample dataset is stored locally under:

```text
data/raw/
```

The `data/` folder is excluded from GitHub using `.gitignore`.

---

## Bronze Layer Approach

This project version uses local sample files to ensure reproducibility and simplify environment setup.

Current flow:

```text
Local raw files → Python parser → PostgreSQL raw schema → ingest_log
```

The ingestion logic is modular. Although the current implementation uses local files, the structure allows cloud-based connectors such as Google Drive and OneDrive to be integrated later without changing the downstream Silver and Gold logic.

For transaction-type sources, loaders are designed to process files by folder pattern instead of relying on only one hard-coded file. This makes the pipeline extensible when multiple daily files are added later.

---

## Bronze Schema

Bronze tables are stored under the PostgreSQL schema:

```text
raw
```

The Bronze Layer is intentionally append-oriented. Raw ingestion history is preserved, and deduplication is handled later in the Silver Layer.

---

## Bronze Tables Loaded

| Source File / Pattern | Raw Table | Rows Loaded | Status |
|---|---|---:|---|
| `SRC01_sales_transactions*.csv` | `raw.sales_transactions` | 119,101 | SUCCESS |
| `SRC02_sales_target_plan.xlsx` | `raw.sales_target_plan` | 1,955 | SUCCESS |
| `SRC03_customer_master.csv` | `raw.customer_master` | 2,000 | SUCCESS |
| `SRC04_product_master.xlsx` | `raw.product_master` | 100 | SUCCESS |
| `SRC05_distributor_orders.xlsx` | `raw.distributor_orders` | 35,945 | SUCCESS |
| `SRC06_distributor_master.csv` | `raw.distributor_master` | 138 | SUCCESS |
| `SRC07_employee_master.xlsx` | `raw.employee_master` | 114 | SUCCESS |
| `SRC08_territory_mapping.xlsx` | `raw.territory_mapping` | 1,843 | SUCCESS |
| `SRC09_return_transactions*.csv` | `raw.return_transactions` | 3,665 | SUCCESS |
| `SRC10_promotion_program.xlsx` | `raw.promotion_program` | 40 | SUCCESS |

---

## Bronze Metadata Columns

The following metadata columns are added during ingestion:

| Metadata Column | Description |
|---|---|
| `_source_file` | Original source file name |
| `_source_platform` | Source platform, currently local sample files |
| `_ingested_at` | Timestamp when the row was loaded into PostgreSQL |
| `_batch_id` | Unique ID for each ingestion batch |

These metadata fields allow each row to be traced back to its source file and ingestion run.

---

## Ingestion Log

All loaders write execution records into:

```text
raw.ingest_log
```

Key fields include:

| Field | Description |
|---|---|
| `batch_id` | Unique ingestion batch ID |
| `source_name` | Source table or source entity name |
| `source_file` | File name loaded |
| `source_platform` | Source platform |
| `rows_loaded` | Number of rows loaded |
| `status` | SUCCESS or FAILED |
| `error_message` | Error detail if failed |
| `failed_step` | Pipeline step where failure occurred |
| `started_at` | Start timestamp |
| `finished_at` | Finish timestamp |
| `duration_sec` | Runtime duration in seconds |

The `failed_step` field helps identify where a loader failed.

Examples:

```text
CHECK_SOURCE_FILE
PARSE_FILE
LOAD_TO_BRONZE
VALIDATE_LOAD
```

---

## Loader Validation

For individual loaders, validation checks whether the number of rows loaded into PostgreSQL for the current `_batch_id` matches the expected DataFrame row count.

This helps confirm that the loader did not silently drop or duplicate rows during ingestion.

Bronze tables were also validated using:

```bash
python 01_ingestion/check_bronze_tables.py
```

The validation script checks:

- Row counts for expected raw tables
- Latest ingestion logs from `raw.ingest_log`
- SUCCESS status for each loaded source
- Metadata availability for loaded tables
- Whether each batch was loaded with the expected row count

---

## Special Bronze Handling: Sales Target Versioning

The sales target source requires additional Bronze processing because the file contains multiple target plan versions in separate sheets.

The general raw file is loaded into:

```text
raw.sales_target_plan
```

However, for target versioning and downstream analytics, an additional normalized versioning process is used.

Additional raw tables created:

| Table | Purpose | Rows / Records |
|---|---|---:|
| `raw.sales_target_files` | Stores one metadata record per target file and sheet version | 2 records |
| `raw.sales_targets_raw` | Stores normalized target data in long format | 1,950 rows |
| `raw.sales_target_versions` | Summarizes version-level metadata | 2 versions |

Versioning result:

| Version Label | Sheet Name | Rows Loaded |
|---|---|---:|
| `v1` | `Plan_v1_Original` | 1,332 |
| `v2` | `Plan_v2_Adjustment_H2` | 618 |

The `summary` sheet is excluded from raw target version ingestion.

Detailed notes are documented in:

```text
docs/sales_target_versioning_notes.md
```

---

## Bronze to Silver Handoff

The Bronze Layer stores raw data with minimal transformation. Type casting, data cleaning, deduplication, and business validation are handled in the dbt Silver Layer.

The Silver Layer reads Bronze tables as dbt sources, mainly from:

```text
raw.*
```

For most normal raw tables, Silver models select the latest successful batch from:

```text
raw.ingest_log
```

For versioned sales targets, Silver reads the full version history from:

```text
raw.sales_targets_raw
```

because latest-version logic depends on the full version history.

---

## Notes

- Bronze data is stored with minimal transformation.
- All non-timestamp columns are loaded as text to avoid type issues at the Bronze stage.
- Bronze is append-oriented and preserves ingestion history.
- Type casting and cleaning are handled in the Silver Layer.
- `sales_transactions` and `return_transactions` use folder-based loaders so the pipeline can support multiple daily files later.
- `promotion_program` and `sales_target_plan` require special handling because they may contain multiple sheets.
- `sales_target_plan` has both a general Bronze raw table and a separate normalized versioning process for target-specific analytics.
- The current implementation focuses on local sample-file ingestion for reproducibility, while keeping the pipeline structure extensible for future cloud-source automation.
- Downstream transformation is handled by dbt Silver and Gold models.