{{ config(materialized='table') }}

SELECT
    customer_id AS customer_key,
    customer_id,
    customer_name,
    customer_type,
    channel,
    province,
    region,
    address,
    phone,
    tax_code,
    join_date,
    credit_limit,
    status,

    CASE
        WHEN credit_limit >= 200000000 THEN 'High Credit'
        WHEN credit_limit >= 100000000 THEN 'Medium Credit'
        WHEN credit_limit IS NOT NULL THEN 'Low Credit'
        ELSE 'Unknown'
    END AS credit_limit_tier,

    _source_file,
    _source_platform,
    _ingested_at,
    _batch_id,
    _processed_at

FROM {{ ref('stg_customers') }}