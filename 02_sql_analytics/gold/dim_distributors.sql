DROP TABLE IF EXISTS dwh.dim_distributors;

CREATE TABLE dwh.dim_distributors AS
SELECT
    distributor_id AS distributor_key,
    distributor_id,
    distributor_name,
    tier,
    channel,
    province,
    region,
    contact_person,
    phone,
    email,
    tax_code,
    join_date,
    credit_limit,
    status,
    assigned_supervisor_id,

    CASE
        WHEN credit_limit >= 500000000 THEN 'High Credit'
        WHEN credit_limit >= 200000000 THEN 'Medium Credit'
        WHEN credit_limit IS NOT NULL THEN 'Low Credit'
        ELSE 'Unknown'
    END AS credit_limit_tier,

    _source_file,
    _source_platform,
    _ingested_at,
    _batch_id
FROM staging.stg_distributors;