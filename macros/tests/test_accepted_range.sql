{#
  Generic test: every value of the column is between min_value and max_value.
  Usage (yml):  - accepted_range: {min_value: 1, max_value: 9}
#}
{% test accepted_range(model, column_name, min_value=none, max_value=none) %}
select *
from {{ model }}
where {{ column_name }} is not null
  and (
      {% if min_value is not none %} {{ column_name }} < {{ min_value }} {% else %} false {% endif %}
      or
      {% if max_value is not none %} {{ column_name }} > {{ max_value }} {% else %} false {% endif %}
  )
{% endtest %}
