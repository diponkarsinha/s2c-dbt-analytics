/*
  int_po_items_enriched
  Grain: one row per PO line. Adds golden supplier, category, cost centre status,
  contract check and EUR amount.

  Compliance flags (reported, never dropped):
    is_maverick                PO without a valid contract for that supplier
    is_blocked_supplier        PO to a supplier that is blocked in SAP
    is_closed_cost_center      PO charged to a cost centre closed before the PO date
*/
with po as (
    select * from {{ ref('stg_sap__po_items') }}
),

contracts as (
    select * from {{ ref('stg_ariba__contracts') }} where not is_deleted
)

select
    po.po_item_key,
    po.po_number,
    po.po_line_number,
    po.company_code,
    po.po_date,
    date_trunc('month', po.po_date)                               as po_month,
    po.changed_on,
    po.sap_supplier_id,
    m.golden_supplier_id,
    po.material_group,
    cat.category_id,
    cat.is_active                                                 as is_category_active,
    po.cost_center_id,
    po.quantity,
    po.net_price,
    po.net_value,
    po.currency,
    round(po.net_value / fx.units_per_eur, 2)                     as net_value_eur,
    po.contract_id,
    c.contract_id is not null
        and po.po_date between c.start_date and c.end_date        as is_under_contract,
    not (c.contract_id is not null
        and po.po_date between c.start_date and c.end_date)       as is_maverick,
    coalesce(m.is_this_id_blocked, false)                         as is_blocked_supplier,
    coalesce(cc.valid_to < po.po_date, false)                     as is_closed_cost_center,
    po.is_deleted,
    po.project_code,
    po.dq_status,
    po.source_file,
    po.loaded_at
from po
left join {{ ref('int_supplier_sap_to_golden') }} m  on m.sap_supplier_id = po.sap_supplier_id
left join {{ ref('int_category_mapping') }} cat      on cat.material_group = po.material_group
left join {{ ref('stg_sap__cost_centers') }} cc      on cc.cost_center_id = po.cost_center_id
left join {{ ref('int_fx_monthly') }} fx
       on fx.from_currency = po.currency and fx.rate_month = date_trunc('month', po.po_date)
left join contracts c                                on c.contract_id = po.contract_id
