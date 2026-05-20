# Gold Layer Summary

## Objective

This document summarizes the Gold Layer implementation for the VietDist Analytics project.

The Gold Layer transforms cleaned Silver staging tables into analytics-ready dimension, fact, and mart tables under the PostgreSQL `dwh` schema.

## Completed Gold Dimension Tables

| Gold Table | Source Table | Purpose |
|---|---|---|
| dwh.dim_date | Generated date spine | Date dimension from 2022 to 2026 |
| dwh.dim_customers | staging.stg_customers | Customer dimension |
| dwh.dim_products | staging.stg_products | Product dimension with margin metrics |
| dwh.dim_employees | staging.stg_employees | Employee dimension with SCD Type 2 structure |
| dwh.dim_distributors | staging.stg_distributors | Distributor dimension |

## Completed Gold Fact Tables

| Gold Table | Source Table | Purpose |
|---|---|---|
| dwh.fact_sales | staging.stg_sales_transactions | Sales transaction fact table |
| dwh.fact_returns | staging.stg_return_transactions | Return transaction fact table |
| dwh.fact_targets | staging.stg_sales_targets_versioned | Latest sales target fact table |
| dwh.fact_distributor_orders | staging.stg_distributor_orders | Distributor order fact table |

## Completed Gold Mart Tables

| Mart Table | Source Tables | Purpose |
|---|---|---|
| dwh.mart_sales_vs_target | dwh.fact_sales, dwh.fact_targets | Compare actual sales performance against targets |
| dwh.mart_distributor_performance | dwh.fact_distributor_orders, dwh.dim_distributors | Analyze distributor order fulfillment and delivery performance |

## Star Schema Design

The Gold Layer follows a star-schema-oriented structure.

### Sales Analytics

Main fact table:

```text
dwh.fact_sales
```

Connected dimensions:

```text
dwh.dim_date
dwh.dim_customers
dwh.dim_products
dwh.dim_employees
```

Main mart:

```text
dwh.mart_sales_vs_target
```

Key metrics:

- Total orders
- Active customers
- Actual quantity
- Actual revenue
- Target quantity
- Target revenue
- Quantity gap
- Revenue gap
- Revenue achievement percentage
- Gross profit
- Gross profit margin percentage

### Distributor Analytics

Main fact table:

```text
dwh.fact_distributor_orders
```

Connected dimensions:

```text
dwh.dim_date
dwh.dim_distributors
dwh.dim_products
```

Main mart:

```text
dwh.mart_distributor_performance
```

Key metrics:

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

## Important Business Logic

### Date Dimension

`dwh.dim_date` contains a full date spine from 2022 to 2026.

Fiscal year logic:

- Fiscal year starts in September.
- `2023-10-01` belongs to fiscal year 2023.
- `2024-01-01` belongs to fiscal year 2023.

### Employee Dimension

`dwh.dim_employees` uses a Type 2 Slowly Changing Dimension structure.

Fields added:

- `employee_key`
- `effective_from`
- `effective_to`
- `is_current`

This allows historical joins between transaction dates and employee records.

### Sales Targets

`dwh.fact_targets` only keeps records where:

```sql
is_latest = TRUE
```

This ensures each employee-month has one latest applicable target.

The full target version history remains available in:

```text
staging.stg_sales_targets_versioned
```

### Sales vs Target Mart

`dwh.mart_sales_vs_target` compares actual sales with latest targets by employee-month.

The mart includes both actual and target measures, plus gap and achievement percentage fields.

### Distributor Performance Mart

`dwh.mart_distributor_performance` summarizes distributor performance by distributor-month.

The mart focuses on fulfillment quality, delivery performance, and delivered amount performance.

## Execution

Gold SQL models can be executed using:

```bash
python 02_sql_analytics/run_sql_file.py 02_sql_analytics/gold/<model_file>.sql
```

Example:

```bash
python 02_sql_analytics/run_sql_file.py 02_sql_analytics/gold/fact_sales.sql
```

## Validation Performed

The following checks were performed during development:

- Row count checks
- Key null checks
- Duplicate grain checks
- Missing dimension key checks
- Sales target latest-version checks
- Mart-level aggregation checks

Examples:

```sql
SELECT COUNT(*)
FROM dwh.fact_sales;
```

```sql
SELECT COUNT(*)
FROM dwh.mart_sales_vs_target;
```

```sql
SELECT
    year,
    month,
    SUM(actual_revenue) AS actual_revenue,
    SUM(target_revenue) AS target_revenue,
    ROUND((SUM(actual_revenue) / NULLIF(SUM(target_revenue), 0)) * 100, 2) AS revenue_achievement_pct
FROM dwh.mart_sales_vs_target
GROUP BY year, month
ORDER BY year, month;
```

```sql
SELECT
    year,
    month,
    SUM(total_qty_ordered) AS total_qty_ordered,
    SUM(total_qty_delivered) AS total_qty_delivered,
    ROUND((SUM(total_qty_delivered) / NULLIF(SUM(total_qty_ordered), 0)) * 100, 2) AS fill_rate_pct
FROM dwh.mart_distributor_performance
GROUP BY year, month
ORDER BY year, month;
```

## Notes

- Gold tables are analytics-ready and can be connected to Power BI.
- Business aggregations are handled in mart tables.
- The next phase is to build Power BI dashboards using the Gold Layer tables.