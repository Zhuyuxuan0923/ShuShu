SELECT event_id
FROM {{ ref('ods_github_events') }}
WHERE event_id IS NULL
   OR event_id = ''
   OR event_type IS NULL
   OR event_type = ''
