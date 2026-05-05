SELECT
    time::TIMESTAMPTZ               AS forecast_time,
    temperature_2m::DOUBLE PRECISION AS temperature_2m,
    humidity::INTEGER               AS humidity,
    precipitation::DOUBLE PRECISION AS precipitation,
    weather_code::INTEGER           AS weather_code,
    source_system::VARCHAR          AS source_system,
    _ingested_at::TIMESTAMPTZ       AS _ingested_at
FROM {{ source('external_apis', 'weather_forecast') }}
WHERE time IS NOT NULL
