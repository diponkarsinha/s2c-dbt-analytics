{#
  on-run-start hook.
  Reads S2C_DEV.AUDIT.V_PIPELINE_GATE (built in s2c-snowflake-data-source).
  If data is incomplete (a file was uploaded but not loaded, row counts do not
  match, Snowflake reported load errors) the gate is BLOCKED and we stop
  BEFORE any model is rebuilt, so Gold keeps its last good version.

  Skip with:  dbt build --vars '{enforce_gate: false}'
#}
{% macro check_pipeline_gate() %}
    {% if execute and var('enforce_gate', true) and flags.WHICH in ('run', 'build') %}
        {% set gate_sql %}
            select gate_status, open_blocking_issues
            from {{ target.database }}.audit.v_pipeline_gate
        {% endset %}
        {% set result = run_query(gate_sql) %}
        {% if result and result.rows | length > 0 %}
            {% set status = result.rows[0][0] %}
            {% set issues = result.rows[0][1] %}
            {% if status == 'BLOCKED' %}
                {{ exceptions.raise_compiler_error(
                    "Pipeline gate is BLOCKED (" ~ issues ~ " open blocking issues). "
                    ~ "See AUDIT.V_DQ_OPEN_FAILURES, fix or acknowledge, then re-run. "
                    ~ "To bypass: --vars '{enforce_gate: false}'") }}
            {% else %}
                {{ log("Pipeline gate: " ~ status, info=true) }}
            {% endif %}
        {% endif %}
    {% endif %}
    select 1
{% endmacro %}
