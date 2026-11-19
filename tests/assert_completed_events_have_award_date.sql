-- A completed sourcing event must have an award date.  (5 planted + wave 10)
{{ config(severity='warn') }}
select event_id, event_status, awarded_date
from {{ ref('fct_sourcing_event') }}
where is_missing_award_date
