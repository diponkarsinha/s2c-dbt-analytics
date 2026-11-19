/*
  dim_contract
  Grain: one row per contract (current version), with supplier match and renewal dates.
  notice_deadline = end_date - notice period: after that date it is too late to renegotiate.
*/
select
    c.contract_id,
    c.contract_title,
    m.golden_supplier_id                                    as supplier_id,
    m.is_matched                                            as is_supplier_matched,
    c.ariba_supplier_id,
    c.category_id,
    c.event_id,
    c.contract_value,
    c.contract_currency,
    c.start_date,
    c.end_date,
    c.signed_date,
    c.notice_period_days,
    dateadd(day, -c.notice_period_days, c.end_date)        as notice_deadline,
    datediff(day, current_date(), c.end_date)               as days_to_expiry,
    c.is_auto_renew,
    c.contract_status,
    c.is_deleted,
    c.end_date >= c.start_date                              as has_valid_term,
    coalesce(a.amendment_count, 0)                          as amendment_count
from {{ ref('stg_ariba__contracts') }} c
left join {{ ref('int_supplier_mapping') }} m on m.ariba_supplier_id = c.ariba_supplier_id
left join (
    select contract_id, count(*) as amendment_count
    from {{ ref('stg_ariba__contract_amendments') }}
    group by contract_id
) a on a.contract_id = c.contract_id
