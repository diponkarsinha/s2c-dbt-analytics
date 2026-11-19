/*
  stg_ariba__sourcing_events
  Grain: one row per sourcing event (latest version). Bids stay as JSON here
  and are exploded in stg_ariba__bids.
*/
{{ config(post_hook="{{ mask_email('owner_email') }}") }}

with flattened as (
    select f.value as e, x._file_name, x._loaded_at
    from {{ source('raw', 'ARIBA_SOURCING_EVENTS') }} x,
         lateral flatten(input => x.raw:records) f
),

typed as (
    select
        e:eventId::string                                  as event_id,
        e:title::string                                    as event_title,
        e:eventType::string                                as event_type,
        e:status::string                                   as event_status,
        e:request:requestId::string                        as request_id,
        e:category:id::string                              as category_id,
        e:owner:name::string                               as owner_name,
        e:owner:email::string                              as owner_email,
        try_to_timestamp_ntz(e:createdDate::string)        as created_at,
        try_to_timestamp_ntz(e:openDate::string)           as opened_at,
        try_to_timestamp_ntz(e:closeDate::string)          as closed_at,
        try_to_timestamp_ntz(e:awardDate::string)          as awarded_at,
        e:baselineSpend:amount::number(18, 2)              as baseline_amount,
        e:baselineSpend:currency::string                   as baseline_currency,
        e:award:aribaSupplierId::string                    as awarded_ariba_supplier_id,
        e:award:awardedAmount::number(18, 2)               as awarded_amount,
        try_to_timestamp_ntz(e:updatedAt::string)          as updated_at,
        e:bids                                             as bids_json,
        _file_name                                         as source_file,
        _loaded_at                                         as loaded_at
    from flattened
)

select *
from typed
where event_id is not null
qualify row_number() over (partition by event_id order by updated_at desc nulls last, loaded_at desc) = 1
