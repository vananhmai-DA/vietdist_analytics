DROP TABLE IF EXISTS dwh.dim_products;

CREATE TABLE dwh.dim_products AS
SELECT
    product_id AS product_key,
    product_id,
    product_name,
    category,
    sub_category,
    unit,
    unit_price,
    cost_price,
    weight_gram,
    status,
    launch_date,

    CASE
        WHEN unit_price IS NULL OR cost_price IS NULL THEN NULL
        ELSE unit_price - cost_price
    END AS unit_margin,

    CASE
        WHEN unit_price IS NULL OR unit_price = 0 OR cost_price IS NULL THEN NULL
        ELSE ROUND(((unit_price - cost_price) / unit_price) * 100, 2)
    END AS unit_margin_pct,

    _source_file,
    _source_platform,
    _ingested_at,
    _batch_id
FROM staging.stg_products;