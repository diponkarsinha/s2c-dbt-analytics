/* stg_risk__alerts: one row per alert raised by the speed layer. */
select
    alert_id,
    event_id,
    supplier_vat       as vat_number,
    alert_type,
    risk_score,
    previous_score,
    event_time,
    is_late,
    status             as alert_status,
    created_at
from {{ source('streaming', 'RISK_ALERTS') }}
