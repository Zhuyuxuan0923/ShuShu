{{ config(
    materialized='incremental',
    unique_key='item_id',
    on_schema_change='sync_all_columns'
) }}

WITH source AS (
    SELECT * FROM {{ ref('ods_business_order_items') }}
    {% if is_incremental() %}
    WHERE _ingested_at > (SELECT COALESCE(MAX(_ingested_at), '1970-01-01'::TIMESTAMPTZ) FROM {{ this }})
    {% endif %}
),
cleaned AS (
    SELECT
        item_id,
        order_id,
        TRIM(product_name)                          AS product_name,
        quantity,
        ROUND(unit_price::NUMERIC, 2)::DOUBLE PRECISION AS unit_price,
        COALESCE(discount_pct, 0)                   AS discount_pct,
        ROUND((quantity * unit_price * (1 - COALESCE(discount_pct, 0) / 100.0))::NUMERIC, 2)::DOUBLE PRECISION
                                                    AS line_total,
        source_system,
        _ingested_at
    FROM source
    WHERE item_id IS NOT NULL
      AND order_id IS NOT NULL
      AND product_name IS NOT NULL
      AND quantity > 0
      AND unit_price >= 0
)
SELECT
    *,
    CURRENT_TIMESTAMP AS _dwd_processed_at
FROM cleaned
{{ deduplicate('item_id') }}
