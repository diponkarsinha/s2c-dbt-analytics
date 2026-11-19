-- Business rule: no PO charged to a cost centre that was already closed.  (6 planted)
{{ config(severity='warn') }}
select po_item_key, cost_center_id, po_date
from {{ ref('fct_purchase_order_line') }}
where is_closed_cost_center and not is_deleted
