DROP TABLE IF EXISTS staging.stg_sales_transactions;

CREATE TABLE staging.stg_sales_transactions AS
WITH source AS (
    SELECT
        NULLIF(TRIM(order_id), '') AS order_id,

        CAST(NULLIF(TRIM(order_date), '') AS DATE) AS order_date,
        CAST(NULLIF(TRIM(order_month), '') AS INTEGER) AS order_month,
        NULLIF(TRIM(order_quarter), '') AS order_quarter,
        CAST(NULLIF(TRIM(order_year), '') AS INTEGER) AS order_year,

        NULLIF(TRIM(customer_id), '') AS customer_id,
        NULLIF(TRIM(region), '') AS region,
        NULLIF(TRIM(province), '') AS province,
        NULLIF(TRIM(channel), '') AS channel,
        NULLIF(TRIM(employee_id), '') AS employee_id,
        NULLIF(TRIM(product_id), '') AS product_id,
        NULLIF(TRIM(product_category), '') AS product_category,

        CAST(NULLIF(TRIM(quantity), '') AS NUMERIC) AS quantity,
        CAST(NULLIF(TRIM(unit_price), '') AS NUMERIC) AS unit_price,
        CAST(NULLIF(TRIM(discount_pct), '') AS NUMERIC) AS discount_pct,
        CAST(NULLIF(TRIM(discount_amount), '') AS NUMERIC) AS discount_amount,
        CAST(NULLIF(TRIM(gross_amount), '') AS NUMERIC) AS gross_amount,
        CAST(NULLIF(TRIM(net_amount), '') AS NUMERIC) AS net_amount,

        NULLIF(TRIM(delivery_status), '') AS delivery_status,
        NULLIF(TRIM(payment_method), '') AS payment_method,
        NULLIF(TRIM(payment_status), '') AS payment_status,

        _source_file,
        _source_platform,
        _ingested_at,
        _batch_id,

        ROW_NUMBER() OVER (
            PARTITION BY order_id, product_id
            ORDER BY _ingested_at DESC
        ) AS rn
    FROM raw.sales_transactions
    WHERE order_id IS NOT NULL
      AND product_id IS NOT NULL
      AND LOWER(TRIM(order_id)) NOT IN ('nan', 'none', 'null', '')
      AND LOWER(TRIM(product_id)) NOT IN ('nan', 'none', 'null', '')
)

SELECT
    order_id,
    order_date,
    order_month,
    order_quarter,
    order_year,
    customer_id,
    region,
    province,
    channel,
    employee_id,
    product_id,
    product_category,
    quantity,
    unit_price,
    discount_pct,
    discount_amount,
    gross_amount,
    net_amount,
    delivery_status,
    payment_method,
    payment_status,
    _source_file,
    _source_platform,
    _ingested_at,
    _batch_id
FROM source
WHERE rn = 1;