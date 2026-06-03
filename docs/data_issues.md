# Data Issues Log

## Objective

This document records the initial data profiling results for the Bronze Layer tables in the VietDist Analytics project.

The purpose of this step is to understand raw data quality before building the dbt Silver Layer.

This profiling step helps identify issues such as missing business keys, duplicate records, and unexpected row counts before applying cleaning, type casting, deduplication, and business logic in Silver.

---

## Profiling Method

Profiling was performed using:

```bash
python 02_sql_analytics/profile_raw_tables.py
```

The profiling script checks:

- Total row count for each raw table
- Null percentage of key columns
- Duplicate rows based on defined business keys
- Latest successful batch from `raw.ingest_log` for normal raw tables
- Full version history for `raw.sales_targets_raw`

Most raw tables are profiled only on the **latest successful batch** because the Bronze Layer is append-oriented. This avoids false duplicate results caused by multiple ingestion runs.

The versioned sales target table `raw.sales_targets_raw` is profiled on **full history** because Silver target versioning requires all target versions to calculate `is_latest`.

---

## Profiling Summary

| Raw Table | Scope | Row Count | Duplicate Rows | Key Column Null Check |
|---|---|---:|---:|---|
| `raw.sales_transactions` | Latest successful batch | 119,101 | 0 | `order_id`: 0.0%, `product_id`: 0.0% |
| `raw.customer_master` | Latest successful batch | 2,000 | 0 | `customer_id`: 0.0% |
| `raw.product_master` | Latest successful batch | 100 | 0 | `product_id`: 0.0% |
| `raw.distributor_orders` | Latest successful batch | 35,945 | 0 | `order_id`: 0.0%, `distributor_id`: 0.0%, `product_id`: 0.0% |
| `raw.distributor_master` | Latest successful batch | 138 | 0 | `distributor_id`: 0.0% |
| `raw.employee_master` | Latest successful batch | 114 | 0 | `employee_id`: 0.0%, `effective_date`: 0.0% |
| `raw.territory_mapping` | Latest successful batch | 1,843 | 0 | `territory_id`: 0.0%, `employee_id`: 0.0%, `customer_id`: 0.0%, `effective_date`: 0.0% |
| `raw.return_transactions` | Latest successful batch | 3,665 | 0 | `return_id`: 0.0% |
| `raw.promotion_program` | Latest successful batch | 40 | 0 | `promotion_id`: 0.0% |
| `raw.sales_targets_raw` | Full history | 1,950 | 0 | `version_label`: 0.0%, `employee_id`: 0.0%, `month_col`: 0.0% |

---

## Key Findings

### 1. Key columns have no null values

All checked key columns have 0.0% null values.

This means the main identifiers are usable for Silver Layer modeling.

Examples of validated key columns include:

- `order_id`
- `customer_id`
- `product_id`
- `employee_id`
- `distributor_id`
- `return_id`
- `promotion_id`
- `version_label`
- `month_col`

---

### 2. No duplicate rows were detected based on defined business keys

The profiling script detected 0 duplicate rows across all profiled raw tables.

Business keys used for duplicate checks include:

| Raw Table | Duplicate Check Key |
|---|---|
| `raw.sales_transactions` | `order_id`, `product_id` |
| `raw.customer_master` | `customer_id` |
| `raw.product_master` | `product_id` |
| `raw.distributor_orders` | `order_id`, `distributor_id`, `product_id` |
| `raw.distributor_master` | `distributor_id` |
| `raw.employee_master` | `employee_id`, `effective_date` |
| `raw.territory_mapping` | `territory_id`, `employee_id`, `customer_id`, `effective_date` |
| `raw.return_transactions` | `return_id` |
| `raw.promotion_program` | `promotion_id` |
| `raw.sales_targets_raw` | `version_label`, `employee_id`, `year`, `month_col` |

---

### 3. Bronze append behavior is handled during profiling

Bronze is designed to preserve ingestion history. Therefore, if the same file is loaded more than once, Bronze may contain multiple batches.

To avoid interpreting expected Bronze append behavior as a data issue, profiling is scoped to the latest successful batch for normal raw tables.

This is controlled through:

```text
raw.ingest_log
```

For normal raw sources, the profiling script identifies the latest successful batch and checks only that batch.

For `raw.sales_targets_raw`, full history is checked because the target versioning logic needs all versions.

---

### 4. Sales target versioning was successfully handled in Bronze

The special sales target versioning process created:

- `raw.sales_target_files`
- `raw.sales_targets_raw`
- `raw.sales_target_versions`

The profiled versioned target table contains:

| Version | Rows |
|---|---:|
| `v1` | 1,332 |
| `v2` | 618 |
| Total | 1,950 |

The table covers both original and adjusted target plans.

This confirms that target versions were preserved instead of overwritten.

---

### 5. Bronze data is structurally ready for Silver transformation

The primary profiling checks passed:

```text
Key null checks: 0.0%
Duplicate business keys: 0
```

However, Bronze data is still raw and mostly text-based.

Silver Layer still needs to handle:

- Type casting
- Date parsing
- Numeric conversion
- Invalid placeholder values
- Standardized text formats
- Deduplication logic
- Versioning logic for sales targets
- Effective-date handling for employee history

---

## Planned Silver Layer Handling

| Area | Silver Treatment |
|---|---|
| IDs and codes | Trim whitespace, standardize values, remove invalid strings such as `nan`, `none`, `null`, and blank strings |
| Date columns | Safely cast to `DATE` using `CASE WHEN` logic before casting |
| Numeric columns | Safely cast revenue, quantity, cost, discount, and target fields to `NUMERIC` |
| Month and year fields | Cast to integer where appropriate |
| Duplicate records | Deduplicate using business keys and latest ingestion timestamp |
| Batch control | Use latest successful batch from `raw.ingest_log` for most Silver models |
| Sales targets | Use full history from `raw.sales_targets_raw` to calculate version rank and `is_latest` |
| Employee history | Preserve `effective_date` logic for historical employee dimension modeling |
| Metadata | Preserve `_source_file`, `_source_platform`, `_ingested_at`, and `_batch_id` |
| Silver audit metadata | Add `_processed_at` in dbt Silver models |

---

## Downstream Handling

The Silver Layer is implemented with dbt under:

```text
02_sql_analytics/dbt/models/silver/
```

Most Silver models are incremental and use:

```text
materialized='incremental'
incremental_strategy='delete+insert'
```

The exception is:

```text
silver.stg_sales_targets_versioned
```

This model is materialized as a full table because the `is_latest` flag depends on the full target version history.

---

## Notes

- The profiling result is based on the current local sample dataset.
- Passing key null and duplicate checks does not mean the data is fully clean.
- It only means the primary structural checks are acceptable.
- Bronze data still requires Silver transformation before it can be used for analytics.
- Normal raw tables are profiled by latest successful batch.
- Versioned sales target data is profiled by full history.
- Additional data issues may be added if discovered during future ingestion or Silver transformation runs.