/*
  stg_risk__current
  Latest risk score per supplier from the speed layer (Snowpipe -> stream -> task).
  Already validated and event-time ordered by SP_PROCESS_RISK_EVENTS.
*/
select
    supplier_vat        as vat_number,
    risk_score          as live_risk_score,
    risk_band           as live_risk_band,
    sanctions_hit,
    last_event_id,
    last_event_time,
    updated_at
from {{ source('streaming', 'RISK_CURRENT') }}
