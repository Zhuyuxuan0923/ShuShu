SELECT
    id::INTEGER                     AS product_id,
    title::VARCHAR                  AS product_title,
    description::TEXT               AS product_description,
    price::DOUBLE PRECISION         AS price,
    discount_percentage::DOUBLE PRECISION AS discount_pct,
    rating::DOUBLE PRECISION        AS rating,
    stock::INTEGER                  AS stock,
    brand::VARCHAR                  AS brand,
    category::VARCHAR               AS category,
    thumbnail::VARCHAR              AS thumbnail_url,
    source_system::VARCHAR          AS source_system,
    _ingested_at::TIMESTAMPTZ       AS _ingested_at
FROM {{ source('external_apis', 'ecommerce_products') }}
WHERE id IS NOT NULL
