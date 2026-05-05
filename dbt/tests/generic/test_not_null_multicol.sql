{% test not_null_multicol(model, columns) %}
    SELECT *
    FROM {{ model }}
    WHERE {% for col in columns %}
        {{ col }} IS NULL{% if not loop.last %} AND {% endif %}
    {% endfor %}
{% endtest %}
