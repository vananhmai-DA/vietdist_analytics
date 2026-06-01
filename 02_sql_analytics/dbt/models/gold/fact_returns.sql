{{ 
    config(
        materialized='incremental',
        unique_key='return_id',
        incremental_strategy='delete+insert'
    ) 
}}

WITH source AS (
    SELECT
        *
    FROM {{ ref('stg_return_transactions') }}

    {% if is_incremental() %}
      WHERE _processed_at > (
          SELECT COALESCE(MAX(_processed_at), TIMESTAMP '1900-01-01')
          FROM {{ this }}
      )
    {% endif %}
)

SELECT
    -- Fact key
    r.return_id,

    -- Degenerate / traceability key
    r.original_order_id,

    -- Foreign keys
    d.date_key AS return_date_key,
    c.customer_key,
    p.product_key,
    e.employee_key,
    g.geography_key,

    -- Natural keys kept for traceability
    r.return_date,
    r.return_month,
    r.customer_id,
    r.employee_id,
    r.product_id,

    -- Descriptive attributes
    r.region,
    r.province,
    r.return_reason,
    r.status,

    -- Measures
    r.return_quantity,
    r.unit_price,
    r.return_amount,

    CASE
        WHEN r.return_quantity IS NULL
          OR p.cost_price IS NULL
        THEN NULL
        ELSE r.return_quantity * p.cost_price
    END AS return_cost_amount,

    CASE
        WHEN r.return_amount IS NULL
          OR r.return_quantity IS NULL
          OR p.cost_price IS NULL
        THEN NULL
        ELSE r.return_amount - (r.return_quantity * p.cost_price)
    END AS return_margin_impact,

    -- Metadata
    r._source_file,
    r._source_platform,
    r._ingested_at,
    r._batch_id,
    r._processed_at

FROM source r

LEFT JOIN {{ ref('dim_dates') }} d
    ON r.return_date = d.date_day

LEFT JOIN {{ ref('dim_customers') }} c
    ON r.customer_id = c.customer_id

LEFT JOIN {{ ref('dim_products') }} p
    ON r.product_id = p.product_id

LEFT JOIN {{ ref('dim_employees') }} e
    ON r.employee_id = e.employee_id
   AND r.return_date BETWEEN e.effective_from AND e.effective_to

LEFT JOIN {{ ref('dim_geography') }} g
    ON COALESCE(r.region, 'Unknown') = g.region
   AND COALESCE(r.province, 'Unknown') = g.province