/*
  kpi_scorecard
  Grain: one row per KPI. Current value (last 12 months) vs target from seeds/kpi_targets.csv.
  This is the table a leadership dashboard would read first.
*/
with spend as (
    select
        100 * sum(iff(is_under_contract, amount_eur, 0)) / nullif(sum(amount_eur), 0) as under_contract_pct,
        100 * sum(iff(is_maverick, amount_eur, 0)) / nullif(sum(amount_eur), 0)       as maverick_pct,
        100 * sum(iff(risk_band in ('High', 'Not assessed'), amount_eur, 0)) / nullif(sum(amount_eur), 0) as risky_pct,
        100 * sum(price_variance_eur) / nullif(sum(iff(is_credit, 0, amount_eur)), 0)  as price_variance_pct
    from {{ ref('fct_spend') }}
    where posting_date >= dateadd(month, -12, current_date())
),

pipeline as (
    select
        avg(cycle_time_days)                                       as avg_cycle_days,
        100 * count_if(is_sla_breached) / nullif(count(*), 0)      as sla_breach_pct
    from {{ ref('fct_request_pipeline') }}
),

events as (
    select 100 * count_if(is_single_source) / nullif(count(*), 0) as single_source_pct
    from {{ ref('fct_sourcing_event') }}
    where event_status <> 'Cancelled'
),

savings as (
    select 100 * sum(iff(is_validated_by_finance, recalculated_savings_eur, 0))
               / nullif(sum(reported_savings_eur), 0)             as validated_pct
    from {{ ref('fct_savings') }}
),

actuals as (
    select 'KPI-01' as kpi_id, (select under_contract_pct from spend)  as actual_value
    union all select 'KPI-02', (select maverick_pct from spend)
    union all select 'KPI-04', (select avg_cycle_days from pipeline)
    union all select 'KPI-05', (select sla_breach_pct from pipeline)
    union all select 'KPI-06', (select validated_pct from savings)
    union all select 'KPI-09', (select risky_pct from spend)
    union all select 'KPI-10', (select single_source_pct from events)
    union all select 'KPI-11', (select price_variance_pct from spend)
)

select
    t.kpi_id,
    t.kpi_name,
    t.unit,
    round(a.actual_value, 1)                                   as actual_value,
    t.target_value,
    t.better_when,
    case
        when a.actual_value is null then 'No data'
        when t.better_when = 'higher' and a.actual_value >= t.target_value then 'On track'
        when t.better_when = 'lower'  and a.actual_value <= t.target_value then 'On track'
        else 'Off track'
    end                                                        as status
from {{ ref('kpi_targets') }} t
left join actuals a on a.kpi_id = t.kpi_id
order by t.kpi_id
