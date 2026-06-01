{{ 
    config(
        materialized='incremental',
        unique_key='product_id',
        incremental_strategy='delete+insert'
    ) 
}}

WITH latest_success_batch AS (
    SELECT
        batch_id
    FROM {{ source('raw', 'ingest_log') }}
    WHERE source_name = 'product_master'
      AND status = 'SUCCESS'
    ORDER BY finished_at DESC
    LIMIT 1
),

source AS (
    SELECT
        CASE
            WHEN product_id IS NULL
              OR LOWER(TRIM(product_id)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(product_id)
        END AS product_id,

        CASE
            WHEN product_name IS NULL
              OR LOWER(TRIM(product_name)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(product_name)
        END AS product_name,

        CASE
            WHEN category IS NULL
              OR LOWER(TRIM(category)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(category)
        END AS category,

        CASE
            WHEN sub_category IS NULL
              OR LOWER(TRIM(sub_category)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(sub_category)
        END AS sub_category,

        CASE
            WHEN unit IS NULL
              OR LOWER(TRIM(unit)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(unit)
        END AS unit,

        CASE
            WHEN unit_price IS NULL
              OR LOWER(TRIM(unit_price)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN REGEXP_REPLACE(TRIM(unit_price), '[, ]', '', 'g') ~ '^-?\d+(\.\d+)?$'
            THEN REGEXP_REPLACE(TRIM(unit_price), '[, ]', '', 'g')::NUMERIC
            ELSE NULL
        END AS unit_price,

        CASE
            WHEN cost_price IS NULL
              OR LOWER(TRIM(cost_price)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN REGEXP_REPLACE(TRIM(cost_price), '[, ]', '', 'g') ~ '^-?\d+(\.\d+)?$'
            THEN REGEXP_REPLACE(TRIM(cost_price), '[, ]', '', 'g')::NUMERIC
            ELSE NULL
        END AS cost_price,

        CASE
            WHEN weight_gram IS NULL
              OR LOWER(TRIM(weight_gram)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN REGEXP_REPLACE(TRIM(weight_gram), '[, ]', '', 'g') ~ '^-?\d+(\.\d+)?$'
            THEN REGEXP_REPLACE(TRIM(weight_gram), '[, ]', '', 'g')::NUMERIC
            ELSE NULL
        END AS weight_gram,

        CASE
            WHEN status IS NULL
              OR LOWER(TRIM(status)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(status)
        END AS status,

        CASE
            WHEN launch_date IS NULL
              OR LOWER(TRIM(launch_date)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN TRIM(launch_date) ~ '^\d{4}-\d{2}-\d{2}$'
            THEN TRIM(launch_date)::DATE
            WHEN TRIM(launch_date) ~ '^\d{1,2}/\d{1,2}/\d{4}$'
            THEN TO_DATE(TRIM(launch_date), 'DD/MM/YYYY')
            ELSE NULL
        END AS launch_date,

        _source_file,
        _source_platform,
        _ingested_at,
        _batch_id,

        ROW_NUMBER() OVER (
            PARTITION BY TRIM(product_id)
            ORDER BY _ingested_at DESC
        ) AS rn

    FROM {{ source('raw', 'product_master') }}
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
    product_id,
    product_name,
    category,
    sub_category,
    unit,
    unit_price,
    cost_price,
    weight_gram,
    status,
    launch_date,
    _source_file,
    _source_platform,
    _ingested_at,
    _batch_id,
    NOW() AS _processed_at
FROM source
WHERE product_id IS NOT NULL
  AND rn = 1