{{ config(
    materialized='incremental',
    unique_key='order_id',
    on_schema_change='sync_all_columns'
) }}

WITH source AS (
    SELECT * FROM {{ ref('ods_business_orders') }}
    {% if is_incremental() %}
    WHERE _ingested_at > (SELECT COALESCE(MAX(_ingested_at), '1970-01-01'::TIMESTAMPTZ) FROM {{ this }})
    {% endif %}
),
cleaned AS (
    SELECT
        order_id,
        customer_id,
        order_date,
        DATE_TRUNC('day', order_date)               AS order_date_key,
        LOWER(TRIM(order_status))                   AS order_status,
        CASE
            WHEN LOWER(TRIM(COALESCE(payment_method, ''))) IN ('credit_card', 'debit_card')
                THEN 'card'
            WHEN LOWER(TRIM(COALESCE(payment_method, ''))) IN ('alipay', 'wechat_pay')
                THEN 'e_wallet'
            WHEN LOWER(TRIM(COALESCE(payment_method, ''))) = 'bank_transfer'
                THEN 'bank_transfer'
            ELSE 'other'
        END                                         AS payment_channel,
        LOWER(TRIM(COALESCE(payment_method, 'unknown'))) AS payment_method,
        ROUND(total_amount::NUMERIC, 2)::DOUBLE PRECISION AS total_amount,
        UPPER(TRIM(COALESCE(currency, 'CNY')))      AS currency,
        source_system,
        _ingested_at
    FROM source
    WHERE order_id IS NOT NULL
      AND customer_id IS NOT NULL
      AND order_date IS NOT NULL
      AND total_amount >= 0
)
SELECT DISTINCT ON (order_id)
    *,
    CURRENT_TIMESTAMP AS _dwd_processed_at
FROM cleaned
ORDER BY order_id, _ingested_at DESC
