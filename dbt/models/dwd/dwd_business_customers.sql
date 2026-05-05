{{ config(
    materialized='incremental',
    unique_key='customer_id',
    on_schema_change='sync_all_columns'
) }}

WITH source AS (
    SELECT * FROM {{ ref('ods_business_customers') }}
    {% if is_incremental() %}
    WHERE _ingested_at > (SELECT COALESCE(MAX(_ingested_at), '1970-01-01'::TIMESTAMPTZ) FROM {{ this }})
    {% endif %}
),
cleaned AS (
    SELECT
        customer_id,
        TRIM(customer_name)                         AS customer_name,
        LOWER(TRIM(email))                          AS email,
        REGEXP_REPLACE(COALESCE(phone, ''), '\s', '') AS phone,
        TRIM(city)                                  AS city,
        register_date,
        LOWER(TRIM(customer_type))                  AS customer_type,
        source_system,
        _ingested_at
    FROM source
    WHERE customer_id IS NOT NULL
      AND customer_name IS NOT NULL
      AND customer_name != ''
)
SELECT
    *,
    CURRENT_TIMESTAMP AS _dwd_processed_at
FROM cleaned
{{ deduplicate('customer_id') }}
