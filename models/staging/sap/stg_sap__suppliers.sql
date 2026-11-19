/*
  stg_sap__suppliers
  Grain: one row per SAP supplier ID, as in the LATEST full reload.
  (History of changes is kept by the snapshot snap_sap_suppliers.)

  XML: each RAW row is one <IDOC>. XMLGET walks the tree, :"$" reads the text.
  Empty tags like <ORT01></ORT01> give NULL.
*/
with src as (
    select
        xmlget(raw, 'E1LFA1M')  as seg,
        _file_name,
        _loaded_at
    from {{ source('raw', 'SAP_SUPPLIERS') }}
),

extracted as (
    select
        xmlget(seg, 'LIFNR'):"$"::string                       as lifnr,
        xmlget(seg, 'NAME1'):"$"::string                       as name1,
        xmlget(seg, 'LAND1'):"$"::string                       as land1,
        xmlget(seg, 'ORT01'):"$"::string                       as ort01,
        xmlget(seg, 'STCEG'):"$"::string                       as stceg,
        xmlget(seg, 'KTOKK'):"$"::string                       as ktokk,
        xmlget(seg, 'SPERR'):"$"::string                       as sperr,
        xmlget(seg, 'ERDAT'):"$"::string                       as erdat,
        xmlget(seg, 'UPDAT'):"$"::string                       as updat,
        xmlget(xmlget(seg, 'E1LFBKM'), 'BANKS'):"$"::string    as banks,
        xmlget(xmlget(seg, 'E1LFBKM'), 'IBAN'):"$"::string     as iban,
        _file_name,
        _loaded_at
    from src
),

typed as (
    select
        lifnr                                   as sap_supplier_id,
        {{ clean_text('name1') }}               as supplier_name,
        land1                                   as country_code,
        nullif(trim(ort01), '')                 as city,
        upper(replace(stceg, ' ', ''))          as vat_number,
        ktokk                                   as account_group,
        coalesce(sperr = 'X', false)            as is_blocked,
        {{ sap_date('erdat') }}                 as created_on,
        {{ sap_date('updat') }}                 as changed_on,
        banks                                   as bank_country,
        iban,
        _file_name                              as source_file,
        _loaded_at                              as loaded_at
    from extracted
)

select *
from typed
where sap_supplier_id is not null
qualify row_number() over (partition by sap_supplier_id order by loaded_at desc, changed_on desc) = 1
