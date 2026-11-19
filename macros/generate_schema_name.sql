{#
  Use the schema name from +schema exactly (STAGING, INTERMEDIATE, MARTS, SNAPSHOTS)
  instead of dbt's default "<target_schema>_<custom_schema>".
  Our schemas already exist in S2C_DEV (created by s2c-snowflake-data-source).
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema | trim | upper }}
    {%- else -%}
        {{ custom_schema_name | trim | upper }}
    {%- endif -%}
{%- endmacro %}
