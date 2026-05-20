DROP TABLE IF EXISTS staging.stg_territory_mapping;

CREATE TABLE staging.stg_territory_mapping AS
WITH source AS (
    SELECT
        NULLIF(TRIM(territory_id), '') AS territory_id,
        NULLIF(TRIM(employee_id), '') AS employee_id,
        NULLIF(TRIM(customer_id), '') AS customer_id,
        NULLIF(TRIM(region), '') AS region,
        NULLIF(TRIM(team), '') AS team,

        CAST(NULLIF(TRIM(effective_date), '') AS DATE) AS effective_date,
        CAST(NULLIF(TRIM(expiry_date), '') AS DATE) AS expiry_date,

        NULLIF(TRIM(version), '') AS version,

        _source_file,
        _source_platform,
        _ingested_at,
        _batch_id,

        ROW_NUMBER() OVER (
            PARTITION BY territory_id, employee_id, customer_id, effective_date
            ORDER BY _ingested_at DESC
        ) AS rn
    FROM raw.territory_mapping
    WHERE territory_id IS NOT NULL
      AND employee_id IS NOT NULL
      AND customer_id IS NOT NULL
      AND LOWER(TRIM(territory_id)) NOT IN ('nan', 'none', 'null', '')
      AND LOWER(TRIM(employee_id)) NOT IN ('nan', 'none', 'null', '')
      AND LOWER(TRIM(customer_id)) NOT IN ('nan', 'none', 'null', '')
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
    _batch_id
FROM source
WHERE rn = 1;