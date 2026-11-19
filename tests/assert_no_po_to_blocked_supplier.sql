-- Business rule: no purchase orders to a supplier blocked in SAP.  (5 planted + wave 8)
{{ config(severity='warn') }}
select po_item_key, supplier_id, sap_supplier_id, po_date, net_value_eur
from {{ ref('fct_purchase_order_line') }}
where is_blocked_supplier and not is_deleted
