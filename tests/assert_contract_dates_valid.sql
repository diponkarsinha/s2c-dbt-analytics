-- Contracts: end after start, signed on or before start.  (3 + 4 planted)
{{ config(severity='warn') }}
select contract_id, start_date, end_date, signed_date,
       iff(end_date < start_date, 'end before start', 'signed after start') as problem
from {{ ref('dim_contract') }}
where not is_deleted
  and (end_date < start_date or signed_date > start_date)
