-- A reversal must cancel the original invoice line exactly (amount + reversal = 0).
-- Severity ERROR: if this fails, spend totals are wrong.
select r.invoice_item_key as reversal_key, o.invoice_item_key as original_key,
       o.amount as original_amount, r.amount as reversal_amount
from {{ ref('fct_invoice_line') }} r
join {{ ref('fct_invoice_line') }} o
  on  o.invoice_number = r.reversed_invoice_number
  and o.invoice_line_number = r.invoice_line_number
where r.reversed_invoice_number is not null
  and abs(o.amount + r.amount) > 0.01
