/*
  kpi_spend_monthly  (KPI-01 spend under contract %, KPI-02 maverick spend, KPI-03 total spend)
  Grain: month x level-1 category x business unit.
*/
select
    f.posting_month                                                   as month_start,
    coalesce(c.l1_category_name, 'Unmapped')                          as category_l1,
    coalesce(f.business_unit, 'Unknown')                              as business_unit,
    count(*)                                                          as invoice_lines,
    round(sum(f.amount_eur), 2)                                       as total_spend_eur,
    round(sum(iff(f.is_under_contract, f.amount_eur, 0)), 2)          as spend_under_contract_eur,
    round(sum(iff(f.is_maverick, f.amount_eur, 0)), 2)                as maverick_spend_eur,
    round(100 * sum(iff(f.is_under_contract, f.amount_eur, 0)) / nullif(sum(f.amount_eur), 0), 1)
                                                                      as spend_under_contract_pct,
    round(sum(iff(f.is_fx_missing, f.amount, 0)), 2)                  as amount_without_fx_rate
from {{ ref('fct_spend') }} f
left join {{ ref('dim_category') }} c on c.category_id = f.category_id
group by 1, 2, 3
