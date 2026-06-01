{{ 
    config(
        materialized='incremental',
        unique_key=['order_id', 'distributor_id', 'product_id'],
        incremental_strategy='delete+insert'
    ) 
}}

WITH latest_success_batch AS (
    SELECT
        batch_id
    FROM {{ source('raw', 'ingest_log') }}
    WHERE source_name = 'distributor_orders'
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
            WHEN distributor_id IS NULL
              OR LOWER(TRIM(distributor_id)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(distributor_id)
        END AS distributor_id,

        CASE
            WHEN region IS NULL
              OR LOWER(TRIM(region)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(region)
        END AS region,

        CASE
            WHEN channel IS NULL
              OR LOWER(TRIM(channel)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(channel)
        END AS channel,

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
            WHEN qty_ordered IS NULL
              OR LOWER(TRIM(qty_ordered)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN REGEXP_REPLACE(TRIM(qty_ordered), '[, ]', '', 'g') ~ '^-?\d+(\.\d+)?$'
            THEN REGEXP_REPLACE(TRIM(qty_ordered), '[, ]', '', 'g')::NUMERIC
            ELSE NULL
        END AS qty_ordered,

        CASE
            WHEN qty_delivered IS NULL
              OR LOWER(TRIM(qty_delivered)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN REGEXP_REPLACE(TRIM(qty_delivered), '[, ]', '', 'g') ~ '^-?\d+(\.\d+)?$'
            THEN REGEXP_REPLACE(TRIM(qty_delivered), '[, ]', '', 'g')::NUMERIC
            ELSE NULL
        END AS qty_delivered,

        CASE
            WHEN fill_rate_pct IS NULL
              OR LOWER(TRIM(fill_rate_pct)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN REGEXP_REPLACE(TRIM(fill_rate_pct), '[,% ]', '', 'g') ~ '^-?\d+(\.\d+)?$'
            THEN REGEXP_REPLACE(TRIM(fill_rate_pct), '[,% ]', '', 'g')::NUMERIC
            ELSE NULL
        END AS fill_rate_pct,

        CASE
            WHEN unit_price_list IS NULL
              OR LOWER(TRIM(unit_price_list)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN REGEXP_REPLACE(TRIM(unit_price_list), '[, ]', '', 'g') ~ '^-?\d+(\.\d+)?$'
            THEN REGEXP_REPLACE(TRIM(unit_price_list), '[, ]', '', 'g')::NUMERIC
            ELSE NULL
        END AS unit_price_list,

        CASE
            WHEN distributor_price IS NULL
              OR LOWER(TRIM(distributor_price)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN REGEXP_REPLACE(TRIM(distributor_price), '[, ]', '', 'g') ~ '^-?\d+(\.\d+)?$'
            THEN REGEXP_REPLACE(TRIM(distributor_price), '[, ]', '', 'g')::NUMERIC
            ELSE NULL
        END AS distributor_price,

        CASE
            WHEN gross_amount IS NULL
              OR LOWER(TRIM(gross_amount)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN REGEXP_REPLACE(TRIM(gross_amount), '[, ]', '', 'g') ~ '^-?\d+(\.\d+)?$'
            THEN REGEXP_REPLACE(TRIM(gross_amount), '[, ]', '', 'g')::NUMERIC
            ELSE NULL
        END AS gross_amount,

        CASE
            WHEN delivered_amount IS NULL
              OR LOWER(TRIM(delivered_amount)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN REGEXP_REPLACE(TRIM(delivered_amount), '[, ]', '', 'g') ~ '^-?\d+(\.\d+)?$'
            THEN REGEXP_REPLACE(TRIM(delivered_amount), '[, ]', '', 'g')::NUMERIC
            ELSE NULL
        END AS delivered_amount,

        CASE
            WHEN expected_delivery_date IS NULL
              OR LOWER(TRIM(expected_delivery_date)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN TRIM(expected_delivery_date) ~ '^\d{4}-\d{2}-\d{2}$'
            THEN TRIM(expected_delivery_date)::DATE
            WHEN TRIM(expected_delivery_date) ~ '^\d{1,2}/\d{1,2}/\d{4}$'
            THEN TO_DATE(TRIM(expected_delivery_date), 'DD/MM/YYYY')
            ELSE NULL
        END AS expected_delivery_date,

        CASE
            WHEN actual_delivery_date IS NULL
              OR LOWER(TRIM(actual_delivery_date)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN TRIM(actual_delivery_date) ~ '^\d{4}-\d{2}-\d{2}$'
            THEN TRIM(actual_delivery_date)::DATE
            WHEN TRIM(actual_delivery_date) ~ '^\d{1,2}/\d{1,2}/\d{4}$'
            THEN TO_DATE(TRIM(actual_delivery_date), 'DD/MM/YYYY')
            ELSE NULL
        END AS actual_delivery_date,

        CASE
            WHEN ontime_delivery IS NULL
              OR LOWER(TRIM(ontime_delivery)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(ontime_delivery)
        END AS on_time_delivery,

        CASE
            WHEN delivery_status IS NULL
              OR LOWER(TRIM(delivery_status)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(delivery_status)
        END AS delivery_status,

        CASE
            WHEN payment_terms IS NULL
              OR LOWER(TRIM(payment_terms)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(payment_terms)
        END AS payment_terms,

        _source_file,
        _source_platform,
        _ingested_at,
        _batch_id,

        ROW_NUMBER() OVER (
            PARTITION BY
                TRIM(order_id),
                TRIM(distributor_id),
                TRIM(product_id)
            ORDER BY _ingested_at DESC
        ) AS rn

    FROM {{ source('raw', 'distributor_orders') }}
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
    distributor_id,
    region,
    channel,
    product_id,
    product_category,
    qty_ordered,
    qty_delivered,
    fill_rate_pct,
    unit_price_list,
    distributor_price,
    gross_amount,
    delivered_amount,
    expected_delivery_date,
    actual_delivery_date,
    on_time_delivery,
    delivery_status,
    payment_terms,
    _source_file,
    _source_platform,
    _ingested_at,
    _batch_id,
    NOW() AS _processed_at
FROM source
WHERE order_id IS NOT NULL
  AND distributor_id IS NOT NULL
  AND product_id IS NOT NULL
  AND rn = 1