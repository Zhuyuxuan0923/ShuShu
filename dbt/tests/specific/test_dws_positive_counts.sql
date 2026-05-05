SELECT event_date, event_type, event_count
FROM {{ ref('dws_github_daily_activity') }}
WHERE event_count < 0
   OR unique_actors < 0
   OR unique_repos < 0
