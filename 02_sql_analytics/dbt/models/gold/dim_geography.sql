{{ config(materialized='table') }}

WITH geography AS (
    SELECT DISTINCT
        COALESCE(region, 'Unknown') AS region,
        COALESCE(province, 'Unknown') AS province
    FROM {{ ref('stg_customers') }}

    UNION

    SELECT DISTINCT
        COALESCE(region, 'Unknown') AS region,
        COALESCE(province, 'Unknown') AS province
    FROM {{ ref('stg_distributors') }}

    UNION

    SELECT DISTINCT
        COALESCE(region, 'Unknown') AS region,
        COALESCE(province, 'Unknown') AS province
    FROM {{ ref('stg_sales_transactions') }}

    UNION

    SELECT DISTINCT
        COALESCE(region, 'Unknown') AS region,
        COALESCE(province, 'Unknown') AS province
    FROM {{ ref('stg_return_transactions') }}
)

SELECT
    ROW_NUMBER() OVER (
        ORDER BY region, province
    ) AS geography_key,

    DENSE_RANK() OVER (
        ORDER BY region
    ) AS region_key,

    region,
    province

FROM geography