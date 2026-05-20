DROP TABLE IF EXISTS dwh.fact_returns;

CREATE TABLE dwh.fact_returns AS
SELECT
    r.return_id,
    r.original_order_id,

    d.date_key AS return_date_key,
    c.customer_key,
    p.product_key,
    e.employee_key,

    r.return_date,
    r.return_month,
    r.customer_id,
    r.employee_id,
    r.product_id,
    r.region,
    r.province,
    r.return_reason,
    r.status,

    r.return_quantity,
    r.unit_price,
    r.return_amount,

    CASE
        WHEN r.return_quantity IS NULL OR p.cost_price IS NULL THEN NULL
        ELSE r.return_quantity * p.cost_price
    END AS return_cost_amount,

    CASE
        WHEN r.return_amount IS NULL
          OR r.return_quantity IS NULL
          OR p.cost_price IS NULL
        THEN NULL
        ELSE r.return_amount - (r.return_quantity * p.cost_price)
    END AS return_margin_impact,

    r._source_file,
    r._source_platform,
    r._ingested_at,
    r._batch_id

FROM staging.stg_return_transactions r

LEFT JOIN dwh.dim_date d
    ON r.return_date = d.date_day

LEFT JOIN dwh.dim_customers c
    ON r.customer_id = c.customer_id

LEFT JOIN dwh.dim_products p
    ON r.product_id = p.product_id

LEFT JOIN dwh.dim_employees e
    ON r.employee_id = e.employee_id
   AND r.return_date BETWEEN e.effective_from AND e.effective_to;