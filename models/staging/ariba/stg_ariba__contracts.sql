/*
  stg_ariba__contracts
  Grain: one row per contract (latest version by lastStatusChangeAt).
  Soft-deleted contracts are kept and flagged (is_deleted).
  autoRenew arrives as true / "Y" / "N" / "true", normalised by to_boolean().
*/
{{ config(post_hook="{{ mask_email('owner_email') }}") }}

with flattened as (
    select f.value as c, x._file_name, x._loaded_at
    from {{ source('raw', 'ARIBA_CONTRACTS') }} x,
         lateral flatten(input => x.raw:contracts) f
),

typed as (
    select
        c:contractId::string                                   as contract_id,
        c:title::string                                        as contract_title,
        c:supplier:aribaId::string                             as ariba_supplier_id,
        c:supplier:name::string                                as supplier_name,
        upper(replace(c:supplier:vatNumber::string, ' ', ''))  as vat_number,
        c:categoryId::string                                   as category_id,
        nullif(c:eventId::string, '')                          as event_id,
        c:value:amount::number(18, 2)                          as contract_value,
        c:value:currency::string                               as contract_currency,
        try_to_date(c:term:startDate::string)                  as start_date,
        try_to_date(c:term:endDate::string)                    as end_date,
        try_to_date(c:term:signedDate::string)                 as signed_date,
        c:term:noticePeriodDays::number                        as notice_period_days,
        {{ to_boolean('c:term:autoRenew') }}                   as is_auto_renew,
        c:status::string                                       as contract_status,
        coalesce(c:isDeleted::boolean, false)                  as is_deleted,
        try_to_timestamp_ntz(c:lastStatusChangeAt::string)     as status_changed_at,
        c:owner:name::string                                   as owner_name,
        c:owner:email::string                                  as owner_email,
        c:lineItems                                            as line_items_json,
        c:amendments                                           as amendments_json,
        _file_name                                             as source_file,
        _loaded_at                                             as loaded_at
    from flattened
)

select *
from typed
where contract_id is not null
qualify row_number() over (partition by contract_id order by status_changed_at desc nulls last, loaded_at desc) = 1
