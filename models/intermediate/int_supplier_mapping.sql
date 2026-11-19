/*
  int_supplier_mapping
  Grain: one row per Ariba supplier ID.
  Ariba and SAP share no ID. We match on VAT number. Unmatched suppliers are kept
  (is_matched = FALSE) so they show up in reports instead of disappearing.
*/
with ariba_suppliers as (
    select ariba_supplier_id, vat_number, supplier_name from {{ ref('stg_ariba__contracts') }}
    union
    select ariba_supplier_id, vat_number, supplier_name from {{ ref('stg_ariba__bids') }}
)

select
    a.ariba_supplier_id,
    a.vat_number,
    any_value(a.supplier_name)              as ariba_supplier_name,
    any_value(g.golden_supplier_id)         as golden_supplier_id,
    any_value(g.golden_supplier_id) is not null as is_matched
from ariba_suppliers a
left join {{ ref('int_supplier_golden_record') }} g on g.vat_number = a.vat_number
where a.ariba_supplier_id is not null
group by a.ariba_supplier_id, a.vat_number
qualify row_number() over (partition by a.ariba_supplier_id order by is_matched desc) = 1
