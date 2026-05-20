DROP TABLE IF EXISTS dwh.dim_date;

CREATE TABLE dwh.dim_date AS
WITH date_spine AS (
    SELECT generate_series(
        DATE '2022-01-01',
        DATE '2026-12-31',
        INTERVAL '1 day'
    )::DATE AS date_day
),

date_parts AS (
    SELECT
        date_day,
        EXTRACT(YEAR FROM date_day)::INTEGER AS calendar_year,
        EXTRACT(QUARTER FROM date_day)::INTEGER AS calendar_quarter,
        EXTRACT(MONTH FROM date_day)::INTEGER AS month_number,
        TO_CHAR(date_day, 'Month') AS month_name,
        EXTRACT(DAY FROM date_day)::INTEGER AS day_of_month,
        EXTRACT(ISODOW FROM date_day)::INTEGER AS day_of_week,
        TO_CHAR(date_day, 'Day') AS day_name,
        EXTRACT(WEEK FROM date_day)::INTEGER AS week_of_year,

        CASE
            WHEN EXTRACT(MONTH FROM date_day)::INTEGER >= 9
            THEN EXTRACT(YEAR FROM date_day)::INTEGER
            ELSE EXTRACT(YEAR FROM date_day)::INTEGER - 1
        END AS fiscal_year,

        CASE
            WHEN EXTRACT(MONTH FROM date_day)::INTEGER IN (9, 10, 11) THEN 1
            WHEN EXTRACT(MONTH FROM date_day)::INTEGER IN (12, 1, 2) THEN 2
            WHEN EXTRACT(MONTH FROM date_day)::INTEGER IN (3, 4, 5) THEN 3
            WHEN EXTRACT(MONTH FROM date_day)::INTEGER IN (6, 7, 8) THEN 4
        END AS fiscal_quarter
    FROM date_spine
)

SELECT
    TO_CHAR(date_day, 'YYYYMMDD')::INTEGER AS date_key,
    date_day,
    calendar_year,
    calendar_quarter,
    month_number,
    TRIM(month_name) AS month_name,
    day_of_month,
    day_of_week,
    TRIM(day_name) AS day_name,
    week_of_year,
    fiscal_year,
    fiscal_quarter,
    CASE WHEN day_of_week IN (6, 7) THEN TRUE ELSE FALSE END AS is_weekend
FROM date_parts;