/*
  kpi_sourcing_performance  (KPI-04 cycle time, KPI-05 SLA breaches, KPI-10 single-source %)
  Grain: quarter x level-1 category.
*/
select
    date_trunc('quarter', p.requested_date)                               as quarter_start,
    coalesce(c.l1_category_name, 'Unmapped')                              as category_l1,
    count(*)                                                              as requests,
    count(p.event_id)                                                     as events_started,
    count(p.awarded_date)                                                 as awards,
    round(avg(p.cycle_time_days), 1)                                      as avg_cycle_time_days,
    round(median(p.cycle_time_days), 1)                                   as median_cycle_time_days,
    count_if(p.is_sla_breached)                                           as sla_breaches,
    round(100 * count_if(p.is_sla_breached) / nullif(count(*), 0), 1)     as sla_breach_pct,
    round(100 * count_if(e.is_single_source) / nullif(count(e.event_id), 0), 1) as single_source_pct
from {{ ref('fct_request_pipeline') }} p
left join {{ ref('fct_sourcing_event') }} e on e.event_id = p.event_id
left join {{ ref('dim_category') }} c on c.category_id = p.category_id
group by 1, 2
