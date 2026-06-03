# Gold Layer Summary

## Objective

This document summarizes the Gold Layer implementation for the VietDist Analytics project.

The Gold Layer transforms cleaned and validated Silver models into analytics-ready dimension, fact, and mart models under the PostgreSQL `gold` schema.

The Gold Layer is implemented using **dbt**. Gold models do not read directly from raw Bronze tables. Instead, they are built from tested Silver models using dbt `ref()` dependencies.

---

## Gold Layer Approach

Current flow:

```text
Bronze raw tables → dbt Silver models → dbt Gold models → Power BI
```

Gold models are stored under:

```text
02_sql_analytics/dbt/models/gold/
```

Gold models are built from Silver models such as:

```text
silver.stg_sales_transactions
silver.stg_customers
silver.stg_products
silver.stg_employees
silver.stg_distributor_orders
silver.stg_sales_targets_versioned
```

using dbt references such as:

```sql
FROM {{ ref('stg_sales_transactions') }}
```

This allows dbt to manage model lineage, dependency order, and testing.

---

## Completed Gold Dimension Models

| Gold Model | Source Model(s) | Purpose |
|---|---|---|
| `gold.dim_dates` | Generated date spine | Date dimension from 2022 to 2026 |
| `gold.dim_customers` | `silver.stg_customers` | Customer dimension with credit limit tier |
| `gold.dim_products` | `silver.stg_products` | Product dimension with unit margin metrics |
| `gold.dim_distributors` | `silver.stg_distributors` | Distributor dimension with credit limit tier |
| `gold.dim_employees` | `silver.stg_employees` | Employee dimension with effective-date history |
| `gold.dim_channels` | Multiple Silver models | Channel dimension for sales and distribution analysis |
| `gold.dim_regions` | Multiple Silver models | Region dimension |
| `gold.dim_geography` | Multiple Silver models | Region-province geography dimension |

---

## Completed Gold Fact Models

| Gold Model | Source Model(s) | Materialization | Purpose |
|---|---|---|---|
| `gold.fact_sales` | `silver.stg_sales_transactions`, Gold dimensions | incremental | Sales transaction fact table |
| `gold.fact_returns` | `silver.stg_return_transactions`, Gold dimensions | incremental | Return transaction fact table |
| `gold.fact_distributor_orders` | `silver.stg_distributor_orders`, Gold dimensions | incremental | Distributor order fact table |
| `gold.fact_targets` | `silver.stg_sales_targets_versioned`, Gold dimensions | table | Latest sales target fact table |

---

## Completed Gold Mart Models

| Gold Mart | Source Model(s) | Purpose |
|---|---|---|
| `gold.mart_sales_vs_target` | `gold.fact_sales`, `gold.fact_targets` | Compare actual sales performance against latest sales targets |
| `gold.mart_distributor_performance` | `gold.fact_distributor_orders`, `gold.dim_distributors` | Analyze distributor fulfillment and delivery performance |

---

## Model Materialization Strategy

Gold models use different materialization strategies depending on their purpose.

| Model Type | Materialization | Reason |
|---|---|---|
| Dimensions | table | Small reference-style models that can be rebuilt safely |
| Large facts | incremental | Transaction-level models that should not be rebuilt unnecessarily |
| Target fact | table | Depends on latest target version logic |
| Marts | table | Aggregated dashboard-ready models that should stay consistent with facts |

Large fact models use dbt incremental materialization with a `delete+insert` strategy.

Example pattern:

```sql
{{ 
    config(
        materialized='incremental',
        unique_key='fact_grain_key',
        incremental_strategy='delete+insert'
    ) 
}}
```

---

## Star Schema Design

The Gold Layer follows a star-schema-oriented structure.

### Sales Analytics

Main fact table:

```text
gold.fact_sales
```

Connected dimensions:

```text
gold.dim_dates
gold.dim_customers
gold.dim_products
gold.dim_employees
gold.dim_channels
gold.dim_geography
```

Main mart:

```text
gold.mart_sales_vs_target
```

Key metrics include:

- Total orders
- Active customers
- Actual quantity
- Actual revenue
- Target quantity
- Target revenue
- Quantity gap
- Revenue gap
- Quantity achievement percentage
- Revenue achievement percentage
- Gross profit
- Gross profit margin percentage

---

### Distributor Analytics

Main fact table:

```text
gold.fact_distributor_orders
```

Connected dimensions:

```text
gold.dim_dates
gold.dim_distributors
gold.dim_products
gold.dim_channels
gold.dim_geography
```

Main mart:

```text
gold.mart_distributor_performance
```

Key metrics include:

- Total orders
- Products ordered
- Total quantity ordered
- Total quantity delivered
- Fill rate percentage
- Total gross amount
- Total delivered amount
- Delivered amount rate percentage
- On-time delivery count
- Late delivery count
- On-time delivery rate percentage

---

## Important Business Logic

### Date Dimension

`gold.dim_dates` contains a full date spine from 2022 to 2026.

Fiscal year logic:

- Fiscal year starts in September.
- Months from September to December belong to the current fiscal year.
- Months from January to August belong to the previous fiscal year.

Example:

| Date | Fiscal Year |
|---|---|
| `2023-10-01` | 2023 |
| `2024-01-01` | 2023 |

---

### Product Dimension

`gold.dim_products` adds unit-level margin metrics:

| Field | Description |
|---|---|
| `unit_margin` | `unit_price - cost_price` |
| `unit_margin_pct` | Unit margin divided by unit price |

These fields support product profitability analysis.

---

### Customer and Distributor Credit Tiers

`gold.dim_customers` and `gold.dim_distributors` create credit limit tiers.

Customer credit tier logic:

| Condition | Tier |
|---|---|
| `credit_limit >= 200,000,000` | High Credit |
| `credit_limit >= 100,000,000` | Medium Credit |
| `credit_limit IS NOT NULL` | Low Credit |
| `credit_limit IS NULL` | Unknown |

Distributor credit tier logic:

| Condition | Tier |
|---|---|
| `credit_limit >= 500,000,000` | High Credit |
| `credit_limit >= 200,000,000` | Medium Credit |
| `credit_limit IS NOT NULL` | Low Credit |
| `credit_limit IS NULL` | Unknown |

---

### Employee Dimension

`gold.dim_employees` uses an effective-date history structure.

Fields added:

| Field | Description |
|---|---|
| `employee_key` | Historical employee key generated from employee ID and effective date |
| `effective_from` | Start date of the employee record |
| `effective_to` | End date of the employee record |
| `is_current` | Indicates whether this is the current employee record |

This allows historical joins between transaction dates and employee records.

Example join logic:

```sql
ON fact.employee_id = dim.employee_id
AND fact.transaction_date BETWEEN dim.effective_from AND dim.effective_to
```

---

### Sales Targets

`gold.fact_targets` keeps only latest applicable target records from:

```text
silver.stg_sales_targets_versioned
```

The model filters:

```sql
WHERE is_latest = TRUE
```

This ensures each employee-month has one latest applicable target.

The full target version history remains available in:

```text
silver.stg_sales_targets_versioned
```

---

### Sales vs Target Mart

`gold.mart_sales_vs_target` compares actual sales performance with latest targets by employee-month.

The mart includes:

- Actual orders
- Active customers
- Actual quantity
- Target quantity
- Quantity gap
- Quantity achievement percentage
- Actual revenue
- Target revenue
- Revenue gap
- Revenue achievement percentage
- Actual total cost
- Actual gross profit
- Actual gross profit margin percentage
- Target new customers

This mart is designed for Power BI dashboard pages focused on sales performance and target achievement.

---

### Distributor Performance Mart

`gold.mart_distributor_performance` summarizes distributor performance by distributor-month.

The mart includes:

- Total orders
- Products ordered
- Total quantity ordered
- Total quantity delivered
- Fill rate percentage
- Total gross amount
- Total delivered amount
- Delivered amount rate percentage
- On-time delivery count
- Late delivery count
- Delivery record count
- On-time delivery rate percentage

This mart is designed for Power BI dashboard pages focused on distributor fulfillment and delivery performance.

---

## Data Quality Tests

Gold data quality tests are managed by dbt in:

```text
02_sql_analytics/dbt/models/gold/schema.yml
```

The tests cover:

- Not-null checks for dimension keys
- Unique checks for dimension keys
- Not-null checks for fact grain keys
- Unique checks for fact grain keys
- Not-null checks for important foreign keys
- Not-null checks for mart reporting fields
- Validation of target latest-version output

Tests can be executed using:

```bash
dbt test --select gold
```

Latest Gold validation result:

```text
PASS=61
WARN=0
ERROR=0
```

---

## Execution

Gold models are executed using dbt.

From the dbt project directory:

```bash
cd 02_sql_analytics/dbt
```

Run the full Gold layer:

```bash
dbt run --select gold --full-refresh
```

Run Gold tests:

```bash
dbt test --select gold
```

For normal runs after the initial full refresh:

```bash
dbt run --select gold
```

---

## Power BI Usage

Power BI should connect to the PostgreSQL `gold` schema.

Recommended Gold tables for Power BI:

```text
gold.dim_dates
gold.dim_customers
gold.dim_products
gold.dim_distributors
gold.dim_employees
gold.dim_channels
gold.dim_regions
gold.dim_geography

gold.fact_sales
gold.fact_returns
gold.fact_distributor_orders
gold.fact_targets

gold.mart_sales_vs_target
gold.mart_distributor_performance
```

For dashboard-level reporting, the main recommended mart tables are:

```text
gold.mart_sales_vs_target
gold.mart_distributor_performance
```

For drill-down and detailed analysis, Power BI can also use the fact and dimension tables.

---

## Notes

- Gold is no longer executed using standalone SQL runner scripts.
- The old `dwh` schema has been replaced by the dbt-managed `gold` schema.
- Gold models are built from tested Silver models using dbt `ref()`.
- Dimension models are rebuilt as tables.
- Large fact models are incremental.
- Mart models are rebuilt as dashboard-ready summary tables.
- Gold tables are analytics-ready and can be connected directly to Power BI.
- Business aggregations are handled in mart tables.
- The next phase is to build or refresh Power BI dashboards using the Gold Layer tables.