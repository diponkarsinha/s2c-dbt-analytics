/*
  int_invoice_lines_enriched
  Grain: one row per invoice line. Adds the PO line it belongs to, EUR amount,
  and price checks against the PO.
*/
with inv as (
    select * from {{ ref('stg_sap__invoices') }}
)

select
    inv.invoice_item_key,
    inv.invoice_number,
    inv.fiscal_year,
    inv.invoice_line_number,
    inv.posting_date,
    date_trunc('month', inv.posting_date)                          as posting_month,
    inv.sap_supplier_id,
    coalesce(po.golden_supplier_id, m.golden_supplier_id)          as golden_supplier_id,
    inv.po_item_key,
    po.po_item_key is not null                                     as has_po_line,
    coalesce(po.is_deleted, false)                                 as is_po_line_deleted,
    po.category_id,
    po.cost_center_id,
    po.contract_id,
    coalesce(po.is_under_contract, false)                          as is_under_contract,
    coalesce(po.is_maverick, true)                                 as is_maverick,
    inv.quantity,
    po.quantity                                                    as po_quantity,
    inv.quantity > po.quantity                                     as is_over_invoiced,
    inv.amount,
    inv.currency,
    round(inv.amount / fx.units_per_eur, 2)                        as amount_eur,
    fx.units_per_eur is null                                       as is_fx_missing,
    round(inv.amount / nullif(inv.quantity, 0), 4)                 as invoiced_unit_price,
    po.net_price                                                   as po_unit_price,
    -- price variance in EUR: only charged above the PO price, debit lines only
    iff(not inv.is_credit and po.net_price is not null
            and inv.amount / nullif(inv.quantity, 0) > po.net_price * 1.001,
        round((inv.amount - inv.quantity * po.net_price) / fx.units_per_eur, 2),
        0)                                                         as price_variance_eur,
    inv.is_credit,
    inv.reversed_invoice_number,
    inv.source_file,
    inv.loaded_at
from inv
left join {{ ref('int_po_items_enriched') }} po    on po.po_item_key = inv.po_item_key
left join {{ ref('int_supplier_sap_to_golden') }} m on m.sap_supplier_id = inv.sap_supplier_id
left join {{ ref('int_fx_monthly') }} fx
       on fx.from_currency = inv.currency and fx.rate_month = date_trunc('month', inv.posting_date)
