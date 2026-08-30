{#
    Convert a date/timestamp expression into the YYYYMMDD integer surrogate key
    used by dim_date. Returns NULL for a NULL input. Portable across DuckDB and
    Snowflake (extract() only).
#}
{% macro date_to_key(ts_column) %}
    case when {{ ts_column }} is not null then
        cast(extract(year  from {{ ts_column }}) as integer) * 10000
      + cast(extract(month from {{ ts_column }}) as integer) * 100
      + cast(extract(day   from {{ ts_column }}) as integer)
    end
{% endmacro %}
