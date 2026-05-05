{{ config(materialized='table') }}

WITH customer_ranking AS (
    SELECT *
    FROM {{ ref('dws_customer_order_summary') }}
),
daily_revenue AS (
    SELECT
        order_date_key,
        SUM(total_revenue)                      AS daily_revenue,
        SUM(order_count)                        AS daily_orders,
        ROUND(AVG(avg_order_value)::NUMERIC, 2)::DOUBLE PRECISION AS daily_avg_order_value
    FROM {{ ref('dws_order_daily_summary') }}
    GROUP BY 1
),
ranked_customers AS (
    SELECT
        customer_id,
        customer_name,
        city,
        customer_type,
        total_orders,
        total_revenue,
        avg_order_value,
        last_order_date,
        customer_lifespan_days,
        payment_channels_used,
        customer_tier,
        RANK() OVER (ORDER BY total_revenue DESC)      AS revenue_rank,
        RANK() OVER (ORDER BY total_orders DESC)       AS loyalty_rank,
        RANK() OVER (ORDER BY avg_order_value DESC)    AS avg_value_rank
    FROM customer_ranking
),
daily_trend AS (
    SELECT
        order_date_key,
        daily_revenue,
        daily_orders,
        daily_avg_order_value,
        LAG(daily_revenue, 1) OVER (ORDER BY order_date_key) AS prev_day_revenue,
        CASE
            WHEN LAG(daily_revenue, 1) OVER (ORDER BY order_date_key) > 0
            THEN ROUND(
                (daily_revenue - LAG(daily_revenue, 1) OVER (ORDER BY order_date_key))
                / LAG(daily_revenue, 1) OVER (ORDER BY order_date_key) * 100, 2
            )::DOUBLE PRECISION
            ELSE NULL
        END                                             AS revenue_dod_pct
    FROM daily_revenue
),
payment_summary AS (
    SELECT
        SUM(card_orders)            AS total_card_orders,
        SUM(ewallet_orders)         AS total_ewallet_orders,
        SUM(bank_transfer_orders)   AS total_bank_transfer_orders
    FROM {{ ref('dws_order_daily_summary') }}
)
SELECT
    rc.customer_id,
    rc.customer_name,
    rc.city,
    rc.customer_type,
    rc.total_orders,
    rc.total_revenue,
    rc.avg_order_value,
    rc.last_order_date,
    rc.customer_lifespan_days,
    rc.payment_channels_used,
    rc.customer_tier,
    rc.revenue_rank,
    rc.loyalty_rank,
    rc.avg_value_rank,
    dt.order_date_key                                   AS latest_trade_date,
    dt.daily_revenue                                    AS latest_daily_revenue,
    dt.revenue_dod_pct,
    ROUND(ps.total_card_orders::NUMERIC
        / NULLIF(ps.total_card_orders + ps.total_ewallet_orders + ps.total_bank_transfer_orders, 0) * 100, 1
    )::DOUBLE PRECISION                                 AS card_payment_pct,
    ROUND(ps.total_ewallet_orders::NUMERIC
        / NULLIF(ps.total_card_orders + ps.total_ewallet_orders + ps.total_bank_transfer_orders, 0) * 100, 1
    )::DOUBLE PRECISION                                 AS ewallet_payment_pct,
    CURRENT_TIMESTAMP                                   AS _ads_generated_at
FROM ranked_customers rc
CROSS JOIN payment_summary ps
LEFT JOIN daily_trend dt ON dt.order_date_key = (
    SELECT MAX(order_date_key) FROM daily_trend
)
WHERE rc.revenue_rank <= 10
ORDER BY rc.revenue_rank
