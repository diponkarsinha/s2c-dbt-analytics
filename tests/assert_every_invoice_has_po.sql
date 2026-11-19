-- Every invoice line should point to a PO line that exists.  (5 planted orphans)
{{ config(severity='warn') }}
select invoice_item_key, po_item_key
from {{ ref('fct_invoice_line') }}
where not has_po_line
