{#
    Render a Jinja list of strings as a SQL IN-list tuple, e.g.
        {{ status_list(['delivered', 'shipped']) }}  ->  ('delivered', 'shipped')
    Keeps the "which statuses count as revenue" rule defined once, in
    dbt_project.yml vars, rather than copy-pasted across metric models.
#}
{% macro status_list(values) %}
    ({%- for v in values -%}
        '{{ v }}'{{ "," if not loop.last }}
    {%- endfor -%})
{% endmacro %}
