{{ config(materialized='table') }}

WITH source AS (
    SELECT
        CASE
            WHEN version_label IS NULL
              OR LOWER(TRIM(version_label)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE LOWER(TRIM(version_label))
        END AS version_label,

        CASE
            WHEN version_label IS NOT NULL
              AND LOWER(TRIM(version_label)) ~ '^v[0-9]+$'
            THEN REPLACE(LOWER(TRIM(version_label)), 'v', '')::INTEGER
            ELSE NULL
        END AS version_rank,

        CASE
            WHEN version_date IS NULL
              OR LOWER(TRIM(version_date)) IN ('', 'nan', 'none', 'null', 'nat')
            THEN NULL
            WHEN TRIM(version_date) ~ '^\d{4}-\d{2}-\d{2}$'
            THEN TRIM(version_date)::DATE
            WHEN TRIM(version_date) ~ '^\d{1,2}/\d{1,2}/\d{4}$'
            THEN TO_DATE(TRIM(version_date), 'DD/MM/YYYY')
            ELSE NULL
        END AS version_date,

        CASE
            WHEN effective_from IS NULL
              OR LOWER(TRIM(effective_from)) IN ('', 'nan', 'none', 'null', 'nat')
            THEN NULL
            WHEN TRIM(effective_from) ~ '^\d{4}-\d{2}-\d{2}$'
            THEN TRIM(effective_from)::DATE
            WHEN TRIM(effective_from) ~ '^\d{1,2}/\d{1,2}/\d{4}$'
            THEN TO_DATE(TRIM(effective_from), 'DD/MM/YYYY')
            ELSE NULL
        END AS effective_from,

        CASE
            WHEN effective_to IS NULL
              OR LOWER(TRIM(effective_to)) IN ('', 'nan', 'none', 'null', 'nat')
            THEN NULL
            WHEN TRIM(effective_to) ~ '^\d{4}-\d{2}-\d{2}$'
            THEN TRIM(effective_to)::DATE
            WHEN TRIM(effective_to) ~ '^\d{1,2}/\d{1,2}/\d{4}$'
            THEN TO_DATE(TRIM(effective_to), 'DD/MM/YYYY')
            ELSE NULL
        END AS effective_to,

        CASE
            WHEN employee_id IS NULL
              OR LOWER(TRIM(employee_id)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(employee_id)
        END AS employee_id,

        CASE
            WHEN employee_name IS NULL
              OR LOWER(TRIM(employee_name)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(employee_name)
        END AS employee_name,

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
            WHEN year IS NULL
              OR LOWER(TRIM(year)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN REGEXP_REPLACE(TRIM(year), '[, ]', '', 'g') ~ '^\d+(\.0)?$'
            THEN REGEXP_REPLACE(TRIM(year), '[, ]', '', 'g')::NUMERIC::INTEGER
            ELSE NULL
        END AS target_year,

        CASE
            WHEN month IS NULL
              OR LOWER(TRIM(month)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN REGEXP_REPLACE(TRIM(month), '[, ]', '', 'g') ~ '^\d+(\.0)?$'
            THEN REGEXP_REPLACE(TRIM(month), '[, ]', '', 'g')::NUMERIC::INTEGER
            ELSE NULL
        END AS target_month,

        CASE
            WHEN month_col IS NULL
              OR LOWER(TRIM(month_col)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE UPPER(TRIM(month_col))
        END AS month_col,

        CASE
            WHEN year IS NULL
              OR month IS NULL
              OR LOWER(TRIM(year)) IN ('', 'nan', 'none', 'null')
              OR LOWER(TRIM(month)) IN ('', 'nan', 'none', 'null')
              OR NOT (REGEXP_REPLACE(TRIM(year), '[, ]', '', 'g') ~ '^\d+(\.0)?$')
              OR NOT (REGEXP_REPLACE(TRIM(month), '[, ]', '', 'g') ~ '^\d+(\.0)?$')
              OR REGEXP_REPLACE(TRIM(month), '[, ]', '', 'g')::NUMERIC::INTEGER NOT BETWEEN 1 AND 12
            THEN NULL
            ELSE MAKE_DATE(
                REGEXP_REPLACE(TRIM(year), '[, ]', '', 'g')::NUMERIC::INTEGER,
                REGEXP_REPLACE(TRIM(month), '[, ]', '', 'g')::NUMERIC::INTEGER,
                1
            )
        END AS target_month_date,

        CASE
            WHEN target_revenue IS NULL
              OR LOWER(TRIM(target_revenue)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN REGEXP_REPLACE(TRIM(target_revenue), '[, ]', '', 'g') ~ '^-?\d+(\.\d+)?$'
            THEN REGEXP_REPLACE(TRIM(target_revenue), '[, ]', '', 'g')::NUMERIC
            ELSE NULL
        END AS target_revenue,

        CASE
            WHEN target_quantity IS NULL
              OR LOWER(TRIM(target_quantity)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN REGEXP_REPLACE(TRIM(target_quantity), '[, ]', '', 'g') ~ '^-?\d+(\.\d+)?$'
            THEN REGEXP_REPLACE(TRIM(target_quantity), '[, ]', '', 'g')::NUMERIC
            ELSE NULL
        END AS target_quantity,

        CASE
            WHEN target_new_customers IS NULL
              OR LOWER(TRIM(target_new_customers)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            WHEN REGEXP_REPLACE(TRIM(target_new_customers), '[, ]', '', 'g') ~ '^-?\d+(\.\d+)?$'
            THEN REGEXP_REPLACE(TRIM(target_new_customers), '[, ]', '', 'g')::NUMERIC
            ELSE NULL
        END AS target_new_customers,

        CASE
            WHEN sheet_name IS NULL
              OR LOWER(TRIM(sheet_name)) IN ('', 'nan', 'none', 'null')
            THEN NULL
            ELSE TRIM(sheet_name)
        END AS sheet_name,

        _source_file,
        _source_platform,
        _ingested_at,
        _batch_id,

        ROW_NUMBER() OVER (
            PARTITION BY
                LOWER(TRIM(version_label)),
                TRIM(employee_id),
                REGEXP_REPLACE(TRIM(year), '[, ]', '', 'g'),
                UPPER(TRIM(month_col))
            ORDER BY _ingested_at DESC
        ) AS rn_version

    FROM {{ source('raw', 'sales_targets_raw') }}
    WHERE version_label IS NOT NULL
      AND employee_id IS NOT NULL
      AND month_col IS NOT NULL
      AND LOWER(TRIM(version_label)) NOT IN ('', 'nan', 'none', 'null')
      AND LOWER(TRIM(employee_id)) NOT IN ('', 'nan', 'none', 'null')
      AND UPPER(TRIM(month_col)) ~ '^T([1-9]|1[0-2])$'
),

deduped AS (
    SELECT *
    FROM source
    WHERE rn_version = 1
      AND version_label IS NOT NULL
      AND employee_id IS NOT NULL
      AND target_year IS NOT NULL
      AND target_month IS NOT NULL
      AND target_month BETWEEN 1 AND 12
),

ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY employee_id, target_year, target_month
            ORDER BY
                version_rank DESC NULLS LAST,
                version_date DESC NULLS LAST,
                _ingested_at DESC
        ) AS rn_latest
    FROM deduped
)

SELECT
    version_label,
    version_rank,
    version_date,
    effective_from,
    effective_to,
    employee_id,
    employee_name,
    region,
    team,
    target_year,
    target_month,
    month_col,
    target_month_date,
    target_revenue,
    target_quantity,
    target_new_customers,
    sheet_name,

    CASE
        WHEN rn_latest = 1 THEN TRUE
        ELSE FALSE
    END AS is_latest,

    _source_file,
    _source_platform,
    _ingested_at,
    _batch_id,
    NOW() AS _processed_at
FROM ranked