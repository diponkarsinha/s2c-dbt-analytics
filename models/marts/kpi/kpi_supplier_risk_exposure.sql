/*
  kpi_supplier_risk_exposure  (KPI-09 spend with high-risk suppliers)
  Grain: one row per supplier with spend in the last 12 months.
  "Not assessed" counts as risky: we cannot prove it is safe.
*/
with spend_12m as (
    select supplier_id, sum(amount_eur) as spend_12m_eur
    from {{ ref('fct_spend') }}
    where posting_date >= dateadd(month, -12, current_date())
    group by supplier_id
)

select
    s.supplier_id,
    s.supplier_name,
    s.country_code,
    s.region,
    s.risk_score,
    s.risk_band,
    s.sanctions_hit,
    s.is_blocked,
    s.is_review_overdue,
    s.is_not_assessed,
    round(coalesce(sp.spend_12m_eur, 0), 2)                                as spend_12m_eur,
    s.risk_band in ('High', 'Not assessed') or s.sanctions_hit            as is_risky,
    round(100 * ratio_to_report(coalesce(sp.spend_12m_eur, 0)) over (), 2) as share_of_total_spend_pct
from {{ ref('dim_supplier') }} s
left join spend_12m sp on sp.supplier_id = s.supplier_id
where coalesce(sp.spend_12m_eur, 0) <> 0
