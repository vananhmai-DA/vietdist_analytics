DROP TABLE IF EXISTS dwh.mart_sales_vs_target;

CREATE TABLE dwh.mart_sales_vs_target AS
WITH actual_sales AS (
    SELECT
        employee_id,
        DATE_TRUNC('month', order_date)::DATE AS sales_month_date,
        EXTRACT(YEAR FROM order_date)::INTEGER AS sales_year,
        EXTRACT(MONTH FROM order_date)::INTEGER AS sales_month,

        COUNT(DISTINCT order_id) AS total_orders,
        COUNT(DISTINCT customer_id) AS active_customers,
        SUM(quantity) AS actual_quantity,
        SUM(gross_amount) AS actual_gross_amount,
        SUM(discount_amount) AS actual_discount_amount,
        SUM(net_amount) AS actual_revenue,
        SUM(total_cost) AS actual_total_cost,
        SUM(gross_profit) AS actual_gross_profit
    FROM dwh.fact_sales
    GROUP BY
        employee_id,
        DATE_TRUNC('month', order_date)::DATE,
        EXTRACT(YEAR FROM order_date)::INTEGER,
        EXTRACT(MONTH FROM order_date)::INTEGER
),

targets AS (
    SELECT
        employee_id,
        employee_name,
        target_month_date,
        target_year,
        target_month,
        region,
        team,
        version_label,
        target_revenue,
        target_quantity,
        target_new_customers
    FROM dwh.fact_targets
)

SELECT
    COALESCE(t.employee_id, a.employee_id) AS employee_id,
    t.employee_name,

    COALESCE(t.target_month_date, a.sales_month_date) AS month_date,
    COALESCE(t.target_year, a.sales_year) AS year,
    COALESCE(t.target_month, a.sales_month) AS month,

    t.region,
    t.team,
    t.version_label,

    COALESCE(a.total_orders, 0) AS total_orders,
    COALESCE(a.active_customers, 0) AS active_customers,

    COALESCE(a.actual_quantity, 0) AS actual_quantity,
    COALESCE(t.target_quantity, 0) AS target_quantity,
    COALESCE(a.actual_quantity, 0) - COALESCE(t.target_quantity, 0) AS quantity_gap,

    CASE
        WHEN t.target_quantity IS NULL OR t.target_quantity = 0 THEN NULL
        ELSE ROUND((COALESCE(a.actual_quantity, 0) / t.target_quantity) * 100, 2)
    END AS quantity_achievement_pct,

    COALESCE(a.actual_revenue, 0) AS actual_revenue,
    COALESCE(t.target_revenue, 0) AS target_revenue,
    COALESCE(a.actual_revenue, 0) - COALESCE(t.target_revenue, 0) AS revenue_gap,

    CASE
        WHEN t.target_revenue IS NULL OR t.target_revenue = 0 THEN NULL
        ELSE ROUND((COALESCE(a.actual_revenue, 0) / t.target_revenue) * 100, 2)
    END AS revenue_achievement_pct,

    COALESCE(a.actual_total_cost, 0) AS actual_total_cost,
    COALESCE(a.actual_gross_profit, 0) AS actual_gross_profit,

    CASE
        WHEN a.actual_revenue IS NULL OR a.actual_revenue = 0 THEN NULL
        ELSE ROUND((a.actual_gross_profit / a.actual_revenue) * 100, 2)
    END AS actual_gross_profit_margin_pct,

    COALESCE(t.target_new_customers, 0) AS target_new_customers

FROM targets t

FULL OUTER JOIN actual_sales a
    ON t.employee_id = a.employee_id
   AND t.target_month_date = a.sales_month_date;