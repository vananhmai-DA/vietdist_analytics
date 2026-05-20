# Data Issues Log

## Objective

This document records the initial data profiling results for the Bronze Layer tables in the VietDist Analytics project.

The purpose of this step is to understand data quality before building the Silver Layer.

## Profiling Method

Profiling was performed using:

```bash
python 02_sql_analytics/profile_raw_tables.py
```

The profiling script checks:

- Total row count for each raw table
- Null percentage of key columns
- Duplicate rows based on defined business keys

## Profiling Summary

| Raw Table | Row Count | Duplicate Rows | Key Column Null Check |
|---|---:|---:|---|
| raw.sales_transactions | 119101 | 0 | order_id: 0.0% |
| raw.sales_target_plan | 1332 | 0 | plan_version: 0.0%, employee_id: 0.0%, month: 0.0% |
| raw.sales_targets_raw | 1950 | 0 | version_label: 0.0%, employee_id: 0.0%, month_col: 0.0% |
| raw.customer_master | 2000 | 0 | customer_id: 0.0% |
| raw.product_master | 100 | 0 | product_id: 0.0% |
| raw.distributor_orders | 35945 | 0 | order_id: 0.0%, distributor_id: 0.0%, product_id: 0.0% |
| raw.distributor_master | 138 | 0 | distributor_id: 0.0% |
| raw.employee_master | 114 | 0 | employee_id: 0.0% |
| raw.territory_mapping | 1843 | 0 | territory_id: 0.0%, employee_id: 0.0%, customer_id: 0.0% |
| raw.return_transactions | 3665 | 0 | return_id: 0.0% |
| raw.promotion_program | 40 | 0 | promotion_id: 0.0% |

## Key Findings

### 1. Key columns have no null values

All checked key columns have 0.0% null values.

This means the main identifiers are usable for Silver Layer modeling.

### 2. No duplicate rows were detected based on defined business keys

The profiling script detected 0 duplicate rows across all profiled raw tables.

Business keys used for duplicate checks include examples such as:

- `order_id`, `product_id` for sales transactions
- `customer_id` for customer master
- `product_id` for product master
- `employee_id`, `effective_date` for employee master
- `version_label`, `employee_id`, `year`, `month_col` for sales target raw data

### 3. Sales target versioning was successfully handled in Bronze

The special sales target versioning process created:

- `raw.sales_target_files`
- `raw.sales_targets_raw`
- `raw.sales_target_versions`

The profiled versioned target table `raw.sales_targets_raw` contains 1950 rows, covering both `v1` and `v2`.

### 4. Bronze data is structurally ready for Silver transformation

Although key nulls and duplicate checks passed, Bronze data is still stored mostly as text.

Silver Layer still needs to handle:

- Type casting
- Date parsing
- Numeric conversion
- Standardized status values
- Standardized text casing
- Business-rule validation
- SCD handling for employee and distributor dimensions

## Planned Silver Layer Handling

| Area | Planned Silver Treatment |
|---|---|
| IDs and codes | Trim whitespace, standardize casing, remove invalid string values such as `nan`, `none`, `null` |
| Date columns | Cast to `DATE` and validate invalid or missing dates |
| Numeric columns | Cast revenue, quantity, cost, discount, and target fields to numeric types |
| Status columns | Standardize values such as active/inactive, paid/unpaid, delivered/pending |
| Duplicate records | Use business keys and latest ingestion timestamp if deduplication becomes necessary |
| Sales targets | Use `raw.sales_targets_raw` as the main input for versioned target transformation |
| Employee history | Preserve effective-date logic for SCD Type 2 handling |
| Distributor history | Preserve effective-date logic for SCD Type 2 handling |

## Notes

- The profiling result is based on the current local sample dataset.
- Further issue logs may be added during Silver transformation if additional data quality problems are discovered.
- Passing key null and duplicate checks does not mean the data is fully clean. It only means the primary profiling checks are acceptable.