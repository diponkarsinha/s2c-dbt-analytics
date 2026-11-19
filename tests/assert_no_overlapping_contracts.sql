-- Same supplier + same category should not have two contracts active at the same time.  (5 planted)
-- Classic interval-overlap self join: A.start <= B.end AND B.start <= A.end
{{ config(severity='warn') }}
select a.contract_id as contract_a, b.contract_id as contract_b, a.supplier_id, a.category_id,
       a.start_date as a_start, a.end_date as a_end, b.start_date as b_start, b.end_date as b_end
from {{ ref('dim_contract') }} a
join {{ ref('dim_contract') }} b
  on  a.supplier_id = b.supplier_id
  and a.category_id = b.category_id
  and a.contract_id < b.contract_id
  and a.start_date <= b.end_date
  and b.start_date <= a.end_date
where not a.is_deleted and not b.is_deleted
  and a.has_valid_term and b.has_valid_term
