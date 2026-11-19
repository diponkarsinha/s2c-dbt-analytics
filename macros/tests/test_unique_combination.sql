{#
  Generic test: the combination of columns is unique.
  Usage (yml, model level):
    data_tests:
      - unique_combination:
          columns: ["event_id", "bid_id", "bid_round"]
#}
{% test unique_combination(model, columns) %}
select {{ columns | join(', ') }}, count(*) as n
from {{ model }}
group by {{ columns | join(', ') }}
having count(*) > 1
{% endtest %}
