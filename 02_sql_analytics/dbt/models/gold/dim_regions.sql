{{ config(materialized='table') }}

WITH regions AS (
    SELECT DISTINCT
        COALESCE(region, 'Unknown') AS region
    FROM {{ ref('stg_customers') }}

    UNION

    SELECT DISTINCT
        COALESCE(region, 'Unknown') AS region
    FROM {{ ref('stg_distributors') }}

    UNION

    SELECT DISTINCT
        COALESCE(region, 'Unknown') AS region
    FROM {{ ref('stg_sales_transactions') }}

    UNION

    SELECT DISTINCT
        COALESCE(region, 'Unknown') AS region
    FROM {{ ref('stg_distributor_orders') }}

    UNION

    SELECT DISTINCT
        COALESCE(region, 'Unknown') AS region
    FROM {{ ref('stg_return_transactions') }}

    UNION

    SELECT DISTINCT
        COALESCE(region, 'Unknown') AS region
    FROM {{ ref('stg_territory_mapping') }}

    UNION

    SELECT DISTINCT
        COALESCE(region, 'Unknown') AS region
    FROM {{ ref('stg_employees') }}
)

SELECT
    ROW_NUMBER() OVER (ORDER BY region) AS region_key,
    region

FROM regions