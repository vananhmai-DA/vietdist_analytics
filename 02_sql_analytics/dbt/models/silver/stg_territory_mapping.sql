{{ 
    config(
        materialized='incremental',
        unique_key=['territory_id', 'employee_id', 'customer_id', 'effective_date'],
        incremental_strategy='delete+insert'
    ) 
}}

WITH latest_success_batch AS (
    SELECT
        batch_id
    FROM {{ source('raw', 'ingest_log') }}
    WHERE source_name = 'territory_mapping'
      AND status = 'SUCCESS'
    ORDER BY finished_at DESC
    LIMIT 1
),

source AS (
    SELECT
        CASE
            WHEN territory_id IS NULL
              OR LOWER(TRIM(territory_id)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(territory_id)
        END AS territory_id,

        CASE
            WHEN employee_id IS NULL
              OR LOWER(TRIM(employee_id)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(employee_id)
        END AS employee_id,

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
            WHEN team IS NULL
              OR LOWER(TRIM(team)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(team)
        END AS team,

        CASE
            WHEN effective_date IS NULL
              OR LOWER(TRIM(effective_date)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN TRIM(effective_date) ~ '^\d{4}-\d{2}-\d{2}$'
            THEN TRIM(effective_date)::DATE
            WHEN TRIM(effective_date) ~ '^\d{1,2}/\d{1,2}/\d{4}$'
            THEN TO_DATE(TRIM(effective_date), 'DD/MM/YYYY')
            ELSE NULL
        END AS effective_date,

        CASE
            WHEN expiry_date IS NULL
              OR LOWER(TRIM(expiry_date)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN TRIM(expiry_date) ~ '^\d{4}-\d{2}-\d{2}$'
            THEN TRIM(expiry_date)::DATE
            WHEN TRIM(expiry_date) ~ '^\d{1,2}/\d{1,2}/\d{4}$'
            THEN TO_DATE(TRIM(expiry_date), 'DD/MM/YYYY')
            ELSE NULL
        END AS expiry_date,

        CASE
            WHEN version IS NULL
              OR LOWER(TRIM(version)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(version)
        END AS version,

        _source_file,
        _source_platform,
        _ingested_at,
        _batch_id,

        ROW_NUMBER() OVER (
            PARTITION BY
                TRIM(territory_id),
                TRIM(employee_id),
                TRIM(customer_id),
                CASE
                    WHEN effective_date IS NULL
                      OR LOWER(TRIM(effective_date)) IN ('', 'nan', 'none', 'null')
                    THEN NULL
                    WHEN TRIM(effective_date) ~ '^\d{4}-\d{2}-\d{2}$'
                    THEN TRIM(effective_date)::DATE
                    WHEN TRIM(effective_date) ~ '^\d{1,2}/\d{1,2}/\d{4}$'
                    THEN TO_DATE(TRIM(effective_date), 'DD/MM/YYYY')
                    ELSE NULL
                END
            ORDER BY _ingested_at DESC
        ) AS rn

    FROM {{ source('raw', 'territory_mapping') }}
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
    territory_id,
    employee_id,
    customer_id,
    region,
    team,
    effective_date,
    expiry_date,
    version,
    _source_file,
    _source_platform,
    _ingested_at,
    _batch_id,
    NOW() AS _processed_at
FROM source
WHERE territory_id IS NOT NULL
  AND employee_id IS NOT NULL
  AND customer_id IS NOT NULL
  AND effective_date IS NOT NULL
  AND rn = 1