{# ---------------------------------------------------------------------------
   Helpers for SAP extracts (text in RAW, SAP formats)
   --------------------------------------------------------------------------- #}

{# '1234,50' -> 1234.50 ; text -> NULL (never fails) #}
{% macro sap_number(column, scale=2) -%}
    try_to_number(replace(trim({{ column }}), ',', '.'), 18, {{ scale }})
{%- endmacro %}

{# '20261102' -> 2026-11-02 ; invalid -> NULL #}
{% macro sap_date(column) -%}
    try_to_date(nullif(trim({{ column }}), ''), 'YYYYMMDD')
{%- endmacro %}

{# collapse double spaces, trim, empty -> NULL #}
{% macro clean_text(column) -%}
    nullif(trim(regexp_replace(replace({{ column }}, chr(65533), '?'), '\\s+', ' ')), '')
{%- endmacro %}
