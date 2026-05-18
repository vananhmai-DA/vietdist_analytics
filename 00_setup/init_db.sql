-- Run this part while connected to the default postgres database
CREATE DATABASE vietdist_dw;

-- Then manually connect to vietdist_dw in DBeaver
-- and run the statements below

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS dwh;

SELECT schema_name
FROM information_schema.schemata
WHERE schema_name IN ('raw', 'staging', 'dwh');