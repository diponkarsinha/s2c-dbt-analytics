{#
  Generic test: a SQL expression must be true for every row.
  Usage (yml, model level):
    data_tests:
      - expression_is_true:
          expression: "end_date >= start_date"
#}
{% test expression_is_true(model, expression, column_name=none) %}
select *
from {{ model }}
where not ({{ expression }})
{% endtest %}
