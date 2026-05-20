DROP TABLE IF EXISTS staging.stg_return_transactions;

CREATE TABLE staging.stg_return_transactions AS
WITH source AS (
    SELECT
        NULLIF(TRIM(return_id), '') AS return_id,
        NULLIF(TRIM(original_order_id), '') AS original_order_id,

        CAST(NULLIF(TRIM(return_date), '') AS DATE) AS return_date,
        CAST(NULLIF(TRIM(return_month), '') AS INTEGER) AS return_month,

        NULLIF(TRIM(customer_id), '') AS customer_id,
        NULLIF(TRIM(employee_id), '') AS employee_id,
        NULLIF(TRIM(product_id), '') AS product_id,
        NULLIF(TRIM(region), '') AS region,
        NULLIF(TRIM(province), '') AS province,

        CAST(NULLIF(TRIM(return_quantity), '') AS NUMERIC) AS return_quantity,
        CAST(NULLIF(TRIM(unit_price), '') AS NUMERIC) AS unit_price,
        CAST(NULLIF(TRIM(return_amount), '') AS NUMERIC) AS return_amount,

        NULLIF(TRIM(return_reason), '') AS return_reason,
        NULLIF(TRIM(status), '') AS status,

        _source_file,
        _source_platform,
        _ingested_at,
        _batch_id,

        ROW_NUMBER() OVER (
            PARTITION BY return_id
            ORDER BY _ingested_at DESC
        ) AS rn
    FROM raw.return_transactions
    WHERE return_id IS NOT NULL
      AND LOWER(TRIM(return_id)) NOT IN ('nan', 'none', 'null', '')
)

SELECT
    return_id,
    original_order_id,
    return_date,
    return_month,
    customer_id,
    employee_id,
    product_id,
    region,
    province,
    return_quantity,
    unit_price,
    return_amount,
    return_reason,
    status,
    _source_file,
    _source_platform,
    _ingested_at,
    _batch_id
FROM source
WHERE rn = 1;