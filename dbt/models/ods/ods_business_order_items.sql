SELECT
    item_id::INTEGER                AS item_id,
    order_id::INTEGER               AS order_id,
    product_name::VARCHAR           AS product_name,
    quantity::INTEGER               AS quantity,
    unit_price::DOUBLE PRECISION    AS unit_price,
    discount_pct::DOUBLE PRECISION  AS discount_pct,
    source_system::VARCHAR          AS source_system,
    _ingested_at::TIMESTAMPTZ       AS _ingested_at
FROM {{ source('external_apis', 'business_order_items') }}
WHERE item_id IS NOT NULL
