{{ config(
    materialized='incremental',
    unique_key='order_date_key',
    on_schema_change='append_new_columns'
) }}

SELECT
    order_date_key,
    order_status,
    COUNT(DISTINCT order_id)                AS order_count,
    COUNT(DISTINCT customer_id)             AS unique_customers,
    ROUND(SUM(total_amount)::NUMERIC, 2)::DOUBLE PRECISION AS total_revenue,
    ROUND(AVG(total_amount)::NUMERIC, 2)::DOUBLE PRECISION AS avg_order_value,
    COUNT(*) FILTER (WHERE payment_channel = 'card')         AS card_orders,
    COUNT(*) FILTER (WHERE payment_channel = 'e_wallet')     AS ewallet_orders,
    COUNT(*) FILTER (WHERE payment_channel = 'bank_transfer') AS bank_transfer_orders,
    CURRENT_TIMESTAMP                       AS _dws_processed_at
FROM {{ ref('dwd_business_orders') }}
{% if is_incremental() %}
WHERE order_date_key >= (SELECT COALESCE(MAX(order_date_key), '1970-01-01'::DATE) FROM {{ this }})
{% endif %}
GROUP BY 1, 2
