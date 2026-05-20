-- Gold Layer Data Quality Tests

-- 1. Row count checks
SELECT 'dim_date row count' AS test_name, COUNT(*) AS result
FROM dwh.dim_date;

SELECT 'dim_customers row count' AS test_name, COUNT(*) AS result
FROM dwh.dim_customers;

SELECT 'dim_products row count' AS test_name, COUNT(*) AS result
FROM dwh.dim_products;

SELECT 'dim_employees row count' AS test_name, COUNT(*) AS result
FROM dwh.dim_employees;

SELECT 'dim_distributors row count' AS test_name, COUNT(*) AS result
FROM dwh.dim_distributors;

SELECT 'fact_sales row count' AS test_name, COUNT(*) AS result
FROM dwh.fact_sales;

SELECT 'fact_returns row count' AS test_name, COUNT(*) AS result
FROM dwh.fact_returns;

SELECT 'fact_targets row count' AS test_name, COUNT(*) AS result
FROM dwh.fact_targets;

SELECT 'fact_distributor_orders row count' AS test_name, COUNT(*) AS result
FROM dwh.fact_distributor_orders;

SELECT 'mart_sales_vs_target row count' AS test_name, COUNT(*) AS result
FROM dwh.mart_sales_vs_target;

SELECT 'mart_distributor_performance row count' AS test_name, COUNT(*) AS result
FROM dwh.mart_distributor_performance;


-- 2. Dimension key not-null tests
SELECT 'dim_date date_key nulls' AS test_name, COUNT(*) AS failures
FROM dwh.dim_date
WHERE date_key IS NULL;

SELECT 'dim_customers customer_key nulls' AS test_name, COUNT(*) AS failures
FROM dwh.dim_customers
WHERE customer_key IS NULL;

SELECT 'dim_products product_key nulls' AS test_name, COUNT(*) AS failures
FROM dwh.dim_products
WHERE product_key IS NULL;

SELECT 'dim_employees employee_key nulls' AS test_name, COUNT(*) AS failures
FROM dwh.dim_employees
WHERE employee_key IS NULL;

SELECT 'dim_distributors distributor_key nulls' AS test_name, COUNT(*) AS failures
FROM dwh.dim_distributors
WHERE distributor_key IS NULL;


-- 3. Dimension key unique tests
SELECT 'dim_date duplicate date_key' AS test_name, COUNT(*) AS failures
FROM (
    SELECT date_key
    FROM dwh.dim_date
    GROUP BY date_key
    HAVING COUNT(*) > 1
) t;

SELECT 'dim_customers duplicate customer_key' AS test_name, COUNT(*) AS failures
FROM (
    SELECT customer_key
    FROM dwh.dim_customers
    GROUP BY customer_key
    HAVING COUNT(*) > 1
) t;

SELECT 'dim_products duplicate product_key' AS test_name, COUNT(*) AS failures
FROM (
    SELECT product_key
    FROM dwh.dim_products
    GROUP BY product_key
    HAVING COUNT(*) > 1
) t;

SELECT 'dim_employees duplicate employee_key' AS test_name, COUNT(*) AS failures
FROM (
    SELECT employee_key
    FROM dwh.dim_employees
    GROUP BY employee_key
    HAVING COUNT(*) > 1
) t;

SELECT 'dim_distributors duplicate distributor_key' AS test_name, COUNT(*) AS failures
FROM (
    SELECT distributor_key
    FROM dwh.dim_distributors
    GROUP BY distributor_key
    HAVING COUNT(*) > 1
) t;


-- 4. Fact grain duplicate tests
SELECT 'fact_sales duplicate order product' AS test_name, COUNT(*) AS failures
FROM (
    SELECT order_id, product_id
    FROM dwh.fact_sales
    GROUP BY order_id, product_id
    HAVING COUNT(*) > 1
) t;

SELECT 'fact_returns duplicate return_id' AS test_name, COUNT(*) AS failures
FROM (
    SELECT return_id
    FROM dwh.fact_returns
    GROUP BY return_id
    HAVING COUNT(*) > 1
) t;

SELECT 'fact_targets duplicate employee month' AS test_name, COUNT(*) AS failures
FROM (
    SELECT employee_id, target_year, target_month
    FROM dwh.fact_targets
    GROUP BY employee_id, target_year, target_month
    HAVING COUNT(*) > 1
) t;

SELECT 'fact_distributor_orders duplicate order distributor product' AS test_name, COUNT(*) AS failures
FROM (
    SELECT order_id, distributor_id, product_id
    FROM dwh.fact_distributor_orders
    GROUP BY order_id, distributor_id, product_id
    HAVING COUNT(*) > 1
) t;


-- 5. Missing dimension key checks
SELECT 'fact_sales missing dimension keys' AS test_name,
       COUNT(*) AS failures
FROM dwh.fact_sales
WHERE order_date_key IS NULL
   OR customer_key IS NULL
   OR product_key IS NULL
   OR employee_key IS NULL;

SELECT 'fact_returns missing dimension keys' AS test_name,
       COUNT(*) AS failures
FROM dwh.fact_returns
WHERE return_date_key IS NULL
   OR customer_key IS NULL
   OR product_key IS NULL
   OR employee_key IS NULL;

SELECT 'fact_targets missing dimension keys' AS test_name,
       COUNT(*) AS failures
FROM dwh.fact_targets
WHERE target_date_key IS NULL
   OR employee_key IS NULL;

SELECT 'fact_distributor_orders missing dimension keys' AS test_name,
       COUNT(*) AS failures
FROM dwh.fact_distributor_orders
WHERE order_date_key IS NULL
   OR distributor_key IS NULL
   OR product_key IS NULL;


-- 6. Business logic sanity checks
SELECT 'dim_date fiscal year check' AS test_name,
       COUNT(*) AS failures
FROM dwh.dim_date
WHERE (date_day = DATE '2023-10-01' AND fiscal_year <> 2023)
   OR (date_day = DATE '2024-01-01' AND fiscal_year <> 2023);

SELECT 'fact_targets latest flag check' AS test_name,
       COUNT(*) AS failures
FROM dwh.fact_targets
WHERE is_latest IS DISTINCT FROM TRUE;

SELECT 'mart_sales_vs_target negative target revenue' AS test_name,
       COUNT(*) AS failures
FROM dwh.mart_sales_vs_target
WHERE target_revenue < 0;

SELECT 'mart_distributor_performance invalid fill rate' AS test_name,
       COUNT(*) AS failures
FROM dwh.mart_distributor_performance
WHERE fill_rate_pct < 0
   OR fill_rate_pct > 100;