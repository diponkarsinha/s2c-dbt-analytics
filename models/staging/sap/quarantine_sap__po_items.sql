/*
  quarantine_sap__po_items
  PO rows the audit layer flagged as ERROR (text in numbers, missing keys, bad dates).
  Kept as a table so someone can look at them, fix the source and re-send.
  Nothing is deleted: RAW still has them, this model just makes them easy to find.
*/
{{ config(materialized='table') }}

select
    r.ebeln || '-' || r.ebelp      as po_item_key,
    dq.dq_status,
    dq.rule_ids,
    r.*
from {{ source('raw', 'SAP_PO_ITEMS') }} r
join {{ source('audit', 'V_ROW_DQ_STATUS') }} dq
  on  dq.raw_table = 'SAP_PO_ITEMS'
  and dq.file_name = r._file_name
  and dq.file_row_number = r._file_row_number
where dq.dq_status = 'ERROR'
