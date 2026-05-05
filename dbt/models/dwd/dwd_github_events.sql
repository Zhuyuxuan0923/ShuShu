{{ config(
    materialized='incremental',
    unique_key='event_id',
    on_schema_change='sync_all_columns'
) }}

WITH source AS (
    SELECT * FROM {{ ref('ods_github_events') }}
    {% if is_incremental() %}
    WHERE _ingested_at > (SELECT COALESCE(MAX(_ingested_at), '1970-01-01'::TIMESTAMPTZ) FROM {{ this }})
    {% endif %}
),
cleaned AS (
    SELECT
        event_id,
        UPPER(TRIM(event_type))                    AS event_type,
        TRIM(actor_login)                          AS actor_login,
        actor_id,
        SPLIT_PART(repo_name, '/', 1)              AS repo_owner,
        SPLIT_PART(repo_name, '/', 2)              AS repo_name_short,
        repo_id,
        event_created_at,
        DATE_TRUNC('day', event_created_at)        AS event_date,
        DATE_TRUNC('hour', event_created_at)       AS event_hour,
        is_public,
        source_system,
        _ingested_at
    FROM source
    WHERE event_id IS NOT NULL
      AND event_type IS NOT NULL
      AND repo_name IS NOT NULL
      AND repo_name LIKE '%/%'
)
SELECT DISTINCT ON (event_id)
    *,
    CURRENT_TIMESTAMP AS _dwd_processed_at
FROM cleaned
ORDER BY event_id, _ingested_at DESC
