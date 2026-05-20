DROP TABLE IF EXISTS staging.stg_sales_targets_versioned;

CREATE TABLE staging.stg_sales_targets_versioned AS
WITH source AS (
    SELECT
        NULLIF(TRIM(version_label), '') AS version_label,

        CASE
            WHEN version_label ~ 'v[0-9]+'
            THEN CAST(REPLACE(LOWER(version_label), 'v', '') AS INTEGER)
            ELSE NULL
        END AS version_rank,

        CASE
            WHEN LOWER(TRIM(version_date)) IN ('', 'nan', 'none', 'null', 'nat')
            THEN NULL
            ELSE CAST(version_date AS DATE)
        END AS version_date,

        CASE
            WHEN LOWER(TRIM(effective_from)) IN ('', 'nan', 'none', 'null', 'nat')
            THEN NULL
            ELSE CAST(effective_from AS DATE)
        END AS effective_from,

        CASE
            WHEN LOWER(TRIM(effective_to)) IN ('', 'nan', 'none', 'null', 'nat')
            THEN NULL
            ELSE CAST(effective_to AS DATE)
        END AS effective_to,

        NULLIF(TRIM(employee_id), '') AS employee_id,
        NULLIF(TRIM(employee_name), '') AS employee_name,
        NULLIF(TRIM(region), '') AS region,
        NULLIF(TRIM(team), '') AS team,

        CAST(CAST(NULLIF(TRIM(year), '') AS NUMERIC) AS INTEGER) AS target_year,
        CAST(CAST(NULLIF(TRIM(month), '') AS NUMERIC) AS INTEGER) AS target_month,
        NULLIF(TRIM(month_col), '') AS month_col,

        MAKE_DATE(
            CAST(CAST(NULLIF(TRIM(year), '') AS NUMERIC) AS INTEGER),
            CAST(CAST(NULLIF(TRIM(month), '') AS NUMERIC) AS INTEGER),
            1
        ) AS target_month_date,

        CAST(NULLIF(TRIM(target_revenue), '') AS NUMERIC) AS target_revenue,
        CAST(NULLIF(TRIM(target_quantity), '') AS NUMERIC) AS target_quantity,
        CAST(NULLIF(TRIM(target_new_customers), '') AS NUMERIC) AS target_new_customers,

        NULLIF(TRIM(sheet_name), '') AS sheet_name,

        _source_file,
        _source_platform,
        _ingested_at,
        _batch_id,

        ROW_NUMBER() OVER (
            PARTITION BY version_label, employee_id, year, month_col
            ORDER BY _ingested_at DESC
        ) AS rn_version
    FROM raw.sales_targets_raw
    WHERE version_label IS NOT NULL
      AND employee_id IS NOT NULL
      AND month_col IS NOT NULL
      AND LOWER(TRIM(version_label)) NOT IN ('nan', 'none', 'null', '')
      AND LOWER(TRIM(employee_id)) NOT IN ('nan', 'none', 'null', '')
      AND month_col ~ '^T([1-9]|1[0-2])$'
),

deduped AS (
    SELECT *
    FROM source
    WHERE rn_version = 1
),

ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY employee_id, target_year, target_month
            ORDER BY version_rank DESC, version_date DESC, _ingested_at DESC
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

    CASE WHEN rn_latest = 1 THEN TRUE ELSE FALSE END AS is_latest,

    _source_file,
    _source_platform,
    _ingested_at,
    _batch_id
FROM ranked;