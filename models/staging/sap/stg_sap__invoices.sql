/*
  stg_sap__invoices
  Grain: one row per invoice line (BELNR + GJAHR + BUZEI).
  Parquet arrives with real types, so we only read and rename.
  Credit memos and reversals are negative (SHKZG = 'H').
*/
with src as (
    select * from {{ source('raw', 'SAP_INVOICES') }}
),

typed as (
    select
        raw:"BELNR"::string                                         as invoice_number,
        raw:"GJAHR"::number                                         as fiscal_year,
        raw:"BUZEI"::number                                         as invoice_line_number,
        raw:"BELNR"::string || '-' || raw:"GJAHR"::string
            || '-' || raw:"BUZEI"::string                           as invoice_item_key,
        try_to_date(raw:"BLDAT"::string)                            as document_date,
        try_to_date(raw:"BUDAT"::string)                            as posting_date,
        try_to_date(raw:"CPUDT"::string)                            as entry_date,
        raw:"LIFNR"::string                                         as sap_supplier_id,
        raw:"EBELN"::string                                         as po_number,
        raw:"EBELP"::string                                         as po_line_number,
        raw:"EBELN"::string || '-' || raw:"EBELP"::string           as po_item_key,
        raw:"MENGE"::number(18, 3)                                  as quantity,
        raw:"WRBTR"::number(18, 2)                                  as amount,
        upper(raw:"WAERS"::string)                                  as currency,
        raw:"SHKZG"::string = 'H'                                   as is_credit,
        nullif(raw:"XBLNR"::string, '')                             as supplier_invoice_ref,
        nullif(raw:"STBLG"::string, '')                             as reversed_invoice_number,
        _file_name                                                  as source_file,
        _loaded_at                                                  as loaded_at
    from src
)

select *
from typed
qualify row_number() over (partition by invoice_item_key order by loaded_at desc, source_file desc) = 1
