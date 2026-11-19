/*
  stg_sap__po_items
  Grain: one row per PO line (latest version).

  What happens here
    1. skip row 1 of every file (it is the header, kept in RAW on purpose)
    2. cast SAP text: decimal comma -> number, YYYYMMDD -> date, keep leading zeros
    3. drop rows the audit layer flagged as ERROR (they go to quarantine_sap__po_items)
    4. schema drift: files whose header added ZZ_PROJECT carry it in _EXTRA_1
    5. de-duplicate: re-sent files, corrections and changes -> keep the newest
       version per PO line (latest AEDAT, then latest load)
*/
with raw_rows as (
    select * from {{ source('raw', 'SAP_PO_ITEMS') }}
),

headers as (           -- header row of each file, to know which columns that file had
    select _file_name, _extra_1 as extra_1_header
    from raw_rows
    where _file_row_number = 1
),

dq as (
    select file_name, file_row_number, dq_status
    from {{ source('audit', 'V_ROW_DQ_STATUS') }}
    where raw_table = 'SAP_PO_ITEMS'
),

typed as (
    select
        r.ebeln                                        as po_number,
        r.ebelp                                        as po_line_number,
        r.ebeln || '-' || r.ebelp                      as po_item_key,
        r.bukrs                                        as company_code,
        r.lifnr                                        as sap_supplier_id,
        {{ sap_date('r.bedat') }}                      as po_date,
        trim(r.matkl)                                  as material_group,
        {{ clean_text('r.txz01') }}                    as item_text,
        {{ sap_number('r.menge', 3) }}                 as quantity,
        r.meins                                        as unit_of_measure,
        {{ sap_number('r.netpr') }}                    as net_price,
        coalesce(try_to_number(r.peinh), 1)            as price_unit,
        {{ sap_number('r.netwr') }}                    as net_value,
        upper(trim(r.waers))                           as currency,
        r.kostl                                        as cost_center_id,
        nullif(trim(r.konnr), '')                      as contract_id,
        coalesce(r.loekz = 'L', false)                 as is_deleted,
        {{ sap_date('r.aedat') }}                      as changed_on,
        iff(h.extra_1_header = 'ZZ_PROJECT', r._extra_1, null) as project_code,
        coalesce(dq.dq_status, 'OK')                   as dq_status,
        r._file_name                                   as source_file,
        r._file_row_number                             as source_row,
        r._loaded_at                                   as loaded_at
    from raw_rows r
    left join headers h on h._file_name = r._file_name
    left join dq on dq.file_name = r._file_name and dq.file_row_number = r._file_row_number
    where r._file_row_number > 1
)

select *
from typed
where dq_status <> 'ERROR'
qualify row_number() over (
    partition by po_item_key
    order by changed_on desc nulls last, loaded_at desc, source_file desc, source_row desc
) = 1
