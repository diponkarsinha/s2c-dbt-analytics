{#
  Normalise booleans that arrive in many shapes:
  true / false (JSON boolean), 'true' / 'false', 'Y' / 'N', 'Yes' / 'No', 'X' / ''
  Used for contracts.autoRenew, savings "Validated by Finance", SAP flags.
#}
{% macro to_boolean(expr) -%}
    case
        when {{ expr }} is null then null
        when upper(trim({{ expr }}::string)) in ('TRUE', 'Y', 'YES', 'X', '1') then true
        when upper(trim({{ expr }}::string)) in ('FALSE', 'N', 'NO', '', '0') then false
        else null
    end
{%- endmacro %}
