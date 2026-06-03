# Additional Gold Dimensions

## Purpose

This document describes additional Gold dimension tables created to support Power BI dashboard analysis.

The additional dimensions are:

- `gold.dim_regions`
- `gold.dim_geography`
- `gold.dim_channels`

These dimensions were added to improve dashboard filtering, drill-down, and business analysis by region, geography, and channel.

---

## Why These Dimensions Were Added

The core Gold model already includes main dimensions such as:

- `gold.dim_dates`
- `gold.dim_customers`
- `gold.dim_products`
- `gold.dim_employees`
- `gold.dim_distributors`

However, Power BI analysis also requires cleaner navigation by:

- Region
- Province
- Sales channel
- Distributor channel

Therefore, additional dimensions were created to support more flexible dashboard slicing and drill-down.

---

## Modeling Approach

In the dbt Gold implementation, these dimensions are built from cleaned Silver models instead of old `dwh` tables.

This design avoids circular dependencies.

For example, `dim_channels` should not be built from `fact_sales`, because fact tables are built after dimension tables. Instead, channel values are collected from cleaned Silver sources first.

Current flow:

```text
Silver models
    ↓
Additional Gold dimensions
    ↓
Gold fact tables
    ↓
Power BI dashboard
```

---

# 1. `gold.dim_regions`

## Purpose

`gold.dim_regions` provides one row per region.

This dimension supports high-level region filtering and region-level analysis in Power BI.

---

## Source Models

`gold.dim_regions` is built from distinct region values across multiple Silver models:

- `silver.stg_customers`
- `silver.stg_distributors`
- `silver.stg_sales_transactions`
- `silver.stg_distributor_orders`
- `silver.stg_return_transactions`
- `silver.stg_territory_mapping`
- `silver.stg_employees`

Using multiple sources makes the region dimension more complete than taking region only from customers.

---

## Logic

The model:

- Extracts distinct region values from relevant Silver models
- Converts missing region values to `Unknown`
- Generates a numeric `region_key`
- Keeps one row per region

---

## Table Structure

| Column | Description |
|---|---|
| `region_key` | Region key used for analytics joins and filtering |
| `region` | Region name |

---

## Business Use

This dimension supports:

- Revenue by region
- Target achievement by region
- Distributor fulfillment by region
- Employee/team analysis by region
- Power BI slicers and filters

Examples of dashboard use:

- Compare revenue achievement across regions
- Identify which region contributes most to revenue gap
- Filter distributor performance by region

---

# 2. `gold.dim_geography`

## Purpose

`gold.dim_geography` provides region-province combinations.

This dimension supports geographic drill-down from region to province.

---

## Source Models

`gold.dim_geography` is built from distinct `region` and `province` combinations across Silver models that contain geographic information:

- `silver.stg_customers`
- `silver.stg_distributors`
- `silver.stg_sales_transactions`
- `silver.stg_return_transactions`

---

## Logic

The model:

- Extracts distinct region-province combinations
- Converts missing region or province values to `Unknown`
- Generates `geography_key`
- Generates `region_key` using region ranking
- Keeps one row per unique region-province combination

---

## Table Structure

| Column | Description |
|---|---|
| `geography_key` | Geography key for each unique region-province combination |
| `region_key` | Region-level key, repeated across provinces within the same region |
| `region` | Region name |
| `province` | Province name |

---

## Business Use

This dimension supports deeper geographic analysis in Power BI, such as:

- Revenue by region
- Revenue by province
- Drill-down from region to province
- Return analysis by province
- Distributor/customer geography filtering

Examples of dashboard use:

- Start from regional revenue gap
- Drill down into provinces inside the underperforming region
- Identify whether a revenue problem is broad across the region or concentrated in specific provinces

---

# 3. `gold.dim_channels`

## Purpose

`gold.dim_channels` provides one row per sales or distribution channel.

This dimension supports channel-level analysis in Power BI.

---

## Source Models

`gold.dim_channels` is built from distinct channel values across multiple Silver models:

- `silver.stg_sales_transactions`
- `silver.stg_customers`
- `silver.stg_distributors`
- `silver.stg_distributor_orders`

Using multiple Silver sources ensures that both sales channels and distributor channels are captured.

---

## Logic

The model:

- Extracts distinct channel values from relevant Silver models
- Converts missing channel values to `Unknown`
- Generates a numeric `channel_key`
- Keeps one row per channel

---

## Table Structure

| Column | Description |
|---|---|
| `channel_key` | Channel key used for analytics joins and filtering |
| `channel` | Sales or distribution channel name |

---

## Current Channel Values

The current dataset contains channel values such as:

- E-commerce
- Modern Trade
- Traditional Trade

Additional values may appear if future source files include new channels.

---

## Business Use

This dimension supports:

- Revenue by channel
- Gross profit by channel
- Channel contribution analysis
- Distributor order analysis by channel
- Power BI slicers and filters

Important note:

Sales targets are not allocated by channel. Therefore, channel charts should be used to analyze actual revenue and profit contribution, not channel-level target achievement.

---

## Relationship to Fact Tables

These additional dimensions can support relationships with Gold fact tables.

Typical relationships:

```text
gold.fact_sales[channel_key] → gold.dim_channels[channel_key]
gold.fact_sales[geography_key] → gold.dim_geography[geography_key]

gold.fact_distributor_orders[channel_key] → gold.dim_channels[channel_key]
gold.fact_distributor_orders[geography_key] → gold.dim_geography[geography_key]
```

`gold.dim_regions` can be used for filtering and reporting where region-level analysis is needed.

---

## dbt Implementation Notes

The additional dimension models are stored under:

```text
02_sql_analytics/dbt/models/gold/
```

Model files:

```text
dim_regions.sql
dim_geography.sql
dim_channels.sql
```

They are tested in:

```text
02_sql_analytics/dbt/models/gold/schema.yml
```

The tests include:

- Not-null checks for keys
- Unique checks for dimension keys
- Unique checks for region or channel values where appropriate

---

## Notes

- These dimensions are part of the dbt Gold Layer.
- They replace the old `dwh`-based dimension logic.
- They are built from Silver models, not from Gold facts.
- This avoids circular dependencies and keeps the Gold build order clean.
- The dimensions improve Power BI usability by supporting slicers, filters, and drill-down paths.