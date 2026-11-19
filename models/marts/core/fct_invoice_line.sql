/*
  fct_invoice_line
  Grain: one row per invoice line.  INCREMENTAL (merge on invoice_item_key).

  Late-arriving data (wave 7: September invoices delivered in November) is picked up
  because we filter on LOAD time, not posting date. If we filtered on posting_date
  > max(posting_date), those late invoices would be missed forever.
*/
{{ config(
    materialized='incremental',
    unique_key='invoice_item_key',
    incremental_strategy='merge',
    on_schema_change='append_new_columns'
) }}

select
    invoice_item_key,
    invoice_number,
    fiscal_year,
    invoice_line_number,
    posting_date,
    posting_month,
    golden_supplier_id          as supplier_id,
    sap_supplier_id,
    po_item_key,
    has_po_line,
    is_po_line_deleted,
    category_id,
    cost_center_id,
    contract_id,
    is_under_contract,
    is_maverick,
    quantity,
    po_quantity,
    is_over_invoiced,
    amount,
    currency,
    amount_eur,
    is_fx_missing,
    invoiced_unit_price,
    po_unit_price,
    price_variance_eur,
    is_credit,
    reversed_invoice_number,
    source_file,
    loaded_at
from {{ ref('int_invoice_lines_enriched') }}

{% if is_incremental() %}
where loaded_at >= (
    select dateadd(day, -{{ var('lookback_days', 3) }}, coalesce(max(loaded_at), '1900-01-01'::timestamp_ltz))
    from {{ this }}
)
{% endif %}
