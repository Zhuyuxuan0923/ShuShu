{{ config(
    materialized='incremental',
    unique_key='forecast_date',
    on_schema_change='append_new_columns'
) }}

SELECT
    forecast_date,
    MIN(temperature_2m)                     AS min_temperature,
    MAX(temperature_2m)                     AS max_temperature,
    ROUND(AVG(temperature_2m)::NUMERIC, 2)::DOUBLE PRECISION AS avg_temperature,
    ROUND(AVG(humidity)::NUMERIC, 1)::DOUBLE PRECISION       AS avg_humidity,
    ROUND(SUM(precipitation)::NUMERIC, 2)::DOUBLE PRECISION  AS total_precipitation,
    COUNT(*)                                AS record_count,
    STRING_AGG(DISTINCT weather_category, ',' ORDER BY weather_category) AS weather_categories,
    CURRENT_TIMESTAMP                       AS _dws_processed_at
FROM {{ ref('dwd_weather_forecast') }}
{% if is_incremental() %}
WHERE forecast_date >= (SELECT COALESCE(MAX(forecast_date), '1970-01-01'::DATE) FROM {{ this }})
{% endif %}
GROUP BY 1
