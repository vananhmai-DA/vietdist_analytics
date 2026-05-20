-- Silver Layer Data Quality Tests

-- 1. Row count checks
SELECT 'stg_customers row count' AS test_name, COUNT(*) AS result
FROM staging.stg_customers;

SELECT 'stg_products row count' AS test_name, COUNT(*) AS result
FROM staging.stg_products;

SELECT 'stg_employees row count' AS test_name, COUNT(*) AS result
FROM staging.stg_employees;

SELECT 'stg_distributors row count' AS test_name, COUNT(*) AS result
FROM staging.stg_distributors;

SELECT 'stg_territory_mapping row count' AS test_name, COUNT(*) AS result
FROM staging.stg_territory_mapping;

SELECT 'stg_return_transactions row count' AS test_name, COUNT(*) AS result
FROM staging.stg_return_transactions;

SELECT 'stg_promotion_program row count' AS test_name, COUNT(*) AS result
FROM staging.stg_promotion_program;

SELECT 'stg_sales_transactions row count' AS test_name, COUNT(*) AS result
FROM staging.stg_sales_transactions;

SELECT 'stg_distributor_orders row count' AS test_name, COUNT(*) AS result
FROM staging.stg_distributor_orders;

SELECT 'stg_sales_targets_versioned row count' AS test_name, COUNT(*) AS result
FROM staging.stg_sales_targets_versioned;


-- 2. Not null key tests
SELECT 'stg_customers customer_id nulls' AS test_name, COUNT(*) AS failures
FROM staging.stg_customers
WHERE customer_id IS NULL;

SELECT 'stg_products product_id nulls' AS test_name, COUNT(*) AS failures
FROM staging.stg_products
WHERE product_id IS NULL;

SELECT 'stg_employees employee_id nulls' AS test_name, COUNT(*) AS failures
FROM staging.stg_employees
WHERE employee_id IS NULL;

SELECT 'stg_distributors distributor_id nulls' AS test_name, COUNT(*) AS failures
FROM staging.stg_distributors
WHERE distributor_id IS NULL;

SELECT 'stg_territory_mapping key nulls' AS test_name, COUNT(*) AS failures
FROM staging.stg_territory_mapping
WHERE territory_id IS NULL
   OR employee_id IS NULL
   OR customer_id IS NULL;

SELECT 'stg_return_transactions return_id nulls' AS test_name, COUNT(*) AS failures
FROM staging.stg_return_transactions
WHERE return_id IS NULL;

SELECT 'stg_promotion_program promotion_id nulls' AS test_name, COUNT(*) AS failures
FROM staging.stg_promotion_program
WHERE promotion_id IS NULL;

SELECT 'stg_sales_transactions key nulls' AS test_name, COUNT(*) AS failures
FROM staging.stg_sales_transactions
WHERE order_id IS NULL
   OR product_id IS NULL;

SELECT 'stg_distributor_orders key nulls' AS test_name, COUNT(*) AS failures
FROM staging.stg_distributor_orders
WHERE order_id IS NULL
   OR distributor_id IS NULL
   OR product_id IS NULL;

SELECT 'stg_sales_targets_versioned key nulls' AS test_name, COUNT(*) AS failures
FROM staging.stg_sales_targets_versioned
WHERE version_label IS NULL
   OR employee_id IS NULL
   OR month_col IS NULL;


-- 3. Unique key tests
SELECT 'stg_customers duplicate customer_id' AS test_name, COUNT(*) AS failures
FROM (
    SELECT customer_id
    FROM staging.stg_customers
    GROUP BY customer_id
    HAVING COUNT(*) > 1
) t;

SELECT 'stg_products duplicate product_id' AS test_name, COUNT(*) AS failures
FROM (
    SELECT product_id
    FROM staging.stg_products
    GROUP BY product_id
    HAVING COUNT(*) > 1
) t;

SELECT 'stg_employees duplicate employee effective record' AS test_name, COUNT(*) AS failures
FROM (
    SELECT employee_id, effective_date
    FROM staging.stg_employees
    GROUP BY employee_id, effective_date
    HAVING COUNT(*) > 1
) t;

SELECT 'stg_distributors duplicate distributor_id' AS test_name, COUNT(*) AS failures
FROM (
    SELECT distributor_id
    FROM staging.stg_distributors
    GROUP BY distributor_id
    HAVING COUNT(*) > 1
) t;

SELECT 'stg_territory_mapping duplicate mapping' AS test_name, COUNT(*) AS failures
FROM (
    SELECT territory_id, employee_id, customer_id, effective_date
    FROM staging.stg_territory_mapping
    GROUP BY territory_id, employee_id, customer_id, effective_date
    HAVING COUNT(*) > 1
) t;

SELECT 'stg_return_transactions duplicate return_id' AS test_name, COUNT(*) AS failures
FROM (
    SELECT return_id
    FROM staging.stg_return_transactions
    GROUP BY return_id
    HAVING COUNT(*) > 1
) t;

SELECT 'stg_promotion_program duplicate promotion_id' AS test_name, COUNT(*) AS failures
FROM (
    SELECT promotion_id
    FROM staging.stg_promotion_program
    GROUP BY promotion_id
    HAVING COUNT(*) > 1
) t;

SELECT 'stg_sales_transactions duplicate order product' AS test_name, COUNT(*) AS failures
FROM (
    SELECT order_id, product_id
    FROM staging.stg_sales_transactions
    GROUP BY order_id, product_id
    HAVING COUNT(*) > 1
) t;

SELECT 'stg_distributor_orders duplicate order distributor product' AS test_name, COUNT(*) AS failures
FROM (
    SELECT order_id, distributor_id, product_id
    FROM staging.stg_distributor_orders
    GROUP BY order_id, distributor_id, product_id
    HAVING COUNT(*) > 1
) t;

SELECT 'stg_sales_targets_versioned duplicate version target' AS test_name, COUNT(*) AS failures
FROM (
    SELECT version_label, employee_id, target_year, month_col
    FROM staging.stg_sales_targets_versioned
    GROUP BY version_label, employee_id, target_year, month_col
    HAVING COUNT(*) > 1
) t;

SELECT 'stg_sales_targets_versioned duplicate latest target' AS test_name, COUNT(*) AS failures
FROM (
    SELECT employee_id, target_year, target_month
    FROM staging.stg_sales_targets_versioned
    WHERE is_latest = TRUE
    GROUP BY employee_id, target_year, target_month
    HAVING COUNT(*) > 1
) t;