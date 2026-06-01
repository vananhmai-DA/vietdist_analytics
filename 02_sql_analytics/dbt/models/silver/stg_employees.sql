{{ config(materialized='table') }}

WITH latest_success_batch AS (
    SELECT
        batch_id
    FROM {{ source('raw', 'ingest_log') }}
    WHERE source_name = 'employee_master'
      AND status = 'SUCCESS'
    ORDER BY finished_at DESC
    LIMIT 1
),

source AS (
    SELECT
        CASE
            WHEN employee_id IS NULL
              OR LOWER(TRIM(employee_id)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(employee_id)
        END AS employee_id,

        CASE
            WHEN full_name IS NULL
              OR LOWER(TRIM(full_name)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(full_name)
        END AS full_name,

        CASE
            WHEN gender IS NULL
              OR LOWER(TRIM(gender)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(gender)
        END AS gender,

        CASE
            WHEN date_of_birth IS NULL
              OR LOWER(TRIM(date_of_birth)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN TRIM(date_of_birth) ~ '^\d{4}-\d{2}-\d{2}$'
            THEN TRIM(date_of_birth)::DATE
            WHEN TRIM(date_of_birth) ~ '^\d{1,2}/\d{1,2}/\d{4}$'
            THEN TO_DATE(TRIM(date_of_birth), 'DD/MM/YYYY')
            ELSE NULL
        END AS date_of_birth,

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
            WHEN position IS NULL
              OR LOWER(TRIM(position)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(position)
        END AS position,

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
            WHEN email IS NULL
              OR LOWER(TRIM(email)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE LOWER(TRIM(email))
        END AS email,

        CASE
            WHEN phone IS NULL
              OR LOWER(TRIM(phone)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(phone)
        END AS phone,

        CASE
            WHEN status IS NULL
              OR LOWER(TRIM(status)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(status)
        END AS status,

        CASE
            WHEN version IS NULL
              OR LOWER(TRIM(version)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(version)
        END AS version,

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
            WHEN resign_date IS NULL
              OR LOWER(TRIM(resign_date)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN TRIM(resign_date) ~ '^\d{4}-\d{2}-\d{2}$'
            THEN TRIM(resign_date)::DATE
            WHEN TRIM(resign_date) ~ '^\d{1,2}/\d{1,2}/\d{4}$'
            THEN TO_DATE(TRIM(resign_date), 'DD/MM/YYYY')
            ELSE NULL
        END AS resign_date,

        CASE
            WHEN transfer_note IS NULL
              OR LOWER(TRIM(transfer_note)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(transfer_note)
        END AS transfer_note,

        _source_file,
        _source_platform,
        _ingested_at,
        _batch_id,

        ROW_NUMBER() OVER (
            PARTITION BY
                TRIM(employee_id),
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

    FROM {{ source('raw', 'employee_master') }}
    WHERE _batch_id = (
        SELECT batch_id
        FROM latest_success_batch
    )
)

SELECT
    employee_id,
    full_name,
    gender,
    date_of_birth,
    join_date,
    position,
    region,
    team,
    email,
    phone,
    status,
    version,
    effective_date,
    resign_date,
    transfer_note,
    _source_file,
    _source_platform,
    _ingested_at,
    _batch_id,
    NOW() AS _processed_at
FROM source
WHERE employee_id IS NOT NULL
  AND rn = 1