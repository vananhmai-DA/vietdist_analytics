{{ 
    config(
        materialized='incremental',
        unique_key=['order_id', 'product_id'],
        incremental_strategy='delete+insert'
    ) 
}}

WITH latest_success_batch AS (
    SELECT
        batch_id
    FROM {{ source('raw', 'ingest_log') }}
    WHERE source_name = 'sales_transactions'
      AND status = 'SUCCESS'
    ORDER BY finished_at DESC
    LIMIT 1
),

source AS (
    SELECT
        CASE
            WHEN order_id IS NULL
              OR LOWER(TRIM(order_id)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(order_id)
        END AS order_id,

        CASE
            WHEN order_date IS NULL
              OR LOWER(TRIM(order_date)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN TRIM(order_date) ~ '^\d{4}-\d{2}-\d{2}$'
            THEN TRIM(order_date)::DATE
            WHEN TRIM(order_date) ~ '^\d{1,2}/\d{1,2}/\d{4}$'
            THEN TO_DATE(TRIM(order_date), 'DD/MM/YYYY')
            ELSE NULL
        END AS order_date,

        CASE
            WHEN order_month IS NULL
              OR LOWER(TRIM(order_month)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN TRIM(order_month) ~ '^\d+$'
            THEN TRIM(order_month)::INTEGER
            ELSE NULL
        END AS order_month,

        CASE
            WHEN order_quarter IS NULL
              OR LOWER(TRIM(order_quarter)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(order_quarter)
        END AS order_quarter,

        CASE
            WHEN order_year IS NULL
              OR LOWER(TRIM(order_year)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN TRIM(order_year) ~ '^\d+$'
            THEN TRIM(order_year)::INTEGER
            ELSE NULL
        END AS order_year,

        CASE
            WHEN customer_id IS NULL
              OR LOWER(TRIM(customer_id)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(customer_id)
        END AS customer_id,

        CASE
            WHEN region IS NULL
              OR LOWER(TRIM(region)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(region)
        END AS region,

        CASE
            WHEN province IS NULL
              OR LOWER(TRIM(province)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(province)
        END AS province,

        CASE
            WHEN channel IS NULL
              OR LOWER(TRIM(channel)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(channel)
        END AS channel,

        CASE
            WHEN employee_id IS NULL
              OR LOWER(TRIM(employee_id)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(employee_id)
        END AS employee_id,

        CASE
            WHEN product_id IS NULL
              OR LOWER(TRIM(product_id)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(product_id)
        END AS product_id,

        CASE
            WHEN product_category IS NULL
              OR LOWER(TRIM(product_category)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(product_category)
        END AS product_category,

        CASE
            WHEN quantity IS NULL
              OR LOWER(TRIM(quantity)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN REGEXP_REPLACE(TRIM(quantity), '[, ]', '', 'g') ~ '^-?\d+(\.\d+)?$'
            THEN REGEXP_REPLACE(TRIM(quantity), '[, ]', '', 'g')::NUMERIC
            ELSE NULL
        END AS quantity,

        CASE
            WHEN unit_price IS NULL
              OR LOWER(TRIM(unit_price)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN REGEXP_REPLACE(TRIM(unit_price), '[, ]', '', 'g') ~ '^-?\d+(\.\d+)?$'
            THEN REGEXP_REPLACE(TRIM(unit_price), '[, ]', '', 'g')::NUMERIC
            ELSE NULL
        END AS unit_price,

        CASE
            WHEN discount_pct IS NULL
              OR LOWER(TRIM(discount_pct)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN REGEXP_REPLACE(TRIM(discount_pct), '[,% ]', '', 'g') ~ '^-?\d+(\.\d+)?$'
            THEN REGEXP_REPLACE(TRIM(discount_pct), '[,% ]', '', 'g')::NUMERIC
            ELSE NULL
        END AS discount_pct,

        CASE
            WHEN discount_amount IS NULL
              OR LOWER(TRIM(discount_amount)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN REGEXP_REPLACE(TRIM(discount_amount), '[, ]', '', 'g') ~ '^-?\d+(\.\d+)?$'
            THEN REGEXP_REPLACE(TRIM(discount_amount), '[, ]', '', 'g')::NUMERIC
            ELSE NULL
        END AS discount_amount,

        CASE
            WHEN gross_amount IS NULL
              OR LOWER(TRIM(gross_amount)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN REGEXP_REPLACE(TRIM(gross_amount), '[, ]', '', 'g') ~ '^-?\d+(\.\d+)?$'
            THEN REGEXP_REPLACE(TRIM(gross_amount), '[, ]', '', 'g')::NUMERIC
            ELSE NULL
        END AS gross_amount,

        CASE
            WHEN net_amount IS NULL
              OR LOWER(TRIM(net_amount)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN REGEXP_REPLACE(TRIM(net_amount), '[, ]', '', 'g') ~ '^-?\d+(\.\d+)?$'
            THEN REGEXP_REPLACE(TRIM(net_amount), '[, ]', '', 'g')::NUMERIC
            ELSE NULL
        END AS net_amount,

        CASE
            WHEN delivery_status IS NULL
              OR LOWER(TRIM(delivery_status)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(delivery_status)
        END AS delivery_status,

        CASE
            WHEN payment_method IS NULL
              OR LOWER(TRIM(payment_method)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(payment_method)
        END AS payment_method,

        CASE
            WHEN payment_status IS NULL
              OR LOWER(TRIM(payment_status)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(payment_status)
        END AS payment_status,

        _source_file,
        _source_platform,
        _ingested_at,
        _batch_id,

        ROW_NUMBER() OVER (
            PARTITION BY
                TRIM(order_id),
                TRIM(product_id)
            ORDER BY _ingested_at DESC
        ) AS rn

    FROM {{ source('raw', 'sales_transactions') }}
    WHERE _batch_id = (
        SELECT batch_id
        FROM latest_success_batch
    )

    {% if is_incremental() %}
      AND _ingested_at > (
          SELECT COALESCE(MAX(_ingested_at), TIMESTAMP '1900-01-01')
          FROM {{ this }}
      )
    {% endif %}
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
    _batch_id,
    NOW() AS _processed_at
FROM source
WHERE order_id IS NOT NULL
  AND product_id IS NOT NULL
  AND rn = 1