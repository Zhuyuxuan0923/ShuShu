SELECT
    id::VARCHAR                     AS event_id,
    type::VARCHAR                   AS event_type,
    actor_login::VARCHAR            AS actor_login,
    actor_id::BIGINT                AS actor_id,
    repo_name::VARCHAR              AS repo_name,
    repo_id::BIGINT                 AS repo_id,
    created_at::TIMESTAMPTZ         AS event_created_at,
    is_public::BOOLEAN              AS is_public,
    source_system::VARCHAR          AS source_system,
    _ingested_at::TIMESTAMPTZ       AS _ingested_at
FROM {{ source('external_apis', 'github_events') }}
WHERE id IS NOT NULL
