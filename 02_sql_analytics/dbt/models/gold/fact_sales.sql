{{ 
    config(
        materialized='incremental',
        unique_key='sales_line_key',
        incremental_strategy='delete+insert'
    ) 
}}

WITH source AS (
    SELECT
        *
    FROM {{ ref('stg_sales_transactions') }}

    {% if is_incremental() %}
      WHERE _processed_at > (
          SELECT COALESCE(MAX(_processed_at), TIMESTAMP '1900-01-01')
          FROM {{ this }}
      )
    {% endif %}
)

SELECT
    -- Fact grain key: one row per order_id + product_id
    s.order_id || '_' || s.product_id AS sales_line_key,

    -- Degenerate dimension
    s.order_id,

    -- Foreign keys
    d.date_key AS order_date_key,
    c.customer_key,
    p.product_key,
    e.employee_key,
    ch.channel_key,
    g.geography_key,

    -- Natural keys kept for traceability
    s.order_date,
    s.customer_id,
    s.employee_id,
    s.product_id,

    -- Descriptive transaction attributes
    s.order_month,
    s.order_quarter,
    s.order_year,
    s.region,
    s.province,
    s.channel,
    s.product_category,
    s.delivery_status,
    s.payment_method,
    s.payment_status,

    -- Measures
    s.quantity,
    s.unit_price,
    s.discount_pct,
    s.discount_amount,
    s.gross_amount,
    s.net_amount,

    CASE
        WHEN s.quantity IS NULL
          OR p.cost_price IS NULL
        THEN NULL
        ELSE s.quantity * p.cost_price
    END AS total_cost,

    CASE
        WHEN s.net_amount IS NULL
          OR s.quantity IS NULL
          OR p.cost_price IS NULL
        THEN NULL
        ELSE s.net_amount - (s.quantity * p.cost_price)
    END AS gross_profit,

    CASE
        WHEN s.net_amount IS NULL
          OR s.net_amount = 0
          OR s.quantity IS NULL
          OR p.cost_price IS NULL
        THEN NULL
        ELSE ROUND(
            ((s.net_amount - (s.quantity * p.cost_price)) / s.net_amount) * 100,
            2
        )
    END AS gross_profit_margin_pct,

    -- Metadata
    s._source_file,
    s._source_platform,
    s._ingested_at,
    s._batch_id,
    s._processed_at

FROM source s

LEFT JOIN {{ ref('dim_dates') }} d
    ON s.order_date = d.date_day

LEFT JOIN {{ ref('dim_customers') }} c
    ON s.customer_id = c.customer_id

LEFT JOIN {{ ref('dim_products') }} p
    ON s.product_id = p.product_id

LEFT JOIN {{ ref('dim_employees') }} e
    ON s.employee_id = e.employee_id
   AND s.order_date BETWEEN e.effective_from AND e.effective_to

LEFT JOIN {{ ref('dim_channels') }} ch
    ON COALESCE(s.channel, 'Unknown') = ch.channel

LEFT JOIN {{ ref('dim_geography') }} g
    ON COALESCE(s.region, 'Unknown') = g.region
   AND COALESCE(s.province, 'Unknown') = g.province