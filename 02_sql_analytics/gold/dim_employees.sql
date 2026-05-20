DROP TABLE IF EXISTS dwh.dim_employees;

CREATE TABLE dwh.dim_employees AS
WITH source AS (
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
        _batch_id
    FROM staging.stg_employees
),

scd AS (
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

        effective_date AS effective_from,

        COALESCE(
            LEAD(effective_date) OVER (
                PARTITION BY employee_id
                ORDER BY effective_date
            ) - INTERVAL '1 day',
            resign_date,
            DATE '9999-12-31'
        )::DATE AS effective_to,

        CASE
            WHEN LEAD(effective_date) OVER (
                PARTITION BY employee_id
                ORDER BY effective_date
            ) IS NULL
            THEN TRUE
            ELSE FALSE
        END AS is_current,

        resign_date,
        transfer_note,
        _source_file,
        _source_platform,
        _ingested_at,
        _batch_id
    FROM source
)

SELECT
    employee_id || '_' || TO_CHAR(effective_from, 'YYYYMMDD') AS employee_key,
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
    effective_from,
    effective_to,
    is_current,
    resign_date,
    transfer_note,
    _source_file,
    _source_platform,
    _ingested_at,
    _batch_id
FROM scd;