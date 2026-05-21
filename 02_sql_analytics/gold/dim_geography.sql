DROP TABLE IF EXISTS dwh.dim_geography;

CREATE TABLE dwh.dim_geography AS
SELECT
    ROW_NUMBER() OVER (ORDER BY region, province) AS geography_key,
    DENSE_RANK() OVER (ORDER BY region) AS region_key,
    region,
    province
FROM (
    SELECT DISTINCT
        COALESCE(region, 'Unknown') AS region,
        COALESCE(province, 'Unknown') AS province
    FROM dwh.dim_customers
) g;

ALTER TABLE dwh.dim_geography
ADD CONSTRAINT pk_dim_geography PRIMARY KEY (geography_key);