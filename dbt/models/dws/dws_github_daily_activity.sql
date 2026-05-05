{{ config(
    materialized='incremental',
    unique_key=['event_date', 'event_type', 'category'],
    on_schema_change='append_new_columns'
) }}

SELECT
    e.event_date,
    COALESCE(c.event_type, UPPER(TRIM(e.event_type))) AS event_type,
    COALESCE(c.category, 'uncategorized')             AS category,
    COUNT(DISTINCT e.event_id)                        AS event_count,
    COUNT(DISTINCT e.actor_id)                        AS unique_actors,
    COUNT(DISTINCT e.repo_id)                         AS unique_repos,
    COUNT(*) FILTER (WHERE e.is_public)               AS public_events,
    COUNT(*) FILTER (WHERE NOT e.is_public)           AS private_events,
    CURRENT_TIMESTAMP                                 AS _dws_processed_at
FROM {{ ref('dwd_github_events') }} e
LEFT JOIN {{ ref('event_type_categories') }} c
    ON UPPER(TRIM(e.event_type)) = c.event_type
{% if is_incremental() %}
WHERE e.event_date >= (SELECT COALESCE(MAX(event_date), '1970-01-01'::DATE) FROM {{ this }})
{% endif %}
GROUP BY 1, 2, 3
