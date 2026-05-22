# Assumptions Log

## Project

**Project name:** VietDist Analytics  
**Purpose:** Document assumptions made during data ingestion, transformation, modeling, and dashboard development.

This file records the key assumptions used in the VietDist Analytics project. These assumptions help reviewers understand how data issues, missing information, and business logic were handled.

---

# 1. Data Source Assumptions

## A001 — Local files used for development

**Assumption:**  
For local development, source files are stored and processed from the local `data/raw/` folder.

**Reason:**  
The project brief describes Google Drive and OneDrive as source platforms, but for local development and reproducibility, sample files are processed locally.

**Impact:**  
The ingestion logic still follows the source structure described in the project brief, but the current local implementation does not require live Google Drive or OneDrive authentication.

---

## A002 — Source file metadata is preserved in Bronze

**Assumption:**  
All Bronze tables keep metadata columns such as `_source_file`, `_source_platform`, `_ingested_at`, and `_batch_id`.

**Reason:**  
Bronze data should preserve traceability to the original source files.

**Impact:**  
Data lineage can be reviewed when investigating data quality issues or reload history.

---

## A003 — Bronze data is loaded in append mode

**Assumption:**  
Bronze layer stores raw source data using append behavior.

**Reason:**  
Bronze should preserve raw ingestion history rather than overwriting previous loads.

**Impact:**  
Deduplication is handled in Silver instead of Bronze.

---

# 2. Sales Target Versioning Assumptions

## A004 — Latest target version is used for Power BI reporting

**Assumption:**  
For Power BI reporting, only the latest effective target version is used.

**Reason:**  
Management reporting should reflect the most recent approved target plan.

**Impact:**  
`mart_sales_vs_target` uses records flagged as latest target version.

---

## A005 — v2 target overrides v1 for adjusted months

**Assumption:**  
When a later target version exists for a month, the later version overrides the earlier version.

**Reason:**  
Target revisions represent updated business expectations.

**Impact:**  
For months adjusted in v2, v2 values are used as the effective target.

---

## A006 — Target is analyzed by month, employee, team, and region

**Assumption:**  
Sales targets are allocated at the month, employee, team, and region level.

**Reason:**  
The available target data supports these dimensions.

**Impact:**  
Target achievement can be analyzed by month, region, team, and employee, but not by channel or product unless target data is extended.

---

## A007 — Target is not allocated by channel

**Assumption:**  
Sales targets are not distributed by sales channel.

**Reason:**  
The target dataset does not include channel-level target allocation.

**Impact:**  
Channel charts should be used to analyze actual revenue and profit contribution, not target achievement.

---

# 3. Date and Fiscal Calendar Assumptions

## A008 — Calendar year 2024 is the main reporting year

**Assumption:**  
The Power BI dashboard focuses on calendar year 2024.

**Reason:**  
The main sales and target analysis is designed around 2024 performance.

**Impact:**  
Dashboard slicers and analysis focus on `calendar_year = 2024`.

---

## A009 — Fiscal year starts in September

**Assumption:**  
Fiscal year starts in September.

**Reason:**  
The `dim_date` table was designed to support fiscal-year reporting where September begins the fiscal year cycle.

**Impact:**  
Fiscal year may differ from calendar year. For example, early 2024 dates may belong to fiscal year 2023.

---

# 4. Silver Layer Assumptions

## A010 — Null and invalid text values are standardized

**Assumption:**  
Invalid values such as blank strings, `"nan"`, or `"null"` are standardized during Silver transformation.

**Reason:**  
Raw files may contain inconsistent missing value representations.

**Impact:**  
Silver tables provide cleaner and more reliable input for Gold models.

---

## A011 — Deduplication is handled in Silver

**Assumption:**  
Duplicate records from raw ingestion are removed or standardized in Silver models.

**Reason:**  
Bronze stores raw append-only data, so duplicate handling should happen after ingestion.

**Impact:**  
Gold tables are built from cleaned and deduplicated staging tables.

---

## A012 — Primary keys are standardized before Gold modeling

**Assumption:**  
Business identifiers such as customer_id, product_id, employee_id, distributor_id, and order_id are standardized before joining to Gold tables.

**Reason:**  
Consistent keys are necessary to build facts and dimensions reliably.

**Impact:**  
Gold joins are more stable and missing dimension keys are reduced.

---

# 5. Gold Layer Modeling Assumptions

## A013 — Star schema is the main modeling approach

**Assumption:**  
Gold layer is modeled using facts, dimensions, and mart tables.

**Reason:**  
Power BI analysis benefits from a clean star schema and business-ready marts.

**Impact:**  
Dashboard visuals primarily use Gold layer tables from the `dwh` schema.

---

## A014 — `fact_sales` grain is order line item

**Assumption:**  
Each row in `fact_sales` represents one sales order line item.

**Reason:**  
The sales transaction data contains product-level sales details.

**Impact:**  
Revenue, quantity, cost, and gross profit can be aggregated by time, customer, product, employee, region, and channel.

---

## A015 — `mart_sales_vs_target` is the main table for target reporting

**Assumption:**  
Actual vs target reporting should use `dwh.mart_sales_vs_target`.

**Reason:**  
This mart combines actual sales and target data at the reporting grain required by Power BI.

**Impact:**  
Measures such as Revenue Achievement %, Revenue Gap, Units Gap, and Units Achievement % are based on this mart.

---

## A016 — `mart_distributor_performance` is the main table for fulfillment reporting

**Assumption:**  
Distributor performance reporting should use `dwh.mart_distributor_performance`.

**Reason:**  
This mart aggregates distributor orders, delivered amounts, fill rate, and on-time delivery performance.

**Impact:**  
Distributor dashboard metrics are calculated consistently from this mart.

---

## A017 — Additional dimensions were added for Power BI usability

**Assumption:**  
Additional dimensions such as `dim_regions`, `dim_channels`, and `dim_geography` are useful for dashboard filtering and drill-down.

**Reason:**  
The original Gold model did not fully support all desired Power BI navigation paths.

**Impact:**  
The dashboard can analyze revenue by region, channel, and geography more clearly.

---

# 6. Metric Assumptions

## A018 — Actual Revenue uses net revenue

**Assumption:**  
Actual Revenue is based on net revenue after discount.

**Reason:**  
Net revenue better reflects realized sales value than gross sales before discount.

**Impact:**  
Revenue target achievement is compared against net actual revenue.

---

## A019 — Gross Profit is calculated after cost

**Assumption:**  
Gross Profit equals revenue minus total cost.

**Reason:**  
This reflects profitability at sales transaction level.

**Impact:**  
Gross Profit Margin can be used to evaluate profitability stability.

---

## A020 — Revenue Gap equals Actual Revenue minus Target Revenue

**Assumption:**  
Revenue Gap is calculated as actual revenue minus target revenue.

**Reason:**  
This shows whether the company is above or below target.

**Impact:**  
Positive gap indicates overperformance. Negative gap indicates underperformance.

---

## A021 — Revenue Achievement % equals Actual Revenue divided by Target Revenue

**Assumption:**  
Revenue Achievement % is calculated as actual revenue divided by target revenue.

**Reason:**  
This is the standard way to evaluate target attainment.

**Impact:**  
Values above 100% indicate target exceeded. Values below 100% indicate underachievement.

---

## A022 — Units Achievement % equals Actual Units Sold divided by Target Units

**Assumption:**  
Units Achievement % is calculated as actual units sold divided by target units.

**Reason:**  
This compares actual sales volume against volume target.

**Impact:**  
It helps identify whether revenue gaps are also linked to quantity gaps.

---

## A023 — Quantity Fill Rate equals delivered quantity divided by ordered quantity

**Assumption:**  
Quantity Fill Rate is calculated as quantity delivered divided by quantity ordered.

**Reason:**  
This measures how completely distributors fulfill orders.

**Impact:**  
Lower fill rate indicates quantity leakage.

---

## A024 — On-time Delivery Rate equals on-time deliveries divided by delivery records

**Assumption:**  
On-time Delivery Rate is calculated using the number of on-time deliveries divided by total delivery records.

**Reason:**  
This measures distributor delivery reliability.

**Impact:**  
Low on-time delivery rate indicates operational risk even when fill rate is acceptable.

---

# 7. Dashboard Assumptions

## A025 — Overview focuses on business health

**Assumption:**  
The Overview page should show overall revenue target achievement, profitability, and revenue contribution.

**Reason:**  
This page is designed for quick executive-level understanding.

**Impact:**  
Detailed employee and distributor analysis is kept for later pages.

---

## A026 — Sales Performance focuses on target gap diagnosis

**Assumption:**  
The Sales Performance page should diagnose where the revenue gap comes from.

**Reason:**  
The main business problem is revenue underachievement against target.

**Impact:**  
The page analyzes month, region, channel contribution, and employee performance.

---

## A027 — Distributor Analysis focuses on fulfillment and delivery reliability

**Assumption:**  
Distributor Analysis should focus on delivered revenue, quantity fill rate, and on-time delivery rate.

**Reason:**  
Distributor execution affects revenue realization and customer experience.

**Impact:**  
The page prioritizes distributors with high revenue contribution and weak fulfillment or delivery performance.

---

## A028 — Channel analysis should not be interpreted as target achievement

**Assumption:**  
Channel charts show actual revenue and profit contribution only.

**Reason:**  
Targets are not available at channel level.

**Impact:**  
Channel performance should support business interpretation, but not be used to evaluate target attainment.

---

## A029 — Employee ranking is used for coaching, not final judgment

**Assumption:**  
Top/Bottom employee ranking is an initial diagnostic view, not a final performance evaluation.

**Reason:**  
Employee performance may be affected by target allocation, region difficulty, pipeline quality, and customer coverage.

**Impact:**  
Managers should use ranking as a starting point for review, not as the only basis for decision-making.

---

# 8. Known Limitations

## L001 — Live cloud connector implementation is not fully used in local dashboard build

**Limitation:**  
The current local version uses local source files rather than live Google Drive or OneDrive API ingestion.

**Impact:**  
The project is reproducible locally, but cloud automation would need additional credentials and connector setup.

---

## L002 — Channel-level targets are not available

**Limitation:**  
The target dataset does not include channel-level target allocation.

**Impact:**  
The dashboard cannot calculate channel-level target achievement.

---

## L003 — Product-level target analysis is not available

**Limitation:**  
The target dataset is not allocated by product.

**Impact:**  
Product-level actual vs target analysis is not included.

---

## L004 — Power BI file is binary

**Limitation:**  
The `.pbix` file is a binary file and cannot be easily reviewed through Git diffs.

**Impact:**  
Dashboard logic is documented separately in README and `docs/dashboard_insights.md`.