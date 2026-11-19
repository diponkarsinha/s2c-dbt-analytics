-- Invoices should not be posted against PO lines deleted in SAP.  (3 planted)
{{ config(severity='warn') }}
select invoice_item_key, po_item_key
from {{ ref('fct_invoice_line') }}
where is_po_line_deleted
