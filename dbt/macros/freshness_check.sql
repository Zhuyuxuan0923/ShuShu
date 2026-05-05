{% macro log_freshness(results) %}
    {%- if execute -%}
        {% for result in results %}
            {% if result.status == 'error' or result.status == 'warn' %}
                {{ log("FRESHNESS " + result.status | upper + ": " + result.node.name + " - loaded_at: " + result.loaded_at, info=True) }}
            {% endif %}
        {% endfor %}
    {%- endif -%}
{% endmacro %}
