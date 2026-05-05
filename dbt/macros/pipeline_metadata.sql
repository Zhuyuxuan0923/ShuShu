{% macro add_pipeline_metadata(include_layer=true) %}
    _ingested_at,
    source_system
    {% if include_layer %}
    , '{{ model.schema | upper }}' AS _layer
    {% endif %}
{% endmacro %}
