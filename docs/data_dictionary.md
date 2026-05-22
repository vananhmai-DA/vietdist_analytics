# Data Dictionary

## Project

**Project name:** VietDist Analytics  
**Database:** `vietdist_dw`  
**Architecture:** Bronze → Silver → Gold → Power BI  
**Main schemas:** `raw`, `staging`, `dwh`

This data dictionary documents the main source tables, transformed tables, business fields, and dashboard metrics used in the VietDist Analytics project.

---

# 1. Source Data

## SRC01 — Sales Transactions

**Purpose:** Contains sales transaction records at order line-item level.

| Field / Concept | Description |
|---|---|
| order_id | Unique sales order identifier |
| order_date | Date when the sales order was created |
| customer_id | Customer identifier |
| product_id | Product identifier |
| employee_id | Sales employee identifier |
| region | Sales region |
| province | Customer or sales province |
| channel | Sales channel, such as Traditional Trade, Modern Trade, or E-commerce |
| quantity | Number of units sold |
| unit_price | Selling price per unit |
| discount_amount | Discount amount applied to the order line |
| gross_amount | Sales amount before discount |
| net_amount | Sales amount after discount |
| total_cost | Cost of goods sold for the order line |
| gross_profit | Gross profit amount |
| gross_profit_margin_pct | Gross profit margin percentage |

---

## SRC02 — Sales Target Plan

**Purpose:** Contains revenue and quantity targets by month and sales employee.

| Field / Concept | Description |
|---|---|
| version_label | Target version, such as v1 or v2 |
| employee_id | Sales employee identifier |
| employee_name | Sales employee name |
| team | Sales team |
| region | Sales region |
| month | Target month |
| target_revenue | Revenue target |
| target_quantity | Quantity target |
| target_new_customers | New customer target |
| is_latest | Flag indicating the latest effective target version |

**Special logic:**  
Sales target data has multiple versions. The latest effective target is used for Power BI reporting.

---

## SRC03 — Customer Master

**Purpose:** Contains customer profile and geographic information.

| Field / Concept | Description |
|---|---|
| customer_id | Customer identifier |
| customer_name | Customer name |
| customer_type | Type or segment of customer |
| region | Customer region |
| province | Customer province |
| join_date | Customer join date |
| status | Customer status |

---

## SRC04 — Product Master

**Purpose:** Contains product master data.

| Field / Concept | Description |
|---|---|
| product_id | Product identifier |
| product_name | Product name |
| category | Product category |
| cost_price | Product cost price |
| launch_date | Product launch date |

---

## SRC05 — Distributor Orders

**Purpose:** Contains distributor order and delivery records.

| Field / Concept | Description |
|---|---|
| distributor_id | Distributor identifier |
| distributor_name | Distributor name |
| product_id | Product identifier |
| order_date | Date when distributor order was placed |
| expected_delivery_date | Expected delivery date |
| actual_delivery_date | Actual delivery date |
| quantity_ordered | Quantity ordered |
| quantity_delivered | Quantity delivered |
| gross_amount | Gross order value |
| delivered_amount | Value of delivered goods |
| fill_rate_pct | Quantity delivered divided by quantity ordered |
| on_time_delivery | Flag indicating whether delivery was on time |

---

## SRC06 — Distributor Master

**Purpose:** Contains distributor master data.

| Field / Concept | Description |
|---|---|
| distributor_id | Distributor identifier |
| distributor_name | Distributor name |
| region | Distributor region |
| channel | Distributor channel |
| credit_limit | Distributor credit limit |
| credit_limit_tier | Credit tier |
| assigned_supervisor_id | Supervisor responsible for distributor |

---

## SRC07 — Employee Master

**Purpose:** Contains sales employee information.

| Field / Concept | Description |
|---|---|
| employee_id | Employee identifier |
| employee_name | Employee name |
| email | Employee email |
| date_of_birth | Date of birth |
| effective_from | Start date of employee record |
| effective_to | End date of employee record |
| is_current | Current employee record flag |

---

## SRC08 — Territory Mapping

**Purpose:** Maps sales employees to regions, provinces, customers, or territories.

| Field / Concept | Description |
|---|---|
| employee_id | Sales employee identifier |
| customer_id | Customer identifier |
| region | Assigned region |
| province | Assigned province |
| team | Sales team |

---

## SRC09 — Return Transactions

**Purpose:** Contains product return records.

| Field / Concept | Description |
|---|---|
| return_id | Return transaction identifier |
| return_date | Return date |
| original_order_id | Original sales order identifier |
| customer_id | Customer identifier |
| product_id | Product identifier |
| employee_id | Sales employee identifier |
| return_quantity | Returned quantity |
| return_amount | Returned amount |
| return_reason | Reason for return |
| return_margin_impact | Estimated impact on margin |

---

## SRC10 — Promotion Program

**Purpose:** Contains promotion program information.

| Field / Concept | Description |
|---|---|
| promotion_id | Promotion identifier |
| promotion_name | Promotion name |
| start_date | Promotion start date |
| end_date | Promotion end date |
| discount_type | Type of promotion or discount |
| discount_value | Promotion discount value |
| product_id | Product linked to promotion |
| channel | Channel where promotion is applied |

---

# 2. Gold Layer Tables

## dwh.dim_date

**Purpose:** Calendar dimension for time-based analysis.

| Column | Description |
|---|---|
| date_key | Date surrogate key |
| date_day | Calendar date |
| calendar_year | Calendar year |
| calendar_quarter | Calendar quarter |
| month_number | Month number |
| month_name | Month name |
| day_of_month | Day of month |
| day_of_week | Day of week |
| day_name | Day name |
| week_of_year | Week number |
| fiscal_year | Fiscal year |
| fiscal_quarter | Fiscal quarter |
| is_weekend | Weekend flag |

---

## dwh.dim_customers

**Purpose:** Customer dimension.

| Column | Description |
|---|---|
| customer_key | Customer surrogate key |
| customer_id | Customer business identifier |
| customer_name | Customer name |
| customer_type | Customer type |
| region | Customer region |
| province | Customer province |
| join_date | Customer join date |
| status | Customer status |

---

## dwh.dim_products

**Purpose:** Product dimension.

| Column | Description |
|---|---|
| product_key | Product surrogate key |
| product_id | Product business identifier |
| product_name | Product name |
| category | Product category |
| cost_price | Product cost |
| launch_date | Product launch date |

---

## dwh.dim_employees

**Purpose:** Employee dimension with SCD Type 2 structure.

| Column | Description |
|---|---|
| employee_key | Employee surrogate key |
| employee_id | Employee business identifier |
| employee_name | Employee name |
| email | Employee email |
| effective_from | Record effective start date |
| effective_to | Record effective end date |
| is_current | Flag for current employee record |

---

## dwh.dim_distributors

**Purpose:** Distributor dimension.

| Column | Description |
|---|---|
| distributor_key | Distributor surrogate key |
| distributor_id | Distributor business identifier |
| distributor_name | Distributor name |
| distributor_region | Distributor region |
| distributor_channel | Distributor channel |
| credit_limit | Distributor credit limit |
| credit_limit_tier | Distributor credit tier |
| contact_person | Distributor contact person |

---

## dwh.dim_regions

**Purpose:** Region-level dimension for sales target analysis.

| Column | Description |
|---|---|
| region_key | Region surrogate key |
| region | Region name |

---

## dwh.dim_channels

**Purpose:** Channel-level dimension for actual sales analysis.

| Column | Description |
|---|---|
| channel_key | Channel surrogate key |
| channel | Sales channel name |

Current channel values:
- E-commerce
- Modern Trade
- Traditional Trade

---

## dwh.dim_geography

**Purpose:** Geography dimension for region and province drill-down analysis.

| Column | Description |
|---|---|
| geography_key | Geography surrogate key |
| region_key | Region-level key |
| region | Region name |
| province | Province name |

---

# 3. Fact Tables

## dwh.fact_sales

**Purpose:** Sales transaction fact table at order line-item grain.

| Column | Description |
|---|---|
| order_id | Sales order identifier |
| order_date_key | Date key for order date |
| customer_key | Customer key |
| product_key | Product key |
| employee_key | Employee key |
| channel | Sales channel |
| region | Sales region |
| province | Sales province |
| quantity | Units sold |
| unit_price | Selling price per unit |
| discount_amount | Discount amount |
| gross_amount | Revenue before discount |
| net_amount | Revenue after discount |
| total_cost | Total cost |
| gross_profit | Gross profit |
| gross_profit_margin_pct | Gross profit margin percentage |

---

## dwh.fact_targets

**Purpose:** Sales target fact table.

| Column | Description |
|---|---|
| target_date_key | Target month date key |
| employee_key | Employee key |
| employee_id | Employee business identifier |
| employee_name | Employee name |
| region | Sales region |
| team | Sales team |
| target_revenue | Revenue target |
| target_quantity | Quantity target |
| target_new_customers | New customer target |
| version_label | Target version |
| is_latest | Latest target flag |

---

## dwh.fact_returns

**Purpose:** Product return fact table.

| Column | Description |
|---|---|
| return_id | Return identifier |
| return_date_key | Return date key |
| original_order_id | Original order identifier |
| customer_key | Customer key |
| product_key | Product key |
| employee_key | Employee key |
| return_quantity | Returned quantity |
| return_amount | Returned amount |
| return_reason | Reason for return |
| return_margin_impact | Margin impact from return |

---

## dwh.fact_distributor_orders

**Purpose:** Distributor fulfillment fact table.

| Column | Description |
|---|---|
| distributor_key | Distributor key |
| product_key | Product key |
| order_date_key | Order date key |
| actual_delivery_date_key | Actual delivery date key |
| quantity_ordered | Quantity ordered |
| quantity_delivered | Quantity delivered |
| gross_amount | Gross order value |
| delivered_amount | Delivered revenue |
| calculated_fill_rate_pct | Quantity delivered divided by quantity ordered |
| calculated_on_time_delivery | On-time delivery flag |

---

# 4. Mart Tables

## dwh.mart_sales_vs_target

**Purpose:** Main mart for Power BI sales target performance analysis.

| Column | Description |
|---|---|
| year | Calendar year |
| month | Month number |
| month_date | Month date |
| region | Sales region |
| team | Sales team |
| employee_id | Employee identifier |
| employee_name | Employee name |
| actual_revenue | Actual revenue |
| target_revenue | Revenue target |
| revenue_gap | Actual revenue minus target revenue |
| revenue_achievement_pct | Actual revenue divided by target revenue |
| actual_quantity | Actual units sold |
| target_quantity | Target units |
| quantity_gap | Actual quantity minus target quantity |
| quantity_achievement_pct | Actual quantity divided by target quantity |
| active_customers | Number of active customers |
| total_orders | Total sales orders |
| actual_gross_profit | Actual gross profit |
| actual_gross_profit_margin_pct | Actual gross profit margin percentage |
| version_label | Target version used |

---

## dwh.mart_distributor_performance

**Purpose:** Main mart for Power BI distributor fulfillment analysis.

| Column | Description |
|---|---|
| month | Month number |
| month_date | Month date |
| distributor_id | Distributor identifier |
| distributor_name | Distributor name |
| distributor_region | Distributor region |
| distributor_channel | Distributor channel |
| total_qty_ordered | Total quantity ordered |
| total_qty_delivered | Total quantity delivered |
| fill_rate_pct | Quantity fill rate |
| total_gross_amount | Gross order value |
| total_delivered_amount | Delivered revenue |
| delivered_amount_rate_pct | Delivered amount divided by gross amount |
| delivery_record_count | Number of delivery records |
| late_delivery_count | Number of late deliveries |
| on_time_delivery_count | Number of on-time deliveries |
| on_time_delivery_rate_pct | On-time delivery rate |

---

# 5. Main Power BI Measures

## Sales Measures

| Measure | Definition |
|---|---|
| Total Actual Revenue | Sum of actual revenue |
| Total Target Revenue | Sum of target revenue |
| Revenue Gap | Actual revenue minus target revenue |
| Revenue Achievement % | Actual revenue divided by target revenue |
| Total Units Sold | Sum of actual quantity |
| Target Units | Sum of target quantity |
| Units Gap | Actual units minus target units |
| Units Achievement % | Actual units divided by target units |
| Gross Profit | Sum of gross profit |
| Gross Profit Margin % | Gross profit divided by actual revenue |
| Active Customers | Number of active customers |

---

## Distributor Measures

| Measure | Definition |
|---|---|
| Distributor Orders | Number of distributor order records |
| Gross Order Value | Sum of gross order value |
| Delivered Revenue | Sum of delivered amount |
| Quantity Fill Rate | Quantity delivered divided by quantity ordered |
| On-time Delivery Rate | On-time deliveries divided by total delivery records |
| Late Delivery Count | Number of late deliveries |
| Revenue Contribution | Distributor delivered revenue divided by total delivered revenue |

---

# 6. Dashboard Pages

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
- Top / Bottom employee ranking

---

## Page 3 — Distributor Analysis

Shows:
- Distributor order value and delivered revenue
- Quantity fill rate
- On-time delivery rate
- Regional fulfillment performance
- Late delivery by channel
- Distributor action priority