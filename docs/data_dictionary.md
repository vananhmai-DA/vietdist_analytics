# Data Dictionary

## Project

**Project name:** VietDist Analytics  
**Database:** `vietdist_dw`  
**Architecture:** Bronze → Silver → Gold → Power BI  
**Main schemas:** `raw`, `silver`, `gold`

This data dictionary documents the main source data, Silver staging models, Gold dimension/fact/mart models, and dashboard metrics used in the VietDist Analytics project.

---

# 1. Source Data

## SRC01 — Sales Transactions

**Purpose:** Contains sales transaction records at order line-item level.

| Field / Concept | Description |
|---|---|
| `order_id` | Unique sales order identifier |
| `order_date` | Date when the sales order was created |
| `order_month` | Month number of the order |
| `order_quarter` | Quarter of the order |
| `order_year` | Year of the order |
| `customer_id` | Customer identifier |
| `product_id` | Product identifier |
| `employee_id` | Sales employee identifier |
| `region` | Sales region |
| `province` | Sales province |
| `channel` | Sales channel, such as Traditional Trade, Modern Trade, or E-commerce |
| `quantity` | Number of units sold |
| `unit_price` | Selling price per unit |
| `discount_pct` | Discount percentage |
| `discount_amount` | Discount amount applied to the order line |
| `gross_amount` | Sales amount before discount |
| `net_amount` | Sales amount after discount |
| `delivery_status` | Delivery status of the order |
| `payment_method` | Payment method |
| `payment_status` | Payment status |

---

## SRC02 — Sales Target Plan

**Purpose:** Contains revenue, quantity, and new customer targets by month and sales employee.

| Field / Concept | Description |
|---|---|
| `version_label` | Target version, such as `v1` or `v2` |
| `version_date` | Version date of the target plan |
| `effective_from` | Start date of target version effectiveness |
| `effective_to` | End date of target version effectiveness |
| `employee_id` | Sales employee identifier |
| `employee_name` | Sales employee name |
| `team` | Sales team |
| `region` | Sales region |
| `year` | Target year |
| `month` | Target month number |
| `month_col` | Original month column label, such as `T1` to `T12` |
| `target_revenue` | Revenue target |
| `target_quantity` | Quantity target |
| `target_new_customers` | New customer target |
| `is_latest` | Flag indicating the latest effective target version after Silver processing |

**Special logic:**  
Sales target data has multiple versions. All versions are preserved in Bronze and Silver. The latest effective target is used for Power BI reporting through `gold.fact_targets`.

---

## SRC03 — Customer Master

**Purpose:** Contains customer profile, channel, and geographic information.

| Field / Concept | Description |
|---|---|
| `customer_id` | Customer identifier |
| `customer_name` | Customer name |
| `customer_type` | Type or segment of customer |
| `channel` | Customer sales channel |
| `region` | Customer region |
| `province` | Customer province |
| `address` | Customer address |
| `phone` | Customer phone number |
| `tax_code` | Customer tax code |
| `join_date` | Customer join date |
| `credit_limit` | Customer credit limit |
| `status` | Customer status |

---

## SRC04 — Product Master

**Purpose:** Contains product master data.

| Field / Concept | Description |
|---|---|
| `product_id` | Product identifier |
| `product_name` | Product name |
| `category` | Product category |
| `sub_category` | Product sub-category |
| `unit` | Selling unit |
| `unit_price` | Product selling price |
| `cost_price` | Product cost price |
| `weight_gram` | Product weight in grams |
| `status` | Product status |
| `launch_date` | Product launch date |

---

## SRC05 — Distributor Orders

**Purpose:** Contains distributor order and delivery records.

| Field / Concept | Description |
|---|---|
| `order_id` | Distributor order identifier |
| `order_date` | Date when distributor order was placed |
| `order_month` | Month number of the order |
| `order_quarter` | Quarter of the order |
| `distributor_id` | Distributor identifier |
| `product_id` | Product identifier |
| `region` | Order region |
| `channel` | Order channel |
| `product_category` | Product category |
| `qty_ordered` | Quantity ordered |
| `qty_delivered` | Quantity delivered |
| `fill_rate_pct` | Source fill rate percentage |
| `unit_price_list` | Listed unit price |
| `distributor_price` | Distributor selling price |
| `gross_amount` | Gross order value |
| `delivered_amount` | Value of delivered goods |
| `expected_delivery_date` | Expected delivery date |
| `actual_delivery_date` | Actual delivery date |
| `on_time_delivery` | Source flag indicating whether delivery was on time |
| `delivery_status` | Delivery status |
| `payment_terms` | Payment terms |

---

## SRC06 — Distributor Master

**Purpose:** Contains distributor master data.

| Field / Concept | Description |
|---|---|
| `distributor_id` | Distributor identifier |
| `distributor_name` | Distributor name |
| `tier` | Distributor tier |
| `channel` | Distributor channel |
| `province` | Distributor province |
| `region` | Distributor region |
| `contact_person` | Distributor contact person |
| `phone` | Distributor phone number |
| `email` | Distributor email |
| `tax_code` | Distributor tax code |
| `join_date` | Distributor join date |
| `credit_limit` | Distributor credit limit |
| `status` | Distributor status |
| `assigned_supervisor_id` | Supervisor responsible for distributor |

---

## SRC07 — Employee Master

**Purpose:** Contains sales employee information and effective-date history.

| Field / Concept | Description |
|---|---|
| `employee_id` | Employee identifier |
| `full_name` | Employee full name |
| `gender` | Employee gender |
| `date_of_birth` | Employee date of birth |
| `join_date` | Employee join date |
| `position` | Employee position |
| `region` | Employee assigned region |
| `team` | Employee assigned team |
| `email` | Employee email |
| `phone` | Employee phone number |
| `status` | Employee status |
| `version` | Employee record version |
| `effective_date` | Effective date of employee record |
| `resign_date` | Resignation date, if any |
| `transfer_note` | Transfer or change note |

---

## SRC08 — Territory Mapping

**Purpose:** Maps sales employees to territories and customers.

| Field / Concept | Description |
|---|---|
| `territory_id` | Territory identifier |
| `employee_id` | Sales employee identifier |
| `customer_id` | Customer identifier |
| `region` | Assigned region |
| `team` | Sales team |
| `effective_date` | Effective date of territory assignment |
| `expiry_date` | Expiry date of territory assignment |
| `version` | Mapping version |

---

## SRC09 — Return Transactions

**Purpose:** Contains product return records.

| Field / Concept | Description |
|---|---|
| `return_id` | Return transaction identifier |
| `original_order_id` | Original sales order identifier |
| `return_date` | Return date |
| `return_month` | Return month |
| `customer_id` | Customer identifier |
| `employee_id` | Sales employee identifier |
| `product_id` | Product identifier |
| `region` | Return region |
| `province` | Return province |
| `return_quantity` | Returned quantity |
| `unit_price` | Unit price of returned product |
| `return_amount` | Return amount |
| `return_reason` | Reason for return |
| `status` | Return status |

---

## SRC10 — Promotion Program

**Purpose:** Contains promotion program information.

| Field / Concept | Description |
|---|---|
| `promotion_id` | Promotion identifier |
| `promotion_name` | Promotion name |
| `promotion_type` | Promotion type |
| `target_channel` | Channel where promotion is applied |
| `target_region` | Region where promotion is applied |
| `start_date` | Promotion start date |
| `end_date` | Promotion end date |
| `applicable_products` | Products where the promotion applies |
| `discount_pct` | Promotion discount percentage |
| `min_order_quantity` | Minimum order quantity for promotion |
| `budget_vnd` | Promotion budget |
| `actual_cost_vnd` | Actual promotion cost |
| `status` | Promotion status |
| `created_by` | Person or team that created the promotion |

---

# 2. Silver Layer Models

Silver models are cleaned, typed, standardized, deduplicated, and validated staging models created by dbt.

Silver schema:

```text
silver
```

## Silver Models

| Silver Model | Source Table | Purpose |
|---|---|---|
| `silver.stg_sales_transactions` | `raw.sales_transactions` | Clean sales transaction data |
| `silver.stg_customers` | `raw.customer_master` | Clean customer master data |
| `silver.stg_products` | `raw.product_master` | Clean product master data |
| `silver.stg_distributors` | `raw.distributor_master` | Clean distributor master data |
| `silver.stg_employees` | `raw.employee_master` | Clean employee master data with effective-date history |
| `silver.stg_territory_mapping` | `raw.territory_mapping` | Clean employee-customer-territory mapping |
| `silver.stg_return_transactions` | `raw.return_transactions` | Clean return transaction data |
| `silver.stg_promotion_program` | `raw.promotion_program` | Clean promotion program data |
| `silver.stg_distributor_orders` | `raw.distributor_orders` | Clean distributor order data |
| `silver.stg_sales_targets_versioned` | `raw.sales_targets_raw` | Clean and version sales target data |

## Common Silver Metadata

| Column | Description |
|---|---|
| `_source_file` | Original file name |
| `_source_platform` | Source platform |
| `_ingested_at` | Bronze ingestion timestamp |
| `_batch_id` | Bronze ingestion batch ID |
| `_processed_at` | Silver processing timestamp |

---

# 3. Gold Dimension Tables

Gold models are analytics-ready tables created by dbt under the `gold` schema.

## gold.dim_dates

**Purpose:** Calendar dimension for time-based analysis.

| Column | Description |
|---|---|
| `date_key` | Date key in `YYYYMMDD` format |
| `date_day` | Calendar date |
| `calendar_year` | Calendar year |
| `calendar_quarter` | Calendar quarter |
| `month_number` | Month number |
| `month_name` | Month name |
| `day_of_month` | Day of month |
| `day_of_week` | ISO day of week |
| `day_name` | Day name |
| `week_of_year` | Week number |
| `fiscal_year` | Fiscal year |
| `fiscal_quarter` | Fiscal quarter |
| `is_weekend` | Weekend flag |

---

## gold.dim_customers

**Purpose:** Customer dimension with credit tier logic.

| Column | Description |
|---|---|
| `customer_key` | Customer business key used for joins |
| `customer_id` | Original customer identifier |
| `customer_name` | Customer name |
| `customer_type` | Customer type |
| `channel` | Customer sales channel |
| `province` | Customer province |
| `region` | Customer region |
| `address` | Customer address |
| `phone` | Customer phone |
| `tax_code` | Customer tax code |
| `join_date` | Customer join date |
| `credit_limit` | Customer credit limit |
| `status` | Customer status |
| `credit_limit_tier` | Derived customer credit tier |

---

## gold.dim_products

**Purpose:** Product dimension with unit margin metrics.

| Column | Description |
|---|---|
| `product_key` | Product business key used for joins |
| `product_id` | Original product identifier |
| `product_name` | Product name |
| `category` | Product category |
| `sub_category` | Product sub-category |
| `unit` | Product selling unit |
| `unit_price` | Product unit price |
| `cost_price` | Product cost price |
| `weight_gram` | Product weight in grams |
| `status` | Product status |
| `launch_date` | Product launch date |
| `unit_margin` | `unit_price - cost_price` |
| `unit_margin_pct` | Unit margin divided by unit price |

---

## gold.dim_distributors

**Purpose:** Distributor dimension with credit tier logic.

| Column | Description |
|---|---|
| `distributor_key` | Distributor business key used for joins |
| `distributor_id` | Original distributor identifier |
| `distributor_name` | Distributor name |
| `tier` | Distributor tier |
| `channel` | Distributor channel |
| `province` | Distributor province |
| `region` | Distributor region |
| `contact_person` | Distributor contact person |
| `phone` | Distributor phone |
| `email` | Distributor email |
| `tax_code` | Distributor tax code |
| `join_date` | Distributor join date |
| `credit_limit` | Distributor credit limit |
| `status` | Distributor status |
| `assigned_supervisor_id` | Supervisor responsible for distributor |
| `credit_limit_tier` | Derived distributor credit tier |

---

## gold.dim_employees

**Purpose:** Employee dimension with effective-date history.

| Column | Description |
|---|---|
| `employee_key` | Historical employee key generated from employee ID and effective date |
| `employee_id` | Original employee identifier |
| `full_name` | Employee full name |
| `gender` | Employee gender |
| `date_of_birth` | Employee date of birth |
| `join_date` | Employee join date |
| `position` | Employee position |
| `region` | Employee assigned region |
| `team` | Employee assigned team |
| `email` | Employee email |
| `phone` | Employee phone |
| `status` | Employee status |
| `version` | Employee record version |
| `effective_from` | Start date of employee record |
| `effective_to` | End date of employee record |
| `is_current` | Current employee record flag |
| `resign_date` | Employee resignation date |
| `transfer_note` | Transfer or change note |

---

## gold.dim_channels

**Purpose:** Channel dimension for sales and distributor analysis.

| Column | Description |
|---|---|
| `channel_key` | Channel key |
| `channel` | Channel name |

Current channel values may include:

- E-commerce
- Modern Trade
- Traditional Trade

---

## gold.dim_regions

**Purpose:** Region-level dimension.

| Column | Description |
|---|---|
| `region_key` | Region key |
| `region` | Region name |

---

## gold.dim_geography

**Purpose:** Geography dimension for region and province drill-down.

| Column | Description |
|---|---|
| `geography_key` | Geography key |
| `region_key` | Region-level key |
| `region` | Region name |
| `province` | Province name |

---

# 4. Gold Fact Tables

## gold.fact_sales

**Purpose:** Sales transaction fact table at order line-item grain.

**Grain:** One row per `order_id` and `product_id`.

| Column | Description |
|---|---|
| `sales_line_key` | Unique fact row key generated from `order_id` and `product_id` |
| `order_id` | Sales order identifier |
| `order_date_key` | Date key for order date |
| `customer_key` | Customer key |
| `product_key` | Product key |
| `employee_key` | Employee key |
| `channel_key` | Channel key |
| `geography_key` | Geography key |
| `order_date` | Sales order date |
| `customer_id` | Original customer identifier |
| `employee_id` | Original employee identifier |
| `product_id` | Original product identifier |
| `region` | Sales region |
| `province` | Sales province |
| `channel` | Sales channel |
| `quantity` | Units sold |
| `unit_price` | Selling price per unit |
| `discount_pct` | Discount percentage |
| `discount_amount` | Discount amount |
| `gross_amount` | Revenue before discount |
| `net_amount` | Revenue after discount |
| `total_cost` | Total cost, calculated from quantity and product cost price |
| `gross_profit` | Net revenue minus total cost |
| `gross_profit_margin_pct` | Gross profit divided by net revenue |

---

## gold.fact_returns

**Purpose:** Product return fact table.

**Grain:** One row per `return_id`.

| Column | Description |
|---|---|
| `return_id` | Return identifier |
| `original_order_id` | Original order identifier |
| `return_date_key` | Date key for return date |
| `customer_key` | Customer key |
| `product_key` | Product key |
| `employee_key` | Employee key |
| `geography_key` | Geography key |
| `return_date` | Return date |
| `customer_id` | Original customer identifier |
| `employee_id` | Original employee identifier |
| `product_id` | Original product identifier |
| `region` | Return region |
| `province` | Return province |
| `return_quantity` | Returned quantity |
| `unit_price` | Unit price |
| `return_amount` | Return amount |
| `return_reason` | Reason for return |
| `return_cost_amount` | Estimated cost of returned goods |
| `return_margin_impact` | Estimated gross margin impact |

---

## gold.fact_distributor_orders

**Purpose:** Distributor fulfillment fact table.

**Grain:** One row per `order_id`, `distributor_id`, and `product_id`.

| Column | Description |
|---|---|
| `distributor_order_line_key` | Unique fact row key |
| `order_id` | Distributor order identifier |
| `order_date_key` | Date key for order date |
| `expected_delivery_date_key` | Date key for expected delivery date |
| `actual_delivery_date_key` | Date key for actual delivery date |
| `distributor_key` | Distributor key |
| `product_key` | Product key |
| `channel_key` | Channel key |
| `geography_key` | Geography key |
| `order_date` | Distributor order date |
| `distributor_id` | Original distributor identifier |
| `product_id` | Original product identifier |
| `region` | Order region |
| `channel` | Order channel |
| `qty_ordered` | Quantity ordered |
| `qty_delivered` | Quantity delivered |
| `fill_rate_pct` | Source fill rate percentage |
| `unit_price_list` | Listed unit price |
| `distributor_price` | Distributor price |
| `gross_amount` | Gross order value |
| `delivered_amount` | Delivered order amount |
| `calculated_fill_rate_pct` | Recalculated delivered quantity divided by ordered quantity |
| `calculated_on_time_delivery` | Recalculated on-time delivery flag |

---

## gold.fact_targets

**Purpose:** Latest sales target fact table.

**Grain:** One row per employee and target month for the latest applicable target version.

| Column | Description |
|---|---|
| `target_key` | Unique target row key generated from employee and target month |
| `target_date_key` | Date key for target month |
| `employee_key` | Employee key |
| `employee_id` | Employee identifier |
| `employee_name` | Employee name |
| `target_year` | Target year |
| `target_month` | Target month |
| `month_col` | Original month label |
| `target_month_date` | First day of target month |
| `version_label` | Target version label |
| `version_rank` | Numeric version rank |
| `version_date` | Version date |
| `effective_from` | Version effective start date |
| `effective_to` | Version effective end date |
| `is_latest` | Latest target flag |
| `region` | Sales region |
| `team` | Sales team |
| `target_revenue` | Revenue target |
| `target_quantity` | Quantity target |
| `target_new_customers` | New customer target |

---

# 5. Gold Mart Tables

## gold.mart_sales_vs_target

**Purpose:** Main mart for Power BI sales target performance analysis.

**Grain:** One row per employee and month.

| Column | Description |
|---|---|
| `employee_id` | Employee identifier |
| `employee_name` | Employee name |
| `month_date` | First day of reporting month |
| `year` | Reporting year |
| `month` | Reporting month |
| `region` | Sales region |
| `team` | Sales team |
| `version_label` | Target version used |
| `total_orders` | Number of sales orders |
| `active_customers` | Number of active customers |
| `actual_quantity` | Actual units sold |
| `target_quantity` | Target units |
| `quantity_gap` | Actual quantity minus target quantity |
| `quantity_achievement_pct` | Actual quantity divided by target quantity |
| `actual_revenue` | Actual net revenue |
| `target_revenue` | Revenue target |
| `revenue_gap` | Actual revenue minus target revenue |
| `revenue_achievement_pct` | Actual revenue divided by target revenue |
| `actual_total_cost` | Actual total cost |
| `actual_gross_profit` | Actual gross profit |
| `actual_gross_profit_margin_pct` | Actual gross profit divided by actual revenue |
| `target_new_customers` | Target new customers |

---

## gold.mart_distributor_performance

**Purpose:** Main mart for Power BI distributor fulfillment analysis.

**Grain:** One row per distributor, month, order region, and order channel.

| Column | Description |
|---|---|
| `distributor_id` | Distributor identifier |
| `distributor_name` | Distributor name |
| `tier` | Distributor tier |
| `distributor_channel` | Distributor channel |
| `province` | Distributor province |
| `distributor_region` | Distributor region |
| `month_date` | First day of reporting month |
| `year` | Reporting year |
| `month` | Reporting month |
| `order_region` | Order region |
| `order_channel` | Order channel |
| `total_orders` | Number of distinct distributor orders |
| `products_ordered` | Number of distinct products ordered |
| `total_qty_ordered` | Total quantity ordered |
| `total_qty_delivered` | Total quantity delivered |
| `fill_rate_pct` | Quantity delivered divided by quantity ordered |
| `total_gross_amount` | Gross order value |
| `total_delivered_amount` | Delivered amount |
| `delivered_amount_rate_pct` | Delivered amount divided by gross amount |
| `on_time_delivery_count` | Number of on-time delivery records |
| `late_delivery_count` | Number of late delivery records |
| `delivery_record_count` | Number of delivery records |
| `on_time_delivery_rate_pct` | On-time deliveries divided by delivery records |

---

# 6. Main Power BI Measures

## Sales Measures

| Measure | Definition |
|---|---|
| Total Actual Revenue | Sum of `actual_revenue` |
| Total Target Revenue | Sum of `target_revenue` |
| Revenue Gap | Actual revenue minus target revenue |
| Revenue Achievement % | Actual revenue divided by target revenue |
| Total Units Sold | Sum of `actual_quantity` |
| Target Units | Sum of `target_quantity` |
| Units Gap | Actual units minus target units |
| Units Achievement % | Actual units divided by target units |
| Gross Profit | Sum of `actual_gross_profit` |
| Gross Profit Margin % | Gross profit divided by actual revenue |
| Active Customers | Number of active customers |

---

## Distributor Measures

| Measure | Definition |
|---|---|
| Distributor Orders | Count of distributor order records or distinct distributor orders |
| Gross Order Value | Sum of `total_gross_amount` |
| Delivered Revenue | Sum of `total_delivered_amount` |
| Quantity Fill Rate | Quantity delivered divided by quantity ordered |
| Delivered Amount Rate | Delivered amount divided by gross order value |
| On-time Delivery Rate | On-time deliveries divided by delivery records |
| Late Delivery Count | Number of late deliveries |
| Revenue Contribution | Distributor delivered revenue divided by total delivered revenue |

---

# 7. Dashboard Pages

## Page 1 — Overview

Shows:

- Revenue target achievement
- Actual revenue
- Gross profit
- Gross profit margin
- Active customers
- Units sold
- Revenue by region
- Revenue by channel
- Revenue and margin trend

---

## Page 2 — Sales Performance

Shows:

- Revenue vs target by month
- Revenue target performance by region
- Channel performance
- Sales employee performance detail
- Top and bottom employee ranking

---

## Page 3 — Distributor Analysis

Shows:

- Distributor order value and delivered revenue
- Quantity fill rate
- On-time delivery rate
- Regional fulfillment performance
- Late delivery by channel
- Distributor action priority