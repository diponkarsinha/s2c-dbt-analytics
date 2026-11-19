/*
  int_supplier_golden_record
  Grain: one row per real-world supplier (one VAT number).

  SAP has duplicates: the same company created again under a new LIFNR with a
  slightly different name. The VAT number is the same, so we group by VAT:
    golden_supplier_id = the OLDEST SAP ID for that VAT (the original record)
    supplier_name      = the name on that oldest record
    is_blocked         = TRUE if ANY of its SAP IDs is blocked
*/
with suppliers as (
    select * from {{ ref('stg_sap__suppliers') }}
),

ranked as (
    select
        *,
        row_number() over (partition by vat_number order by created_on, sap_supplier_id) as rn
    from suppliers
)

select
    r.vat_number,
    r.sap_supplier_id                                         as golden_supplier_id,
    r.supplier_name,
    r.country_code,
    r.city,
    r.created_on,
    agg.sap_id_count,
    agg.sap_supplier_ids,
    agg.is_blocked,
    agg.sap_id_count > 1                                      as has_duplicates
from ranked r
join (
    select
        vat_number,
        count(*)                                              as sap_id_count,
        array_agg(sap_supplier_id) within group (order by sap_supplier_id) as sap_supplier_ids,
        boolor_agg(is_blocked)                                as is_blocked
    from suppliers
    group by vat_number
) agg on agg.vat_number = r.vat_number
where r.rn = 1
