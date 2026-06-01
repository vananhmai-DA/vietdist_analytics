{{ config(materialized='table') }}

SELECT
    -- Fact grain key: one row per employee + target month + latest version
    t.employee_id || '_' || TO_CHAR(t.target_month_date, 'YYYYMMDD') AS target_key,

    -- Foreign keys
    d.date_key AS target_date_key,
    e.employee_key,

    -- Natural keys
    t.employee_id,
    t.employee_name,
    t.target_year,
    t.target_month,
    t.month_col,
    t.target_month_date,

    -- Version info
    t.version_label,
    t.version_rank,
    t.version_date,
    t.effective_from,
    t.effective_to,
    t.is_latest,

    -- Descriptive fields
    t.region,
    t.team,

    -- Measures
    t.target_revenue,
    t.target_quantity,
    t.target_new_customers,

    -- Metadata
    t._source_file,
    t._source_platform,
    t._ingested_at,
    t._batch_id,
    t._processed_at

FROM {{ ref('stg_sales_targets_versioned') }} t

LEFT JOIN {{ ref('dim_dates') }} d
    ON t.target_month_date = d.date_day

LEFT JOIN {{ ref('dim_employees') }} e
    ON t.employee_id = e.employee_id
   AND t.target_month_date BETWEEN e.effective_from AND e.effective_to

WHERE t.is_latest = TRUE