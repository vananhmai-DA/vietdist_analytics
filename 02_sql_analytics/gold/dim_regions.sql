DROP TABLE IF EXISTS dwh.dim_regions;

CREATE TABLE dwh.dim_regions AS
SELECT
    ROW_NUMBER() OVER (ORDER BY region) AS region_key,
    region
FROM (
    SELECT DISTINCT
        COALESCE(region, 'Unknown') AS region
    FROM dwh.dim_customers
) r;

ALTER TABLE dwh.dim_regions
ADD CONSTRAINT pk_dim_regions PRIMARY KEY (region_key);