# Additional Gold Dimensions

## Purpose

This document describes the additional dimension tables created in the Gold layer to support Power BI dashboard analysis.

The original Gold layer already included core dimensions such as date, customers, products, employees, and distributors. During the Power BI dashboard development phase, additional business analysis needs were identified, especially for revenue breakdown by sales channel and customer region.

To support a cleaner star-schema structure and more professional dashboard filtering, two additional dimensions were created:

- `dwh.dim_regions`
- `dwh.dim_channels`

---

## 1. dim_regions

### Source

`dwh.dim_customers`

### Logic

The `dim_regions` table extracts distinct combinations of customer region and province from the customer dimension.

The table supports geography-level analysis in Power BI, allowing revenue to be analyzed by region and drilled down to province.

### Table Structure

| Column | Description |
|---|---|
| geography_key | Primary key for each unique region-province combination |
| region_key | Region-level key. The value repeats across provinces within the same region |
| region | Region name |
| province | Province name |

### Business Use

This dimension supports revenue analysis by geography in Power BI, such as:

- Revenue by region
- Revenue by province
- Regional sales contribution
- Drill-down from region to province

---

## 2. dim_channels

### Source

`dwh.fact_sales`

### Logic

The `dim_channels` table extracts distinct sales channels from the sales fact table.

### Table Structure

| Column | Description |
|---|---|
| channel_key | Surrogate key for each sales channel |
| channel | Sales channel name |

### Current Channel Values

The current dataset contains three sales channels:

- E-commerce
- Modern Trade
- Traditional Trade

### Business Use

This dimension supports sales performance analysis by channel in Power BI, such as:

- Revenue by channel
- Channel contribution to total revenue
- Comparison between online and offline sales channels

---

## Power BI Usage

The additional dimensions are used to improve dashboard analysis and filtering.

Recommended relationships:

| Dimension | Related Table | Relationship |
|---|---|---|
| `dwh.dim_regions[region]` | `dwh.dim_customers[region]` | One-to-many |
| `dwh.dim_channels[channel]` | `dwh.fact_sales[channel]` | One-to-many |

For revenue breakdown by region or channel, the dashboard should use sales revenue from `dwh.fact_sales`.

Recommended measure:

```DAX
Sales Revenue =
SUM('dwh fact_sales'[net_amount])