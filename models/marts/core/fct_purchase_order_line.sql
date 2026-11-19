/*
  fct_purchase_order_line
  Grain: one row per PO line.  Materialization: INCREMENTAL (merge on po_item_key).

  Incremental logic: each run only reads PO lines LOADED in the last N days
  (var lookback_days, default 3) before the newest row already in this table.
  Changed lines (wave 7) and corrections (wave 5) are re-sent files, so they
  have a new load time and are merged over the old version.
*/
{{ config(
    materialized='incremental',
    unique_key='po_item_key',
    incremental_strategy='merge',
    on_schema_change='append_new_columns'
) }}

select
    po_item_key,
    po_number,
    po_line_number,
    po_date,
    po_month,
    changed_on,
    golden_supplier_id          as supplier_id,
    sap_supplier_id,
    category_id,
    material_group,
    cost_center_id,
    company_code,
    contract_id,
    quantity,
    net_price,
    net_value,
    currency,
    net_value_eur,
    is_under_contract,
    is_maverick,
    is_blocked_supplier,
    is_closed_cost_center,
    is_category_active,
    is_deleted,
    project_code,
    dq_status,
    source_file,
    loaded_at
from {{ ref('int_po_items_enriched') }}

{% if is_incremental() %}
where loaded_at >= (
    select dateadd(day, -{{ var('lookback_days', 3) }}, coalesce(max(loaded_at), '1900-01-01'::timestamp_ltz))
    from {{ this }}
)
{% endif %}
