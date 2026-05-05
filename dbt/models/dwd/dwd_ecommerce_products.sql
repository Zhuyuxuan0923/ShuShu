{{ config(
    materialized='incremental',
    unique_key='product_id',
    on_schema_change='sync_all_columns'
) }}

WITH source AS (
    SELECT * FROM {{ ref('ods_ecommerce_products') }}
    {% if is_incremental() %}
    WHERE _ingested_at > (SELECT COALESCE(MAX(_ingested_at), '1970-01-01'::TIMESTAMPTZ) FROM {{ this }})
    {% endif %}
),
cleaned AS (
    SELECT
        product_id,
        TRIM(product_title)                         AS product_title,
        product_description,
        ROUND(price::NUMERIC, 2)::DOUBLE PRECISION  AS price,
        COALESCE(discount_pct, 0)                   AS discount_pct,
        ROUND(rating::NUMERIC, 2)::DOUBLE PRECISION AS rating,
        CASE
            WHEN rating >= 4.5 THEN 'platinum'
            WHEN rating >= 4.0 THEN 'gold'
            WHEN rating >= 3.0 THEN 'silver'
            ELSE 'bronze'
        END                                         AS rating_tier,
        stock,
        TRIM(COALESCE(brand, 'Unknown'))            AS brand,
        TRIM(category)                              AS category,
        thumbnail_url,
        source_system,
        _ingested_at
    FROM source
    WHERE product_id IS NOT NULL
      AND product_title IS NOT NULL
      AND price IS NOT NULL
)
SELECT
    *,
    CURRENT_TIMESTAMP AS _dwd_processed_at
FROM cleaned
{{ deduplicate('product_id') }}
