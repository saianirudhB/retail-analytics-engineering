{#
    Map a two-letter Brazilian state code (UF) to its macro-region.
    Used by dim_customers and dim_sellers so regional roll-ups are defined
    once. Source: IBGE's five official regions.
#}
{% macro brazil_region(state_column) %}
    case upper({{ state_column }})
        when 'AC' then 'North'        when 'AP' then 'North'
        when 'AM' then 'North'        when 'PA' then 'North'
        when 'RO' then 'North'        when 'RR' then 'North'
        when 'TO' then 'North'
        when 'AL' then 'Northeast'    when 'BA' then 'Northeast'
        when 'CE' then 'Northeast'    when 'MA' then 'Northeast'
        when 'PB' then 'Northeast'    when 'PE' then 'Northeast'
        when 'PI' then 'Northeast'    when 'RN' then 'Northeast'
        when 'SE' then 'Northeast'
        when 'DF' then 'Central-West' when 'GO' then 'Central-West'
        when 'MT' then 'Central-West' when 'MS' then 'Central-West'
        when 'ES' then 'Southeast'    when 'MG' then 'Southeast'
        when 'RJ' then 'Southeast'    when 'SP' then 'Southeast'
        when 'PR' then 'South'        when 'RS' then 'South'
        when 'SC' then 'South'
        else 'Unknown'
    end
{% endmacro %}
