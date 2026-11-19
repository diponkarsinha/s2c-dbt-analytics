-- Speed layer vs batch: every supplier with a HIGH_RISK alert must show High in dim_supplier
-- unless a newer event lowered the score. Checks the two paths agree.
{{ config(severity='warn') }}
select a.vat_number, a.risk_score as alert_score, s.risk_score as current_score, s.risk_band
from {{ ref('stg_risk__alerts') }} a
join {{ ref('dim_supplier') }} s on s.vat_number = a.vat_number
join {{ ref('stg_risk__current') }} c on c.vat_number = a.vat_number
where a.alert_type = 'HIGH_RISK'
  and c.last_event_id = a.event_id
  and s.risk_band <> 'High'
