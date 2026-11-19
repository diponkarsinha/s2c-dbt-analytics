-- 3-way match: invoiced quantity must not exceed the ordered quantity.  (6 planted)
{{ config(severity='warn') }}
select invoice_item_key, po_item_key, quantity, po_quantity
from {{ ref('fct_invoice_line') }}
where is_over_invoiced and not is_credit
