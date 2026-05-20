DROP TABLE IF EXISTS staging.stg_promotion_program;

CREATE TABLE staging.stg_promotion_program AS
WITH source AS (
    SELECT
        NULLIF(TRIM(promotion_id), '') AS promotion_id,
        NULLIF(TRIM(promotion_name), '') AS promotion_name,
        NULLIF(TRIM(promotion_type), '') AS promotion_type,
        NULLIF(TRIM(target_channel), '') AS target_channel,
        NULLIF(TRIM(target_region), '') AS target_region,

        CAST(NULLIF(TRIM(start_date), '') AS DATE) AS start_date,
        CAST(NULLIF(TRIM(end_date), '') AS DATE) AS end_date,

        NULLIF(TRIM(applicable_products), '') AS applicable_products,

        CAST(NULLIF(TRIM(discount_pct), '') AS NUMERIC) AS discount_pct,
        CAST(NULLIF(TRIM(min_order_quantity), '') AS NUMERIC) AS min_order_quantity,
        CAST(NULLIF(TRIM(budget_vnd), '') AS NUMERIC) AS budget_vnd,
        CAST(NULLIF(TRIM(actual_cost_vnd), '') AS NUMERIC) AS actual_cost_vnd,

        NULLIF(TRIM(status), '') AS status,
        NULLIF(TRIM(created_by), '') AS created_by,

        _source_file,
        _source_platform,
        _ingested_at,
        _batch_id,

        ROW_NUMBER() OVER (
            PARTITION BY promotion_id
            ORDER BY _ingested_at DESC
        ) AS rn
    FROM raw.promotion_program
    WHERE promotion_id IS NOT NULL
      AND LOWER(TRIM(promotion_id)) NOT IN ('nan', 'none', 'null', '')
)

SELECT
    promotion_id,
    promotion_name,
    promotion_type,
    target_channel,
    target_region,
    start_date,
    end_date,
    applicable_products,
    discount_pct,
    min_order_quantity,
    budget_vnd,
    actual_cost_vnd,
    status,
    created_by,
    _source_file,
    _source_platform,
    _ingested_at,
    _batch_id
FROM source
WHERE rn = 1;