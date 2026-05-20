DROP TABLE IF EXISTS dwh.mart_distributor_performance;

CREATE TABLE dwh.mart_distributor_performance AS
WITH distributor_monthly AS (
    SELECT
        f.distributor_id,
        dis.distributor_name,
        dis.tier,
        dis.channel AS distributor_channel,
        dis.province,
        dis.region AS distributor_region,

        DATE_TRUNC('month', f.order_date)::DATE AS month_date,
        EXTRACT(YEAR FROM f.order_date)::INTEGER AS year,
        EXTRACT(MONTH FROM f.order_date)::INTEGER AS month,

        f.region AS order_region,
        f.channel AS order_channel,

        COUNT(DISTINCT f.order_id) AS total_orders,
        COUNT(DISTINCT f.product_id) AS products_ordered,

        SUM(f.qty_ordered) AS total_qty_ordered,
        SUM(f.qty_delivered) AS total_qty_delivered,

        SUM(f.gross_amount) AS total_gross_amount,
        SUM(f.delivered_amount) AS total_delivered_amount,

        COUNT(*) FILTER (
            WHERE f.calculated_on_time_delivery = TRUE
        ) AS on_time_delivery_count,

        COUNT(*) FILTER (
            WHERE f.calculated_on_time_delivery = FALSE
        ) AS late_delivery_count,

        COUNT(*) FILTER (
            WHERE f.delivery_status IS NOT NULL
        ) AS delivery_record_count

    FROM dwh.fact_distributor_orders f

    LEFT JOIN dwh.dim_distributors dis
        ON f.distributor_id = dis.distributor_id

    GROUP BY
        f.distributor_id,
        dis.distributor_name,
        dis.tier,
        dis.channel,
        dis.province,
        dis.region,
        DATE_TRUNC('month', f.order_date)::DATE,
        EXTRACT(YEAR FROM f.order_date)::INTEGER,
        EXTRACT(MONTH FROM f.order_date)::INTEGER,
        f.region,
        f.channel
)

SELECT
    distributor_id,
    distributor_name,
    tier,
    distributor_channel,
    province,
    distributor_region,

    month_date,
    year,
    month,

    order_region,
    order_channel,

    total_orders,
    products_ordered,

    total_qty_ordered,
    total_qty_delivered,

    CASE
        WHEN total_qty_ordered IS NULL OR total_qty_ordered = 0 THEN NULL
        ELSE ROUND((total_qty_delivered / total_qty_ordered) * 100, 2)
    END AS fill_rate_pct,

    total_gross_amount,
    total_delivered_amount,

    CASE
        WHEN total_gross_amount IS NULL OR total_gross_amount = 0 THEN NULL
        ELSE ROUND((total_delivered_amount / total_gross_amount) * 100, 2)
    END AS delivered_amount_rate_pct,

    on_time_delivery_count,
    late_delivery_count,
    delivery_record_count,

    CASE
        WHEN delivery_record_count IS NULL OR delivery_record_count = 0 THEN NULL
        ELSE ROUND((on_time_delivery_count::NUMERIC / delivery_record_count) * 100, 2)
    END AS on_time_delivery_rate_pct

FROM distributor_monthly;