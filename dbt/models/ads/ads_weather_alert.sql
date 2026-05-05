{{ config(materialized='table') }}

WITH hourly AS (
    SELECT *
    FROM {{ ref('dwd_weather_forecast') }}
    WHERE forecast_time >= CURRENT_TIMESTAMP
      AND forecast_time < CURRENT_TIMESTAMP + INTERVAL '24 hours'
),
alerts AS (
    SELECT
        forecast_time,
        temperature_2m,
        weather_code,
        weather_category,
        CASE
            WHEN temperature_2m >= 40.0 THEN 'critical'
            WHEN temperature_2m >= 38.0 THEN 'warning'
            ELSE NULL
        END                                     AS heat_alert,
        CASE
            WHEN weather_code BETWEEN 90 AND 99 THEN 'critical'
            WHEN weather_code BETWEEN 80 AND 89 THEN 'warning'
            ELSE NULL
        END                                     AS storm_alert
    FROM hourly
)
SELECT
    forecast_time,
    temperature_2m,
    weather_category,
    COALESCE(heat_alert, storm_alert)           AS alert_type,
    CASE
        WHEN heat_alert = 'critical' OR storm_alert = 'critical' THEN 'critical'
        ELSE 'warning'
    END                                         AS severity,
    CASE
        WHEN heat_alert IS NOT NULL
            THEN 'Temperature ' || temperature_2m::VARCHAR || 'C - Extreme heat'
        WHEN storm_alert IS NOT NULL
            THEN 'Weather code ' || weather_code::VARCHAR || ' - Thunderstorm'
    END                                         AS alert_message,
    CURRENT_TIMESTAMP                           AS _ads_generated_at
FROM alerts
WHERE heat_alert IS NOT NULL OR storm_alert IS NOT NULL
ORDER BY forecast_time
