DROP TABLE IF EXISTS dwh.fact_sales;

CREATE TABLE dwh.fact_sales AS
SELECT
    -- Degenerate dimension
    s.order_id,

    -- Foreign keys
    d.date_key AS order_date_key,
    c.customer_key,
    p.product_key,
    e.employee_key,

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
        WHEN s.quantity IS NULL OR p.cost_price IS NULL THEN NULL
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
        WHEN s.net_amount IS NULL OR s.net_amount = 0
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
    s._batch_id

FROM staging.stg_sales_transactions s

LEFT JOIN dwh.dim_date d
    ON s.order_date = d.date_day

LEFT JOIN dwh.dim_customers c
    ON s.customer_id = c.customer_id

LEFT JOIN dwh.dim_products p
    ON s.product_id = p.product_id

LEFT JOIN dwh.dim_employees e
    ON s.employee_id = e.employee_id
   AND s.order_date BETWEEN e.effective_from AND e.effective_to;