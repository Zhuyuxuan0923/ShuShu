SELECT
    order_id::INTEGER               AS order_id,
    customer_id::INTEGER            AS customer_id,
    order_date::TIMESTAMPTZ         AS order_date,
    order_status::VARCHAR           AS order_status,
    payment_method::VARCHAR         AS payment_method,
    total_amount::DOUBLE PRECISION  AS total_amount,
    currency::VARCHAR               AS currency,
    source_system::VARCHAR          AS source_system,
    _ingested_at::TIMESTAMPTZ       AS _ingested_at
FROM {{ source('external_apis', 'business_orders') }}
WHERE order_id IS NOT NULL
