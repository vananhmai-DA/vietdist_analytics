DROP TABLE IF EXISTS dwh.dim_channels;

CREATE TABLE dwh.dim_channels AS
SELECT
    ROW_NUMBER() OVER (ORDER BY channel) AS channel_key,
    channel
FROM (
    SELECT DISTINCT
        COALESCE(channel, 'Unknown') AS channel
    FROM dwh.fact_sales
) c;

ALTER TABLE dwh.dim_channels
ADD CONSTRAINT pk_dim_channels PRIMARY KEY (channel_key);