# Sales Target Versioning Notes

## Objective

This document summarizes the special Bronze Layer handling for `SRC02_sales_target_plan.xlsx`.

The sales target file contains multiple target plan versions in separate sheets. Each version must be preserved instead of being overwritten.

## Source File

```text
data/raw/SRC02_sales_target_plan.xlsx
```

## Source Sheets

| Sheet Name | Version Label | Description |
|---|---|---|
| Plan_v1_Original | v1 | Original annual sales target plan |
| Plan_v2_Adjustment_H2 | v2 | Adjusted sales target plan for H2 |
| summary | Not loaded | Summary sheet, excluded from raw target ingestion |

## Bronze Tables Created

### raw.sales_target_files

This table stores one metadata record per source file and sheet version.

Key fields:

- `source_file`
- `sheet_name`
- `version_label`
- `rows_loaded`
- `status`
- `error_message`
- `ingested_at`

### raw.sales_targets_raw

This table stores the sales target data in long format.

Key fields:

- `version_label`
- `version_date`
- `effective_from`
- `effective_to`
- `employee_id`
- `employee_name`
- `region`
- `team`
- `year`
- `month`
- `month_col`
- `target_revenue`
- `target_quantity`
- `target_new_customers`
- `sheet_name`
- `_source_file`
- `_source_platform`
- `_ingested_at`
- `_batch_id`

### raw.sales_target_versions

This table summarizes version-level metadata from `raw.sales_targets_raw`.

Key fields:

- `version_label`
- `source_file`
- `sheet_name`
- `row_count`
- `employee_count`
- `month_count`
- `min_month_col`
- `max_month_col`
- `first_ingested_at`
- `last_ingested_at`

## Processing Logic

The script performs the following steps:

- Reads all sheets from `SRC02_sales_target_plan.xlsx`.
- Excludes the `summary` sheet.
- Extracts the version label from each sheet name.
- Standardizes column names.
- Removes empty rows.
- Removes rows containing `TỔNG` or `Total`.
- Converts month values into `month_col` format from `T1` to `T12`.
- Adds source metadata columns.
- Loads the normalized result into `raw.sales_targets_raw`.
- Writes one load record per sheet into `raw.sales_target_files`.
- Creates `raw.sales_target_versions` as a version summary table.

## Validation Results

The script was executed with:

```bash
python 01_ingestion/loaders/process_sales_target_versions.py
```

Validation output confirmed:

| Check | Result |
|---|---|
| Target sheets loaded | 2 |
| Distinct versions in `raw.sales_target_files` | v1, v2 |
| Rows in `raw.sales_targets_raw` for v1 | 1332 |
| Rows in `raw.sales_targets_raw` for v2 | 618 |
| Total rows loaded into `raw.sales_targets_raw` | 1950 |
| Rows containing `TỔNG` or `Total` | 0 |
| Month values | T1 to T12 |

## Validation Queries

Check rows by version:

```sql
SELECT 
    version_label,
    sheet_name,
    COUNT(*) AS row_count
FROM raw.sales_targets_raw
GROUP BY 
    version_label,
    sheet_name
ORDER BY 
    version_label,
    sheet_name;
```

Check invalid total rows:

```sql
SELECT COUNT(*) AS total_rows_left
FROM raw.sales_targets_raw
WHERE
    LOWER(COALESCE(employee_id, '')) LIKE '%tổng%'
    OR LOWER(COALESCE(employee_name, '')) LIKE '%tổng%'
    OR LOWER(COALESCE(month_col, '')) LIKE '%tổng%'
    OR LOWER(COALESCE(month_col, '')) LIKE '%total%';
```

Check month values in correct order:

```sql
SELECT DISTINCT month_col
FROM raw.sales_targets_raw
ORDER BY CAST(REPLACE(month_col, 'T', '') AS INTEGER);
```

## Notes

- The `summary` sheet is excluded from raw target ingestion.
- The script deletes and reloads only the same file and sheet combination when rerun. This avoids duplicate records while preserving other versions.
- The month values may appear as `T1`, `T10`, `T11`, `T12`, `T2` when sorted as text. This is not a data issue.
- Sales target type casting and business logic will be handled in the Silver Layer.