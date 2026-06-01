{{ 
    config(
        materialized='incremental',
        unique_key='distributor_id',
        incremental_strategy='delete+insert'
    ) 
}}

WITH latest_success_batch AS (
    SELECT
        batch_id
    FROM {{ source('raw', 'ingest_log') }}
    WHERE source_name = 'distributor_master'
      AND status = 'SUCCESS'
    ORDER BY finished_at DESC
    LIMIT 1
),

source AS (
    SELECT
        CASE
            WHEN distributor_id IS NULL
              OR LOWER(TRIM(distributor_id)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(distributor_id)
        END AS distributor_id,

        CASE
            WHEN distributor_name IS NULL
              OR LOWER(TRIM(distributor_name)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(distributor_name)
        END AS distributor_name,

        CASE
            WHEN tier IS NULL
              OR LOWER(TRIM(tier)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(tier)
        END AS tier,

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
            WHEN contact_person IS NULL
              OR LOWER(TRIM(contact_person)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(contact_person)
        END AS contact_person,

        CASE
            WHEN phone IS NULL
              OR LOWER(TRIM(phone)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(phone)
        END AS phone,

        CASE
            WHEN email IS NULL
              OR LOWER(TRIM(email)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE LOWER(TRIM(email))
        END AS email,

        CASE
            WHEN tax_code IS NULL
              OR LOWER(TRIM(tax_code)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(tax_code)
        END AS tax_code,

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

        CASE
            WHEN status IS NULL
              OR LOWER(TRIM(status)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(status)
        END AS status,

        CASE
            WHEN assigned_supervisor_id IS NULL
              OR LOWER(TRIM(assigned_supervisor_id)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(assigned_supervisor_id)
        END AS assigned_supervisor_id,

        _source_file,
        _source_platform,
        _ingested_at,
        _batch_id,

        ROW_NUMBER() OVER (
            PARTITION BY TRIM(distributor_id)
            ORDER BY _ingested_at DESC
        ) AS rn

    FROM {{ source('raw', 'distributor_master') }}
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
    distributor_id,
    distributor_name,
    tier,
    channel,
    province,
    region,
    contact_person,
    phone,
    email,
    tax_code,
    join_date,
    credit_limit,
    status,
    assigned_supervisor_id,
    _source_file,
    _source_platform,
    _ingested_at,
    _batch_id,
    NOW() AS _processed_at
FROM source
WHERE distributor_id IS NOT NULL
  AND rn = 1