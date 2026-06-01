{{ 
    config(
        materialized='incremental',
        unique_key='promotion_id',
        incremental_strategy='delete+insert'
    ) 
}}

WITH latest_success_batch AS (
    SELECT
        batch_id
    FROM {{ source('raw', 'ingest_log') }}
    WHERE source_name = 'promotion_program'
      AND status = 'SUCCESS'
    ORDER BY finished_at DESC
    LIMIT 1
),

source AS (
    SELECT
        CASE
            WHEN promotion_id IS NULL
              OR LOWER(TRIM(promotion_id)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(promotion_id)
        END AS promotion_id,

        CASE
            WHEN promotion_name IS NULL
              OR LOWER(TRIM(promotion_name)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(promotion_name)
        END AS promotion_name,

        CASE
            WHEN promotion_type IS NULL
              OR LOWER(TRIM(promotion_type)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(promotion_type)
        END AS promotion_type,

        CASE
            WHEN target_channel IS NULL
              OR LOWER(TRIM(target_channel)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(target_channel)
        END AS target_channel,

        CASE
            WHEN target_region IS NULL
              OR LOWER(TRIM(target_region)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(target_region)
        END AS target_region,

        CASE
            WHEN start_date IS NULL
              OR LOWER(TRIM(start_date)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN TRIM(start_date) ~ '^\d{4}-\d{2}-\d{2}$'
            THEN TRIM(start_date)::DATE
            WHEN TRIM(start_date) ~ '^\d{1,2}/\d{1,2}/\d{4}$'
            THEN TO_DATE(TRIM(start_date), 'DD/MM/YYYY')
            ELSE NULL
        END AS start_date,

        CASE
            WHEN end_date IS NULL
              OR LOWER(TRIM(end_date)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN TRIM(end_date) ~ '^\d{4}-\d{2}-\d{2}$'
            THEN TRIM(end_date)::DATE
            WHEN TRIM(end_date) ~ '^\d{1,2}/\d{1,2}/\d{4}$'
            THEN TO_DATE(TRIM(end_date), 'DD/MM/YYYY')
            ELSE NULL
        END AS end_date,

        CASE
            WHEN applicable_products IS NULL
              OR LOWER(TRIM(applicable_products)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(applicable_products)
        END AS applicable_products,

        CASE
            WHEN discount_pct IS NULL
              OR LOWER(TRIM(discount_pct)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN REGEXP_REPLACE(TRIM(discount_pct), '[,% ]', '', 'g') ~ '^-?\d+(\.\d+)?$'
            THEN REGEXP_REPLACE(TRIM(discount_pct), '[,% ]', '', 'g')::NUMERIC
            ELSE NULL
        END AS discount_pct,

        CASE
            WHEN min_order_quantity IS NULL
              OR LOWER(TRIM(min_order_quantity)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN REGEXP_REPLACE(TRIM(min_order_quantity), '[, ]', '', 'g') ~ '^-?\d+(\.\d+)?$'
            THEN REGEXP_REPLACE(TRIM(min_order_quantity), '[, ]', '', 'g')::NUMERIC
            ELSE NULL
        END AS min_order_quantity,

        CASE
            WHEN budget_vnd IS NULL
              OR LOWER(TRIM(budget_vnd)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN REGEXP_REPLACE(TRIM(budget_vnd), '[, ]', '', 'g') ~ '^-?\d+(\.\d+)?$'
            THEN REGEXP_REPLACE(TRIM(budget_vnd), '[, ]', '', 'g')::NUMERIC
            ELSE NULL
        END AS budget_vnd,

        CASE
            WHEN actual_cost_vnd IS NULL
              OR LOWER(TRIM(actual_cost_vnd)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN REGEXP_REPLACE(TRIM(actual_cost_vnd), '[, ]', '', 'g') ~ '^-?\d+(\.\d+)?$'
            THEN REGEXP_REPLACE(TRIM(actual_cost_vnd), '[, ]', '', 'g')::NUMERIC
            ELSE NULL
        END AS actual_cost_vnd,

        CASE
            WHEN status IS NULL
              OR LOWER(TRIM(status)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(status)
        END AS status,

        CASE
            WHEN created_by IS NULL
              OR LOWER(TRIM(created_by)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(created_by)
        END AS created_by,

        _source_file,
        _source_platform,
        _ingested_at,
        _batch_id,

        ROW_NUMBER() OVER (
            PARTITION BY TRIM(promotion_id)
            ORDER BY _ingested_at DESC
        ) AS rn

    FROM {{ source('raw', 'promotion_program') }}
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
    promotion_id,
    promotion_name,
    promotion_type,
    target_channel,
    target_region,
    start_date,
    end_date,
    applicable_products,
    discount_pct,
    min_order_quantity,
    budget_vnd,
    actual_cost_vnd,
    status,
    created_by,
    _source_file,
    _source_platform,
    _ingested_at,
    _batch_id,
    NOW() AS _processed_at
FROM source
WHERE promotion_id IS NOT NULL
  AND rn = 1