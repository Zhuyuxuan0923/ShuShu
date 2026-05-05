{{ config(materialized='table') }}

WITH daily AS (
    SELECT *
    FROM {{ ref('dws_github_daily_activity') }}
    WHERE event_date >= CURRENT_DATE - INTERVAL '7 days'
),
ranked AS (
    SELECT
        event_date,
        event_type,
        category,
        event_count,
        unique_actors,
        unique_repos,
        LAG(event_count, 1) OVER (
            PARTITION BY event_type ORDER BY event_date
        ) AS prev_day_count,
        LAG(event_count, 7) OVER (
            PARTITION BY event_type ORDER BY event_date
        ) AS week_ago_count,
        RANK() OVER (
            PARTITION BY event_date ORDER BY event_count DESC
        ) AS daily_rank
    FROM daily
)
SELECT
    event_date,
    event_type,
    COALESCE(category, 'uncategorized')    AS category,
    event_count,
    unique_actors,
    unique_repos,
    daily_rank,
    CASE
        WHEN prev_day_count > 0
        THEN ROUND((event_count - prev_day_count)::NUMERIC / prev_day_count * 100, 2)
        ELSE NULL
    END                                     AS day_over_day_pct,
    CASE
        WHEN week_ago_count > 0
        THEN ROUND((event_count - week_ago_count)::NUMERIC / week_ago_count * 100, 2)
        ELSE NULL
    END                                     AS week_over_week_pct,
    CURRENT_TIMESTAMP                       AS _ads_generated_at
FROM ranked
