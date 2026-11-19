/* dim_supplier_history: SCD2 view of SAP supplier changes from the snapshot. */
select
    sap_supplier_id,
    supplier_name,
    city,
    vat_number,
    is_blocked,
    bank_country,
    dbt_valid_from                    as valid_from,
    dbt_valid_to                      as valid_to,
    dbt_valid_to is null              as is_current
from {{ ref('snap_sap_suppliers') }}
