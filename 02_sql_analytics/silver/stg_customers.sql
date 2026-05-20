DROP TABLE IF EXISTS staging.stg_customers;

CREATE TABLE staging.stg_customers AS
WITH source AS (
    SELECT
        NULLIF(TRIM(customer_id), '') AS customer_id,
        NULLIF(TRIM(customer_name), '') AS customer_name,
        NULLIF(TRIM(customer_type), '') AS customer_type,
        NULLIF(TRIM(channel), '') AS channel,
        NULLIF(TRIM(province), '') AS province,
        NULLIF(TRIM(region), '') AS region,
        NULLIF(TRIM(address), '') AS address,
        NULLIF(TRIM(phone), '') AS phone,
        NULLIF(TRIM(tax_code), '') AS tax_code,
        NULLIF(TRIM(status), '') AS status,

        CAST(NULLIF(TRIM(join_date), '') AS DATE) AS join_date,
        CAST(NULLIF(TRIM(credit_limit), '') AS NUMERIC) AS credit_limit,

        _source_file,
        _source_platform,
        _ingested_at,
        _batch_id,

        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY _ingested_at DESC
        ) AS rn
    FROM raw.customer_master
    WHERE customer_id IS NOT NULL
      AND LOWER(TRIM(customer_id)) NOT IN ('nan', 'none', 'null', '')
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
    _batch_id
FROM source
WHERE rn = 1;