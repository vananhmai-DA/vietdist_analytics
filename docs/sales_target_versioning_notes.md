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
- `ingested_at`

### raw.sales_targets_raw

This table stores the sales target data in long format.

Key fields:

- `version_label`
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
- `_source_file`
- `_source_platform`
- `_ingested_at`
- `_batch_id`

### raw.sales_target_versions

This table summarizes version-level metadata from `raw.sales_targets_raw`.

## Validation Results

The script was executed with:

```bash
python 01_ingestion/loaders/process_sales_target_versions.py
```

Validation output confirmed:

| Check | Result |
|---|---|
| Distinct versions in `raw.sales_target_files` | v1, v2 |
| Rows in `raw.sales_targets_raw` for v1 | 1332 |
| Rows in `raw.sales_targets_raw` for v2 | 618 |
| Rows containing `TỔNG` or `Total` | 0 |
| Month values | T1 to T12 |

## Notes

- The `summary` sheet is excluded from raw target ingestion.
- The script deletes and reloads only the same file and sheet combination when rerun. This avoids duplicate records while preserving other versions.
- Sales target type casting and business logic will be handled in the Silver Layer.