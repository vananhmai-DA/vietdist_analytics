DROP TABLE IF EXISTS staging.stg_distributor_orders;

CREATE TABLE staging.stg_distributor_orders AS
WITH source AS (
    SELECT
        NULLIF(TRIM(order_id), '') AS order_id,

        CAST(NULLIF(TRIM(order_date), '') AS DATE) AS order_date,
        CAST(NULLIF(TRIM(order_month), '') AS INTEGER) AS order_month,
        NULLIF(TRIM(order_quarter), '') AS order_quarter,

        NULLIF(TRIM(distributor_id), '') AS distributor_id,
        NULLIF(TRIM(region), '') AS region,
        NULLIF(TRIM(channel), '') AS channel,
        NULLIF(TRIM(product_id), '') AS product_id,
        NULLIF(TRIM(product_category), '') AS product_category,

        CAST(NULLIF(TRIM(qty_ordered), '') AS NUMERIC) AS qty_ordered,
        CAST(NULLIF(TRIM(qty_delivered), '') AS NUMERIC) AS qty_delivered,
        CAST(NULLIF(TRIM(fill_rate_pct), '') AS NUMERIC) AS fill_rate_pct,

        CAST(NULLIF(TRIM(unit_price_list), '') AS NUMERIC) AS unit_price_list,
        CAST(NULLIF(TRIM(distributor_price), '') AS NUMERIC) AS distributor_price,
        CAST(NULLIF(TRIM(gross_amount), '') AS NUMERIC) AS gross_amount,
        CAST(NULLIF(TRIM(delivered_amount), '') AS NUMERIC) AS delivered_amount,

        CAST(NULLIF(TRIM(expected_delivery_date), '') AS DATE) AS expected_delivery_date,
        CAST(NULLIF(TRIM(actual_delivery_date), '') AS DATE) AS actual_delivery_date,

        NULLIF(TRIM(ontime_delivery), '') AS on_time_delivery,
        NULLIF(TRIM(delivery_status), '') AS delivery_status,
        NULLIF(TRIM(payment_terms), '') AS payment_terms,

        _source_file,
        _source_platform,
        _ingested_at,
        _batch_id,

        ROW_NUMBER() OVER (
            PARTITION BY order_id, distributor_id, product_id
            ORDER BY _ingested_at DESC
        ) AS rn
    FROM raw.distributor_orders
    WHERE order_id IS NOT NULL
      AND distributor_id IS NOT NULL
      AND product_id IS NOT NULL
      AND LOWER(TRIM(order_id)) NOT IN ('nan', 'none', 'null', '')
      AND LOWER(TRIM(distributor_id)) NOT IN ('nan', 'none', 'null', '')
      AND LOWER(TRIM(product_id)) NOT IN ('nan', 'none', 'null', '')
)

SELECT
    order_id,
    order_date,
    order_month,
    order_quarter,
    distributor_id,
    region,
    channel,
    product_id,
    product_category,
    qty_ordered,
    qty_delivered,
    fill_rate_pct,
    unit_price_list,
    distributor_price,
    gross_amount,
    delivered_amount,
    expected_delivery_date,
    actual_delivery_date,
    on_time_delivery,
    delivery_status,
    payment_terms,
    _source_file,
    _source_platform,
    _ingested_at,
    _batch_id
FROM source
WHERE rn = 1;