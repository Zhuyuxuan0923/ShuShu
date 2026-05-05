{{ config(
    materialized='incremental',
    unique_key='forecast_time',
    on_schema_change='sync_all_columns'
) }}

WITH source AS (
    SELECT * FROM {{ ref('ods_weather_forecast') }}
    {% if is_incremental() %}
    WHERE _ingested_at > (SELECT COALESCE(MAX(_ingested_at), '1970-01-01'::TIMESTAMPTZ) FROM {{ this }})
    {% endif %}
),
cleaned AS (
    SELECT
        forecast_time,
        temperature_2m,
        humidity,
        precipitation,
        weather_code,
        DATE_TRUNC('day', forecast_time)           AS forecast_date,
        CASE
            WHEN weather_code = 0 THEN 'clear'
            WHEN weather_code BETWEEN 1 AND 3 THEN 'partly_cloudy'
            WHEN weather_code BETWEEN 4 AND 9 THEN 'cloudy'
            WHEN weather_code BETWEEN 10 AND 19 THEN 'fog'
            WHEN weather_code BETWEEN 20 AND 29 THEN 'drizzle'
            WHEN weather_code BETWEEN 30 AND 39 THEN 'rain'
            WHEN weather_code BETWEEN 40 AND 49 THEN 'snow'
            WHEN weather_code BETWEEN 50 AND 59 THEN 'heavy_rain'
            WHEN weather_code BETWEEN 60 AND 69 THEN 'heavy_snow'
            WHEN weather_code BETWEEN 70 AND 79 THEN 'snow_grains'
            WHEN weather_code BETWEEN 80 AND 89 THEN 'thunderstorm'
            WHEN weather_code BETWEEN 90 AND 99 THEN 'severe_thunderstorm'
            ELSE 'unknown'
        END                                         AS weather_category,
        source_system,
        _ingested_at
    FROM source
    WHERE forecast_time IS NOT NULL
)
SELECT DISTINCT ON (forecast_time)
    *,
    CURRENT_TIMESTAMP AS _dwd_processed_at
FROM cleaned
ORDER BY forecast_time, _ingested_at DESC
