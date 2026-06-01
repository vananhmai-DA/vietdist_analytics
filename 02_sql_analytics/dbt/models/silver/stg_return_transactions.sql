{{ 
    config(
        materialized='incremental',
        unique_key='return_id',
        incremental_strategy='delete+insert'
    ) 
}}

WITH latest_success_batch AS (
    SELECT
        batch_id
    FROM {{ source('raw', 'ingest_log') }}
    WHERE source_name = 'return_transactions'
      AND status = 'SUCCESS'
    ORDER BY finished_at DESC
    LIMIT 1
),

source AS (
    SELECT
        CASE
            WHEN return_id IS NULL
              OR LOWER(TRIM(return_id)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(return_id)
        END AS return_id,

        CASE
            WHEN original_order_id IS NULL
              OR LOWER(TRIM(original_order_id)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(original_order_id)
        END AS original_order_id,

        CASE
            WHEN return_date IS NULL
              OR LOWER(TRIM(return_date)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN TRIM(return_date) ~ '^\d{4}-\d{2}-\d{2}$'
            THEN TRIM(return_date)::DATE
            WHEN TRIM(return_date) ~ '^\d{1,2}/\d{1,2}/\d{4}$'
            THEN TO_DATE(TRIM(return_date), 'DD/MM/YYYY')
            ELSE NULL
        END AS return_date,

        CASE
            WHEN return_month IS NULL
              OR LOWER(TRIM(return_month)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN TRIM(return_month) ~ '^\d+$'
            THEN TRIM(return_month)::INTEGER
            ELSE NULL
        END AS return_month,

        CASE
            WHEN customer_id IS NULL
              OR LOWER(TRIM(customer_id)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(customer_id)
        END AS customer_id,

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
            WHEN return_quantity IS NULL
              OR LOWER(TRIM(return_quantity)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN REGEXP_REPLACE(TRIM(return_quantity), '[, ]', '', 'g') ~ '^-?\d+(\.\d+)?$'
            THEN REGEXP_REPLACE(TRIM(return_quantity), '[, ]', '', 'g')::NUMERIC
            ELSE NULL
        END AS return_quantity,

        CASE
            WHEN unit_price IS NULL
              OR LOWER(TRIM(unit_price)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN REGEXP_REPLACE(TRIM(unit_price), '[, ]', '', 'g') ~ '^-?\d+(\.\d+)?$'
            THEN REGEXP_REPLACE(TRIM(unit_price), '[, ]', '', 'g')::NUMERIC
            ELSE NULL
        END AS unit_price,

        CASE
            WHEN return_amount IS NULL
              OR LOWER(TRIM(return_amount)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN REGEXP_REPLACE(TRIM(return_amount), '[, ]', '', 'g') ~ '^-?\d+(\.\d+)?$'
            THEN REGEXP_REPLACE(TRIM(return_amount), '[, ]', '', 'g')::NUMERIC
            ELSE NULL
        END AS return_amount,

        CASE
            WHEN return_reason IS NULL
              OR LOWER(TRIM(return_reason)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(return_reason)
        END AS return_reason,

        CASE
            WHEN status IS NULL
              OR LOWER(TRIM(status)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(status)
        END AS status,

        _source_file,
        _source_platform,
        _ingested_at,
        _batch_id,

        ROW_NUMBER() OVER (
            PARTITION BY TRIM(return_id)
            ORDER BY _ingested_at DESC
        ) AS rn

    FROM {{ source('raw', 'return_transactions') }}
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
    return_id,
    original_order_id,
    return_date,
    return_month,
    customer_id,
    employee_id,
    product_id,
    region,
    province,
    return_quantity,
    unit_price,
    return_amount,
    return_reason,
    status,
    _source_file,
    _source_platform,
    _ingested_at,
    _batch_id,
    NOW() AS _processed_at
FROM source
WHERE return_id IS NOT NULL
  AND rn = 1