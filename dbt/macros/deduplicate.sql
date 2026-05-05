{% macro deduplicate(partition_by, order_by='_ingested_at DESC') %}
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY {{ partition_by }}
        ORDER BY {{ order_by }}
    ) = 1
{% endmacro %}
