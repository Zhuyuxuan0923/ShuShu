{{ config(
    materialized='incremental',
    unique_key='event_date',
    on_schema_change='append_new_columns'
) }}

SELECT
    event_date,
    event_type,
    category,
    COUNT(DISTINCT event_id)               AS event_count,
    COUNT(DISTINCT actor_id)               AS unique_actors,
    COUNT(DISTINCT repo_id)                AS unique_repos,
    COUNT(*) FILTER (WHERE is_public)      AS public_events,
    COUNT(*) FILTER (WHERE NOT is_public)  AS private_events,
    CURRENT_TIMESTAMP                      AS _dws_processed_at
FROM {{ ref('dwd_github_events') }}
LEFT JOIN {{ ref('event_type_categories') }}
    ON UPPER(TRIM({{ ref('dwd_github_events') }}.event_type)) = {{ ref('event_type_categories') }}.event_type
{% if is_incremental() %}
WHERE event_date >= (SELECT COALESCE(MAX(event_date), '1970-01-01'::DATE) FROM {{ this }})
{% endif %}
GROUP BY 1, 2, 3
