# Sales Target Versioning Notes

## Objective

This document summarizes the special handling for `SRC02_sales_target_plan.xlsx`.

The sales target file contains multiple target plan versions in separate sheets. Each version must be preserved instead of being overwritten because target revisions are part of the business history.

This versioning logic affects the full pipeline:

```text
Bronze raw target versions
    ↓
Silver versioned target model
    ↓
Gold latest target fact
    ↓
Power BI actual vs target reporting
```

---

## Source File

```text
data/raw/SRC02_sales_target_plan.xlsx
```

The `data/` folder is excluded from GitHub using `.gitignore`.

---

## Source Sheets

| Sheet Name | Version Label | Description |
|---|---|---|
| `Plan_v1_Original` | `v1` | Original annual sales target plan |
| `Plan_v2_Adjustment_H2` | `v2` | Adjusted sales target plan for H2 |
| `summary` | Not loaded | Summary sheet, excluded from raw target ingestion |

---

## Why Versioning Is Needed

Sales targets can change during the year.

For example:

| Period | Original Target | Adjustment | Effective Version |
|---|---|---|---|
| Jan–Jun | `v1` | No adjustment | `v1` |
| Jul–Dec | `v1` | Adjusted by `v2` | `v2` where available |

If later versions were allowed to overwrite earlier versions, the project would lose the ability to audit how targets changed over time.

Therefore, the Bronze Layer stores all target versions, and the Silver Layer determines which version is latest for each employee-month.

---

## Bronze Tables Created

### `raw.sales_target_files`

This table stores one metadata record per source file and sheet version.

Key fields:

| Field | Description |
|---|---|
| `source_file` | Source Excel file name |
| `sheet_name` | Sheet name in the workbook |
| `version_label` | Extracted version label such as `v1` or `v2` |
| `rows_loaded` | Number of rows loaded from the sheet |
| `status` | Load status |
| `error_message` | Error message if the sheet failed |
| `ingested_at` | Ingestion timestamp |

---

### `raw.sales_targets_raw`

This table stores sales target data in normalized long format.

Key fields:

| Field | Description |
|---|---|
| `version_label` | Target version label |
| `version_date` | Target version date |
| `effective_from` | Version effective start date |
| `effective_to` | Version effective end date |
| `employee_id` | Sales employee identifier |
| `employee_name` | Sales employee name |
| `region` | Sales region |
| `team` | Sales team |
| `year` | Target year |
| `month` | Target month number |
| `month_col` | Original month column converted to `T1` to `T12` |
| `target_revenue` | Revenue target |
| `target_quantity` | Quantity target |
| `target_new_customers` | New customer target |
| `sheet_name` | Source sheet name |
| `_source_file` | Source file metadata |
| `_source_platform` | Source platform metadata |
| `_ingested_at` | Ingestion timestamp |
| `_batch_id` | Ingestion batch ID |

---

### `raw.sales_target_versions`

This table summarizes version-level metadata from `raw.sales_targets_raw`.

Key fields:

| Field | Description |
|---|---|
| `version_label` | Target version label |
| `source_file` | Source file name |
| `sheet_name` | Source sheet name |
| `row_count` | Number of rows for the version |
| `employee_count` | Number of employees included |
| `month_count` | Number of months included |
| `min_month_col` | Earliest month column |
| `max_month_col` | Latest month column |
| `first_ingested_at` | First ingestion timestamp |
| `last_ingested_at` | Latest ingestion timestamp |

---

## Bronze Processing Logic

The processing script performs the following steps:

1. Reads all sheets from `SRC02_sales_target_plan.xlsx`.
2. Excludes the `summary` sheet.
3. Extracts the version label from each sheet name.
4. Standardizes column names.
5. Removes empty rows.
6. Removes rows containing `TỔNG` or `Total`.
7. Converts month values into `month_col` format from `T1` to `T12`.
8. Adds source metadata columns.
9. Loads the normalized result into `raw.sales_targets_raw`.
10. Writes one load record per sheet into `raw.sales_target_files`.
11. Creates `raw.sales_target_versions` as a version summary table.

The script was executed with:

```bash
python 01_ingestion/loaders/process_sales_target_versions.py
```

---

## Bronze Validation Results

Validation output confirmed:

| Check | Result |
|---|---|
| Target sheets loaded | 2 |
| Distinct versions in `raw.sales_target_files` | `v1`, `v2` |
| Rows in `raw.sales_targets_raw` for `v1` | 1,332 |
| Rows in `raw.sales_targets_raw` for `v2` | 618 |
| Total rows loaded into `raw.sales_targets_raw` | 1,950 |
| Rows containing `TỔNG` or `Total` | 0 |
| Month values | `T1` to `T12` |

---

## Bronze Validation Queries

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

Check month values in correct numeric order:

```sql
SELECT DISTINCT month_col
FROM raw.sales_targets_raw
ORDER BY CAST(REPLACE(month_col, 'T', '') AS INTEGER);
```

---

## Silver Usage

The normalized Bronze target table:

```text
raw.sales_targets_raw
```

is transformed into the dbt Silver model:

```text
silver.stg_sales_targets_versioned
```

This Silver model adds target versioning logic required for analytics.

Key fields created in Silver:

| Field | Description |
|---|---|
| `version_rank` | Numeric rank extracted from `version_label` |
| `target_month_date` | First day of the target month |
| `is_latest` | Indicates whether this is the latest applicable target for each employee-month |

---

## Why `stg_sales_targets_versioned` Is Not Incremental

Most Silver models are incremental. However, `silver.stg_sales_targets_versioned` is intentionally materialized as a full table.

Reason:

The `is_latest` flag depends on the full version history.

When a new target version is added, older records may need to change from:

```text
is_latest = TRUE
```

to:

```text
is_latest = FALSE
```

A simple incremental model would add new rows but may not correctly re-rank old rows. Therefore, full recomputation is safer and more correct for this model.

---

## Silver Versioning Result

The model keeps both `v1` and `v2` records, but marks only the latest applicable record for each employee-month as `is_latest = TRUE`.

Expected logic:

| Version | Meaning |
|---|---|
| `v1` | Still latest for employee-months not replaced by `v2` |
| `v2` | Latest for adjusted H2 employee-months |

This allows the project to preserve history while reporting against the latest approved target.

---

## Gold Usage

The Gold model:

```text
gold.fact_targets
```

reads from:

```text
silver.stg_sales_targets_versioned
```

and keeps only records where:

```sql
WHERE is_latest = TRUE
```

This ensures that Power BI actual vs target reporting uses the latest effective target for each employee-month.

The full version history remains available in:

```text
silver.stg_sales_targets_versioned
```

---

## Power BI Usage

The target data is used in:

```text
gold.mart_sales_vs_target
```

This mart compares actual sales from `gold.fact_sales` against latest targets from `gold.fact_targets`.

Main target-related metrics include:

- Target revenue
- Actual revenue
- Revenue gap
- Revenue achievement percentage
- Target quantity
- Actual quantity
- Quantity gap
- Quantity achievement percentage
- Target new customers

---

## Notes

- The `summary` sheet is excluded from raw target ingestion.
- The script deletes and reloads only the same file and sheet combination when rerun. This avoids duplicate records while preserving other versions.
- The month values may appear as `T1`, `T10`, `T11`, `T12`, `T2` when sorted as text. This is not a data issue.
- Numeric sorting should use `CAST(REPLACE(month_col, 'T', '') AS INTEGER)`.
- Bronze preserves all target versions.
- Silver determines the latest applicable target per employee-month.
- Gold uses only the latest target records for Power BI reporting.