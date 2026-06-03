# Silver Layer Summary

## Objective

This document summarizes the Silver Layer implementation for the VietDist Analytics project.

The Silver Layer transforms Bronze raw tables into cleaned, typed, standardized, deduplicated, and validated staging models under the PostgreSQL `silver` schema.

The Silver Layer is implemented using **dbt** instead of standalone SQL scripts. This allows the project to manage model dependencies, materialization logic, incremental processing, data quality tests, and lineage in a more controlled and reproducible way.

---

## Silver Layer Approach

Current flow:

```text
Bronze raw tables → dbt Silver models → PostgreSQL silver schema
```

The Silver models read from Bronze sources declared in:

```text
02_sql_analytics/dbt/models/silver/sources.yml
```

and are built under:

```text
02_sql_analytics/dbt/models/silver/
```

Most Silver models are implemented as dbt **incremental models**. This means:

- If the Silver table does not exist, dbt creates it.
- If the Silver table already exists, dbt processes only newer successful ingestion batches.
- Duplicate business keys are handled using dbt `unique_key` and the `delete+insert` incremental strategy.
- Bronze data remains append-only and unchanged.

---

## Completed Silver Models

| Silver Model | Source Table | Materialization | Purpose |
|---|---|---|---|
| `silver.stg_customers` | `raw.customer_master` | incremental | Clean customer master data |
| `silver.stg_products` | `raw.product_master` | incremental | Clean product master data |
| `silver.stg_employees` | `raw.employee_master` | incremental | Clean employee master data with effective-date history |
| `silver.stg_distributors` | `raw.distributor_master` | incremental | Clean distributor master data |
| `silver.stg_territory_mapping` | `raw.territory_mapping` | incremental | Clean territory, employee, and customer mapping |
| `silver.stg_return_transactions` | `raw.return_transactions` | incremental | Clean return transaction data |
| `silver.stg_promotion_program` | `raw.promotion_program` | incremental | Clean promotion program data |
| `silver.stg_sales_transactions` | `raw.sales_transactions` | incremental | Clean sales transaction data |
| `silver.stg_distributor_orders` | `raw.distributor_orders` | incremental | Clean distributor order data |
| `silver.stg_sales_targets_versioned` | `raw.sales_targets_raw` | table | Clean and version sales target data |

---

## Incremental Logic

Most Silver models use dbt incremental materialization.

Example pattern:

```sql
{{ 
    config(
        materialized='incremental',
        unique_key='business_key',
        incremental_strategy='delete+insert'
    ) 
}}
```

Each incremental Silver model reads from the latest successful Bronze batch using `raw.ingest_log`:

```sql
WITH latest_success_batch AS (
    SELECT
        batch_id
    FROM {{ source('raw', 'ingest_log') }}
    WHERE source_name = '<source_name>'
      AND status = 'SUCCESS'
    ORDER BY finished_at DESC
    LIMIT 1
)
```

During incremental runs, only newer processed data is loaded:

```sql
{% if is_incremental() %}
  AND _ingested_at > (
      SELECT COALESCE(MAX(_ingested_at), TIMESTAMP '1900-01-01')
      FROM {{ this }}
  )
{% endif %}
```

This avoids rebuilding fixed staging tables from scratch while still allowing new successful batches to be processed.

---

## Unique Keys Used

| Model | Unique Key |
|---|---|
| `stg_customers` | `customer_id` |
| `stg_products` | `product_id` |
| `stg_distributors` | `distributor_id` |
| `stg_employees` | `employee_id`, `effective_date` |
| `stg_territory_mapping` | `territory_id`, `employee_id`, `customer_id`, `effective_date` |
| `stg_promotion_program` | `promotion_id` |
| `stg_return_transactions` | `return_id` |
| `stg_sales_transactions` | `order_id`, `product_id` |
| `stg_distributor_orders` | `order_id`, `distributor_id`, `product_id` |

---

## Transformation Rules Applied

The Silver models apply the following standard transformations:

- Trim whitespace from text fields
- Convert blank strings and invalid placeholders to `NULL`
- Handle invalid values such as `nan`, `none`, `null`, and `nat`
- Use `CASE WHEN` before type casting to avoid failed casts
- Cast date fields safely to `DATE`
- Cast numeric fields safely to `NUMERIC`
- Cast month and year fields to integer where appropriate
- Deduplicate records using business keys and latest ingestion timestamp
- Preserve Bronze metadata columns:
  - `_source_file`
  - `_source_platform`
  - `_ingested_at`
  - `_batch_id`
- Add Silver processing metadata:
  - `_processed_at`

---

## Sales Target Versioning

The sales target model is handled separately because the source file contains multiple target plan versions.

The Silver model:

```text
silver.stg_sales_targets_versioned
```

contains both `v1` and `v2` target records.

Additional fields are created:

| Field | Description |
|---|---|
| `version_rank` | Numeric rank extracted from the version label |
| `version_date` | Date of the target version |
| `effective_from` | Start date of the target version |
| `effective_to` | End date of the target version |
| `target_month_date` | First day of the target month |
| `is_latest` | Indicates the latest applicable target for each employee-month |

This model is intentionally materialized as a full table instead of incremental because the `is_latest` flag depends on the full version history.

When a new target version is added, older version rows may need to be re-ranked and updated from:

```text
is_latest = TRUE
```

to:

```text
is_latest = FALSE
```

Therefore, a full recomputation is safer and more correct for this model.

---

## Data Quality Tests

Silver data quality tests are managed by dbt in:

```text
02_sql_analytics/dbt/models/silver/schema.yml
```

The tests cover:

- Not-null checks for key fields
- Unique checks for business keys
- Composite key validation through model-level grain design
- Not-null checks for metadata fields such as `_batch_id`
- Validation of versioned sales target logic

Tests can be executed using:

```bash
dbt test --select silver
```

Latest Silver validation result:

```text
PASS
WARN=0
ERROR=0
```

---

## Execution

Silver models are executed using dbt.

From the dbt project directory:

```bash
cd 02_sql_analytics/dbt
```

Run the full Silver layer:

```bash
dbt run --select silver --full-refresh
```

Run Silver tests:

```bash
dbt test --select silver
```

For normal incremental runs after the initial full refresh:

```bash
dbt run --select silver
```

---

## Notes

- Silver is no longer executed using standalone SQL runner scripts.
- The old `DROP TABLE IF EXISTS` and `CREATE TABLE AS` approach has been replaced by dbt materializations.
- Most Silver models use incremental loading with the `delete+insert` strategy.
- `stg_sales_targets_versioned` remains a full table model due to version re-ranking requirements.
- Bronze data remains append-only and unchanged.
- Business-level aggregations are not handled in Silver. They are implemented in the Gold Layer.
- The Gold Layer is built from tested Silver models using dbt `ref()`.