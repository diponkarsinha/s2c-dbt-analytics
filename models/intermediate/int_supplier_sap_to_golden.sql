/* int_supplier_sap_to_golden: every SAP supplier ID -> its golden supplier ID (via VAT). */
select
    s.sap_supplier_id,
    g.golden_supplier_id,
    s.vat_number,
    s.sap_supplier_id <> g.golden_supplier_id   as is_duplicate_id,
    s.is_blocked                                as is_this_id_blocked
from {{ ref('stg_sap__suppliers') }} s
join {{ ref('int_supplier_golden_record') }} g on g.vat_number = s.vat_number
