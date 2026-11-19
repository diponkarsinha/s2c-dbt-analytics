{# 1-3 Low, 4-6 Medium, 7-9 High, anything else Not assessed #}
{% macro risk_band(score) -%}
    case
        when {{ score }} between 1 and 3 then 'Low'
        when {{ score }} between 4 and 6 then 'Medium'
        when {{ score }} between 7 and 9 then 'High'
        else 'Not assessed'
    end
{%- endmacro %}
