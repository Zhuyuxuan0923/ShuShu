{{ config(
    materialized='incremental',
    unique_key='customer_id',
    on_schema_change='append_new_columns'
) }}

WITH order_totals AS (
    SELECT
        o.customer_id,
        c.customer_name,
        c.city,
        c.customer_type,
        COUNT(DISTINCT o.order_id)                          AS total_orders,
        ROUND(SUM(o.total_amount)::NUMERIC, 2)::DOUBLE PRECISION  AS total_revenue,
        ROUND(AVG(o.total_amount)::NUMERIC, 2)::DOUBLE PRECISION  AS avg_order_value,
        MAX(o.order_date)                                   AS last_order_date,
        MIN(o.order_date)                                   AS first_order_date,
        COUNT(DISTINCT o.order_date_key)                    AS active_days,
        COUNT(DISTINCT o.payment_channel)                   AS payment_channels_used
    FROM {{ ref('dwd_business_orders') }} o
    JOIN {{ ref('dwd_business_customers') }} c ON o.customer_id = c.customer_id
    GROUP BY 1, 2, 3, 4
)
SELECT
    *,
    EXTRACT(DAY FROM (last_order_date - first_order_date)) AS customer_lifespan_days,
    CASE
        WHEN total_revenue >= 50000 THEN 'vip'
        WHEN total_revenue >= 10000 THEN 'premium'
        WHEN total_revenue >= 5000  THEN 'standard'
        ELSE 'basic'
    END                                                     AS customer_tier,
    CURRENT_TIMESTAMP                                       AS _dws_processed_at
FROM order_totals
