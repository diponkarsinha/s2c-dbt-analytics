{#
  Post-hook: attach the GOVERNANCE.MP_EMAIL masking policy to an email column.
  Rendered at run time, so {{ this }} is the table/view just built.

  Usage in a model:
      {{ config(post_hook="{{ mask_email('owner_email') }}") }}

  FORCE replaces a policy that is already attached (incremental tables keep theirs).
  Result: analysts see *****@samplepharma.example; roles with S2C_PII_READER see the email.
#}
{% macro mask_email(column) -%}
    alter {{ 'view' if model.config.materialized == 'view' else 'table' }} {{ this }}
        modify column {{ column }}
        set masking policy {{ target.database }}.governance.mp_email force
{%- endmacro %}
