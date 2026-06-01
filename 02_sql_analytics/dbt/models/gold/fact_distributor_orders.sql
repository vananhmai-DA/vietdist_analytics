{{ 
    config(
        materialized='incremental',
        unique_key='distributor_order_line_key',
        incremental_strategy='delete+insert'
    ) 
}}

WITH source AS (
    SELECT
        *
    FROM {{ ref('stg_distributor_orders') }}

    {% if is_incremental() %}
      WHERE _processed_at > (
          SELECT COALESCE(MAX(_processed_at), TIMESTAMP '1900-01-01')
          FROM {{ this }}
      )
    {% endif %}
)

SELECT
    -- Fact grain key: one row per order_id + distributor_id + product_id
    o.order_id || '_' || o.distributor_id || '_' || o.product_id AS distributor_order_line_key,

    -- Degenerate dimension
    o.order_id,

    -- Foreign keys
    d.date_key AS order_date_key,
    dd_expected.date_key AS expected_delivery_date_key,
    dd_actual.date_key AS actual_delivery_date_key,
    dis.distributor_key,
    p.product_key,
    ch.channel_key,
    g.geography_key,

    -- Natural keys
    o.order_date,
    o.order_month,
    o.order_quarter,
    o.distributor_id,
    o.product_id,

    -- Descriptive fields
    o.region,
    o.channel,
    o.product_category,
    o.on_time_delivery,
    o.delivery_status,
    o.payment_terms,

    -- Delivery dates
    o.expected_delivery_date,
    o.actual_delivery_date,

    -- Measures
    o.qty_ordered,
    o.qty_delivered,
    o.fill_rate_pct,
    o.unit_price_list,
    o.distributor_price,
    o.gross_amount,
    o.delivered_amount,

    CASE
        WHEN o.qty_ordered IS NULL
          OR o.qty_ordered = 0
        THEN NULL
        ELSE ROUND((o.qty_delivered / o.qty_ordered) * 100, 2)
    END AS calculated_fill_rate_pct,

    CASE
        WHEN o.expected_delivery_date IS NULL
          OR o.actual_delivery_date IS NULL
        THEN NULL
        WHEN o.actual_delivery_date <= o.expected_delivery_date THEN TRUE
        ELSE FALSE
    END AS calculated_on_time_delivery,

    -- Metadata
    o._source_file,
    o._source_platform,
    o._ingested_at,
    o._batch_id,
    o._processed_at

FROM source o

LEFT JOIN {{ ref('dim_dates') }} d
    ON o.order_date = d.date_day

LEFT JOIN {{ ref('dim_dates') }} dd_expected
    ON o.expected_delivery_date = dd_expected.date_day

LEFT JOIN {{ ref('dim_dates') }} dd_actual
    ON o.actual_delivery_date = dd_actual.date_day

LEFT JOIN {{ ref('dim_distributors') }} dis
    ON o.distributor_id = dis.distributor_id

LEFT JOIN {{ ref('dim_products') }} p
    ON o.product_id = p.product_id

LEFT JOIN {{ ref('dim_channels') }} ch
    ON COALESCE(o.channel, 'Unknown') = ch.channel

LEFT JOIN {{ ref('dim_geography') }} g
    ON COALESCE(o.region, 'Unknown') = g.region
   AND COALESCE(dis.province, 'Unknown') = g.province