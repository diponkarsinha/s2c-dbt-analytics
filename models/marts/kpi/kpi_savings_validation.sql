/*
  kpi_savings_validation  (KPI-06 validated savings, KPI-07 reconciliation gap)
  Grain: quarter x level-1 category.
*/
select
    f.savings_quarter,
    coalesce(c.l1_category_name, 'Unmapped')                               as category_l1,
    count(*)                                                               as savings_lines,
    round(sum(f.reported_savings_eur), 2)                                  as reported_savings_eur,
    round(sum(f.recalculated_savings_eur), 2)                              as recalculated_savings_eur,
    round(sum(iff(f.is_validated_by_finance, f.recalculated_savings_eur, 0)), 2) as validated_savings_eur,
    round(sum(f.savings_gap_eur), 2)                                       as savings_gap_eur,
    count_if(f.is_sheet_math_wrong)                                        as lines_with_wrong_math,
    round(100 * sum(iff(f.is_validated_by_finance, f.recalculated_savings_eur, 0))
              / nullif(sum(f.reported_savings_eur), 0), 1)                 as validated_vs_reported_pct
from {{ ref('fct_savings') }} f
left join {{ ref('dim_category') }} c on c.category_id = f.category_id
group by 1, 2
