{{ config(materialized='table') }}

WITH category_metrics AS (
    SELECT *
    FROM {{ ref('dws_ecommerce_category_daily') }}
),
ranked AS (
    SELECT
        category,
        product_count,
        brand_count,
        avg_price,
        min_price,
        max_price,
        avg_rating,
        total_stock,
        total_inventory_value,
        platinum_products,
        gold_products,
        discounted_products,
        RANK() OVER (ORDER BY total_inventory_value DESC) AS revenue_rank,
        RANK() OVER (ORDER BY avg_rating DESC)           AS rating_rank
    FROM category_metrics
)
SELECT
    category,
    product_count,
    brand_count,
    avg_price,
    min_price,
    max_price,
    avg_rating,
    total_stock,
    total_inventory_value,
    platinum_products,
    gold_products,
    discounted_products,
    revenue_rank,
    rating_rank,
    CASE
        WHEN revenue_rank <= 5 AND avg_rating >= 4.0 THEN 'star'
        WHEN revenue_rank <= 10 THEN 'core'
        ELSE 'niche'
    END                                         AS category_tier,
    CURRENT_TIMESTAMP                           AS _ads_generated_at
FROM ranked
ORDER BY revenue_rank
