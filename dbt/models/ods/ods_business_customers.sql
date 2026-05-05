SELECT
    customer_id::INTEGER            AS customer_id,
    customer_name::VARCHAR          AS customer_name,
    email::VARCHAR                  AS email,
    phone::VARCHAR                  AS phone,
    city::VARCHAR                   AS city,
    register_date::DATE             AS register_date,
    customer_type::VARCHAR          AS customer_type,
    source_system::VARCHAR          AS source_system,
    _ingested_at::TIMESTAMPTZ       AS _ingested_at
FROM {{ source('external_apis', 'business_customers') }}
WHERE customer_id IS NOT NULL
