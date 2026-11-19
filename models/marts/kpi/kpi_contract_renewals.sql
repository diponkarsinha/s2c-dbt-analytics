/*
  kpi_contract_renewals  (KPI-08 contracts expiring soon)
  Grain: one row per active contract ending in the next N days (var expiry_window_days),
  with the spend that depends on it, so the biggest renewals are handled first.
*/
with spend_12m as (
    select contract_id, sum(amount_eur) as spend_12m_eur
    from {{ ref('fct_spend') }}
    where contract_id is not null and posting_date >= dateadd(month, -12, current_date())
    group by contract_id
)

select
    c.contract_id,
    c.contract_title,
    c.supplier_id,
    c.category_id,
    c.end_date,
    c.notice_deadline,
    c.days_to_expiry,
    c.is_auto_renew,
    current_date() > c.notice_deadline                     as is_notice_deadline_passed,
    case
        when c.days_to_expiry <= 30 then '0-30 days'
        when c.days_to_expiry <= 60 then '31-60 days'
        else '61-90 days'
    end                                                    as expiry_bucket,
    round(coalesce(s.spend_12m_eur, 0), 2)                 as spend_12m_eur
from {{ ref('dim_contract') }} c
left join spend_12m s on s.contract_id = c.contract_id
where not c.is_deleted
  and c.has_valid_term
  and c.contract_status = 'Active'
  and c.days_to_expiry between 0 and {{ var('expiry_window_days', 90) }}
