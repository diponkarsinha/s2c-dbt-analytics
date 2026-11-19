/*
  fct_spend
  Grain: one row per invoice line (money actually spent).
  The main fact for spend analytics: amount in EUR + contract / risk / compliance flags.
  Spend = invoices (not POs): a PO is an intention, an invoice is real money.
*/
select
    f.invoice_item_key,
    f.posting_date,
    f.posting_month,
    f.supplier_id,
    s.risk_band,
    s.is_blocked                                 as is_supplier_blocked,
    f.category_id,
    f.cost_center_id,
    cc.business_unit,
    f.contract_id,
    f.is_under_contract,
    f.is_maverick,
    f.has_po_line,
    f.is_credit,
    f.amount,
    f.currency,
    f.amount_eur,
    f.is_fx_missing,
    f.price_variance_eur
from {{ ref('fct_invoice_line') }} f
left join {{ ref('dim_supplier') }} s      on s.supplier_id = f.supplier_id
left join {{ ref('dim_cost_center') }} cc  on cc.cost_center_id = f.cost_center_id
