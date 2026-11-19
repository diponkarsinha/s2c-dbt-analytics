-- Savings in the Excel tracker must equal baseline - negotiated.  (5 planted)
{{ config(severity='warn') }}
select savings_id, reported_baseline_eur, reported_negotiated_eur, reported_savings_eur, sheet_math_savings_eur
from {{ ref('fct_savings') }}
where is_sheet_math_wrong
