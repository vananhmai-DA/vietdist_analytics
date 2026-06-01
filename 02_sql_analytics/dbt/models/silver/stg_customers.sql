{{ 
    config(
        materialized='incremental',
        unique_key='customer_id',
        incremental_strategy='delete+insert'
    ) 
}}

WITH latest_success_batch AS (
    SELECT
        batch_id
    FROM {{ source('raw', 'ingest_log') }}
    WHERE source_name = 'customer_master'
      AND status = 'SUCCESS'
    ORDER BY finished_at DESC
    LIMIT 1
),

source AS (
    SELECT
        CASE
            WHEN customer_id IS NULL
              OR LOWER(TRIM(customer_id)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(customer_id)
        END AS customer_id,

        CASE
            WHEN customer_name IS NULL
              OR LOWER(TRIM(customer_name)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(customer_name)
        END AS customer_name,

        CASE
            WHEN customer_type IS NULL
              OR LOWER(TRIM(customer_type)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(customer_type)
        END AS customer_type,

        CASE
            WHEN channel IS NULL
              OR LOWER(TRIM(channel)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(channel)
        END AS channel,

        CASE
            WHEN province IS NULL
              OR LOWER(TRIM(province)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(province)
        END AS province,

        CASE
            WHEN region IS NULL
              OR LOWER(TRIM(region)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(region)
        END AS region,

        CASE
            WHEN address IS NULL
              OR LOWER(TRIM(address)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(address)
        END AS address,

        CASE
            WHEN phone IS NULL
              OR LOWER(TRIM(phone)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(phone)
        END AS phone,

        CASE
            WHEN tax_code IS NULL
              OR LOWER(TRIM(tax_code)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(tax_code)
        END AS tax_code,

        CASE
            WHEN status IS NULL
              OR LOWER(TRIM(status)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(status)
        END AS status,

        CASE
            WHEN join_date IS NULL
              OR LOWER(TRIM(join_date)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN TRIM(join_date) ~ '^\d{4}-\d{2}-\d{2}$'
            THEN TRIM(join_date)::DATE
            WHEN TRIM(join_date) ~ '^\d{1,2}/\d{1,2}/\d{4}$'
            THEN TO_DATE(TRIM(join_date), 'DD/MM/YYYY')
            ELSE NULL
        END AS join_date,

        CASE
            WHEN credit_limit IS NULL
              OR LOWER(TRIM(credit_limit)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN REGEXP_REPLACE(TRIM(credit_limit), '[, ]', '', 'g') ~ '^-?\d+(\.\d+)?$'
            THEN REGEXP_REPLACE(TRIM(credit_limit), '[, ]', '', 'g')::NUMERIC
            ELSE NULL
        END AS credit_limit,

        _source_file,
        _source_platform,
        _ingested_at,
        _batch_id,

        ROW_NUMBER() OVER (
            PARTITION BY TRIM(customer_id)
            ORDER BY _ingested_at DESC
        ) AS rn

    FROM {{ source('raw', 'customer_master') }}
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
    customer_id,
    customer_name,
    customer_type,
    channel,
    province,
    region,
    address,
    phone,
    tax_code,
    join_date,
    credit_limit,
    status,
    _source_file,
    _source_platform,
    _ingested_at,
    _batch_id,
    NOW() AS _processed_at
FROM source
WHERE customer_id IS NOT NULL
  AND rn = 1