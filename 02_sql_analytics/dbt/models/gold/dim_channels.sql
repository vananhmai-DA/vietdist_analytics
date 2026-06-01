{{ config(materialized='table') }}

WITH channels AS (
    SELECT DISTINCT
        COALESCE(channel, 'Unknown') AS channel
    FROM {{ ref('stg_sales_transactions') }}

    UNION

    SELECT DISTINCT
        COALESCE(channel, 'Unknown') AS channel
    FROM {{ ref('stg_customers') }}

    UNION

    SELECT DISTINCT
        COALESCE(channel, 'Unknown') AS channel
    FROM {{ ref('stg_distributors') }}

    UNION

    SELECT DISTINCT
        COALESCE(channel, 'Unknown') AS channel
    FROM {{ ref('stg_distributor_orders') }}
)

SELECT
    ROW_NUMBER() OVER (ORDER BY channel) AS channel_key,
    channel
FROM channels