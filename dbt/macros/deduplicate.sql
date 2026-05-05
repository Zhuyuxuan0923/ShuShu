{% macro deduplicate(partition_by, order_by='_ingested_at DESC') %}
    -- PostgreSQL does not support QUALIFY.
    -- Models must use SELECT DISTINCT ON ({{ partition_by }}) ... ORDER BY {{ partition_by }}, {{ order_by }} instead.
{% endmacro %}
