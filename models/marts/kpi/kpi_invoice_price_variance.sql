/*
  kpi_invoice_price_variance  (KPI-11 billed above the agreed price)
  Grain: month x supplier.
*/
select
    f.posting_month                                                 as month_start,
    f.supplier_id,
    s.supplier_name,
    count(*)                                                        as invoice_lines,
    count_if(f.price_variance_eur > 0)                              as lines_above_po_price,
    round(sum(f.amount_eur), 2)                                     as invoiced_eur,
    round(sum(f.price_variance_eur), 2)                             as price_variance_eur,
    round(100 * sum(f.price_variance_eur) / nullif(sum(f.amount_eur), 0), 2) as price_variance_pct
from {{ ref('fct_spend') }} f
left join {{ ref('dim_supplier') }} s on s.supplier_id = f.supplier_id
where not f.is_credit
group by 1, 2, 3
having count_if(f.price_variance_eur > 0) > 0
