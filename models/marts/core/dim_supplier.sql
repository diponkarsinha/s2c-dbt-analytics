/*
  dim_supplier
  Grain: one row per golden supplier (one real company).
  Risk: the live score from the speed layer wins; otherwise the latest weekly assessment.
*/
with latest_assessment as (
    select *
    from {{ ref('stg_risk__assessments') }}
    qualify row_number() over (partition by vat_number order by generated_at desc) = 1
)

select
    g.golden_supplier_id                                         as supplier_id,
    g.supplier_name,
    g.vat_number,
    g.country_code,
    r.country_name,
    r.region,
    g.city,
    g.is_blocked,
    g.has_duplicates,
    g.sap_id_count,
    a.financial_risk_score                                       as weekly_risk_score,
    cur.live_risk_score,
    coalesce(cur.live_risk_score, a.financial_risk_score)        as risk_score,
    {{ risk_band('coalesce(cur.live_risk_score, a.financial_risk_score)') }} as risk_band,
    coalesce(cur.sanctions_hit, false)                           as sanctions_hit,
    a.esg_score,
    a.esg_medal,
    a.assessed_on,
    a.next_review_due,
    coalesce(a.is_review_overdue, false)                         as is_review_overdue,
    a.vat_number is null and cur.vat_number is null              as is_not_assessed
from {{ ref('int_supplier_golden_record') }} g
left join {{ ref('country_regions') }} r   on r.country_code = g.country_code
left join latest_assessment a              on a.vat_number = g.vat_number
left join {{ ref('stg_risk__current') }} cur on cur.vat_number = g.vat_number
