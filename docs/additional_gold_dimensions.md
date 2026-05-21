# Additional Gold Dimensions

## Purpose

This document describes additional Gold dimension tables created to support Power BI dashboard analysis.

The additional dimensions are:

- `dwh.dim_regions`
- `dwh.dim_geography`
- `dwh.dim_channels`

---

## 1. dim_regions

### Source

`dwh.dim_customers`

### Logic

The `dim_regions` table extracts distinct customer regions from the customer dimension.

This table contains one row per region.

### Table Structure

| Column | Description |
|---|---|
| region_key | Primary key for each region |
| region | Region name |

### Business Use

This dimension supports high-level revenue analysis by region, especially for tables that only contain region-level information, such as `mart_sales_vs_target`.

---

## 2. dim_geography

### Source

`dwh.dim_customers`

### Logic

The `dim_geography` table extracts distinct combinations of region and province from the customer dimension.

This table supports geographic drill-down analysis from region to province.

### Table Structure

| Column | Description |
|---|---|
| geography_key | Primary key for each unique region-province combination |
| region_key | Region-level key, repeated across provinces within the same region |
| region | Region name |
| province | Province name |

### Business Use

This dimension supports deeper geographic analysis in Power BI, such as:

- Revenue by region
- Revenue by province
- Drill-down from region to province

---

## 3. dim_channels

### Source

`dwh.fact_sales`

### Logic

The `dim_channels` table extracts distinct sales channels from the sales fact table.

### Table Structure

| Column | Description |
|---|---|
| channel_key | Primary key for each sales channel |
| channel | Sales channel name |

### Current Channel Values

The current dataset contains three sales channels:

- E-commerce
- Modern Trade
- Traditional Trade

### Business Use

This dimension supports sales performance analysis by channel in Power BI.