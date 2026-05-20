DROP TABLE IF EXISTS staging.stg_distributors;

CREATE TABLE staging.stg_distributors AS
WITH source AS (
    SELECT
        NULLIF(TRIM(distributor_id), '') AS distributor_id,
        NULLIF(TRIM(distributor_name), '') AS distributor_name,
        NULLIF(TRIM(tier), '') AS tier,
        NULLIF(TRIM(channel), '') AS channel,
        NULLIF(TRIM(province), '') AS province,
        NULLIF(TRIM(region), '') AS region,
        NULLIF(TRIM(contact_person), '') AS contact_person,
        NULLIF(TRIM(phone), '') AS phone,
        NULLIF(TRIM(email), '') AS email,
        NULLIF(TRIM(tax_code), '') AS tax_code,

        CAST(NULLIF(TRIM(join_date), '') AS DATE) AS join_date,
        CAST(NULLIF(TRIM(credit_limit), '') AS NUMERIC) AS credit_limit,

        NULLIF(TRIM(status), '') AS status,
        NULLIF(TRIM(assigned_supervisor_id), '') AS assigned_supervisor_id,

        _source_file,
        _source_platform,
        _ingested_at,
        _batch_id,

        ROW_NUMBER() OVER (
            PARTITION BY distributor_id
            ORDER BY _ingested_at DESC
        ) AS rn
    FROM raw.distributor_master
    WHERE distributor_id IS NOT NULL
      AND LOWER(TRIM(distributor_id)) NOT IN ('nan', 'none', 'null', '')
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
    _batch_id
FROM source
WHERE rn = 1;