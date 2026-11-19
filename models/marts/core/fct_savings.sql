/*
  fct_savings
  Grain: one row per savings line from the Excel tracker.
  Compares what Procurement REPORTED with what the sourcing data PROVES:
    recalculated = event baseline - awarded amount
    gap          = reported - recalculated
*/
select
    s.savings_id,
    s.event_id,
    e.category_id,
    e.awarded_supplier_id                                   as supplier_id,
    s.savings_date,
    date_trunc('quarter', s.savings_date)                   as savings_quarter,
    s.baseline_eur                                          as reported_baseline_eur,
    s.negotiated_eur                                        as reported_negotiated_eur,
    s.reported_savings_eur,
    s.baseline_eur - s.negotiated_eur                       as sheet_math_savings_eur,
    abs(s.reported_savings_eur - (s.baseline_eur - s.negotiated_eur)) > 0.01 as is_sheet_math_wrong,
    e.calculated_savings_eur                                as recalculated_savings_eur,
    s.reported_savings_eur - coalesce(e.calculated_savings_eur, 0) as savings_gap_eur,
    e.event_id is not null                                  as has_matching_event,
    s.is_validated_by_finance
from {{ ref('stg_manual__savings') }} s
left join {{ ref('fct_sourcing_event') }} e on e.event_id = s.event_id
