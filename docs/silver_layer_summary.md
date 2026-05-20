# Silver Layer Summary

## Objective

This document summarizes the Silver Layer implementation for the VietDist Analytics project.

The Silver Layer transforms Bronze raw tables into cleaned, typed, standardized, and validated staging tables under the PostgreSQL `staging` schema.

## Completed Silver Models

| Silver Table | Source Table | Purpose |
|---|---|---|
| staging.stg_customers | raw.customer_master | Clean customer master data |
| staging.stg_products | raw.product_master | Clean product master data |
| staging.stg_employees | raw.employee_master | Clean employee master data with effective-date history |
| staging.stg_distributors | raw.distributor_master | Clean distributor master data |
| staging.stg_territory_mapping | raw.territory_mapping | Clean territory, employee, and customer mapping |
| staging.stg_return_transactions | raw.return_transactions | Clean return transaction data |
| staging.stg_promotion_program | raw.promotion_program | Clean promotion program data |
| staging.stg_sales_transactions | raw.sales_transactions | Clean sales transaction data |
| staging.stg_distributor_orders | raw.distributor_orders | Clean distributor order data |
| staging.stg_sales_targets_versioned | raw.sales_targets_raw | Clean and version sales target data |

## Transformation Rules Applied

The Silver models apply the following standard transformations:

- Trim whitespace from text fields
- Convert blank strings to `NULL`
- Remove invalid key values such as `nan`, `none`, and `null`
- Cast date fields to `DATE`
- Cast numeric fields to `NUMERIC`
- Cast month and year fields to integer where appropriate
- Deduplicate records using business keys and latest ingestion timestamp
- Preserve metadata columns from Bronze:
  - `_source_file`
  - `_source_platform`
  - `_ingested_at`
  - `_batch_id`

## Sales Target Versioning

The sales target model was handled separately because the source file contains multiple plan versions.

The Silver table:

```text
staging.stg_sales_targets_versioned
```

contains both `v1` and `v2` target records.

Additional fields were created:

| Field | Description |
|---|---|
| version_rank | Numeric rank extracted from version label |
| target_month_date | First day of the target month |
| is_latest | Indicates the latest applicable target for each employee-month |

Validation confirmed that each employee-month has only one latest target record.

## Data Quality Tests

Silver data quality tests were created in:

```text
02_sql_analytics/silver/test_silver_models.sql
```

The tests cover:

- Row count checks
- Not-null checks for key fields
- Unique key checks
- Duplicate latest target checks for sales targets

The goal is to maintain zero test failures before building Gold Layer models.

## Execution

SQL models can be executed using:

```bash
python 02_sql_analytics/run_sql_file.py 02_sql_analytics/silver/<model_file>.sql
```

Example:

```bash
python 02_sql_analytics/run_sql_file.py 02_sql_analytics/silver/stg_sales_transactions.sql
```

## Notes

- Silver tables are rebuilt from Bronze using `DROP TABLE IF EXISTS` and `CREATE TABLE AS`.
- Bronze data remains unchanged.
- Business-level aggregations are not handled in Silver. They will be implemented in the Gold Layer.
- The next phase is to build dimension, fact, and mart tables in the `dwh` schema.