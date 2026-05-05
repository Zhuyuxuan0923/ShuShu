{{ config(
    materialized='incremental',
    unique_key='category',
    on_schema_change='append_new_columns'
) }}

SELECT
    category,
    COUNT(DISTINCT product_id)              AS product_count,
    COUNT(DISTINCT brand)                   AS brand_count,
    ROUND(AVG(price)::NUMERIC, 2)::DOUBLE PRECISION       AS avg_price,
    ROUND(MIN(price)::NUMERIC, 2)::DOUBLE PRECISION       AS min_price,
    ROUND(MAX(price)::NUMERIC, 2)::DOUBLE PRECISION       AS max_price,
    ROUND(AVG(rating)::NUMERIC, 2)::DOUBLE PRECISION      AS avg_rating,
    SUM(stock)                              AS total_stock,
    ROUND(SUM(price * stock)::NUMERIC, 2)::DOUBLE PRECISION AS total_inventory_value,
    COUNT(*) FILTER (WHERE rating_tier = 'platinum') AS platinum_products,
    COUNT(*) FILTER (WHERE rating_tier = 'gold')     AS gold_products,
    COUNT(*) FILTER (WHERE discount_pct > 0)         AS discounted_products,
    CURRENT_TIMESTAMP                        AS _dws_processed_at
FROM {{ ref('dwd_ecommerce_products') }}
{% if is_incremental() %}
WHERE _dwd_processed_at > (SELECT COALESCE(MAX(_dws_processed_at), '1970-01-01'::TIMESTAMPTZ) FROM {{ this }})
{% endif %}
GROUP BY 1
