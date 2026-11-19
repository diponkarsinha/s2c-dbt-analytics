/*
  fct_request_pipeline
  Grain: one row per sourcing request.
  Walks the S2C chain: request -> event -> award -> contract.
  cycle_time_days = request created -> award; SLA = var sla_days (45).
*/
with first_contract as (
    select event_id, contract_id, signed_date
    from {{ ref('dim_contract') }}
    where event_id is not null and not is_deleted
    qualify row_number() over (partition by event_id order by signed_date) = 1
)

select
    r.request_id,
    r.category_id,
    r.business_unit,
    r.request_status,
    r.estimated_value,
    r.created_at::date                                         as requested_date,
    r.sla_due_date,
    e.event_id,
    e.event_status,
    e.awarded_date,
    c.contract_id,
    c.signed_date                                              as contract_signed_date,
    datediff(day, r.created_at, e.awarded_date)                as cycle_time_days,
    case
        when e.awarded_date is not null then e.awarded_date > r.sla_due_date
        when r.request_status in ('Cancelled') then false
        else current_date() > r.sla_due_date
    end                                                        as is_sla_breached,
    case
        when c.contract_id is not null then '4 Contracted'
        when e.awarded_date is not null then '3 Awarded'
        when e.event_id is not null then '2 Sourcing'
        when r.request_status = 'Cancelled' then '0 Cancelled'
        else '1 Intake'
    end                                                        as pipeline_stage
from {{ ref('stg_ariba__requests') }} r
left join {{ ref('fct_sourcing_event') }} e on e.event_id = r.event_id
left join first_contract c on c.event_id = e.event_id
