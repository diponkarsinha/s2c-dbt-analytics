/*
  stg_ariba__requests
  Grain: one row per sourcing request (latest version).
  Paginated API: each RAW row is one page {result:[...], meta:{...}}.
  FLATTEN(result) turns the array into rows. The API sends numbers as text.
*/
{{ config(post_hook="{{ mask_email('requested_by_email') }}") }}

with flattened as (
    select
        f.value        as r,
        p._file_name,
        p._loaded_at
    from {{ source('raw', 'ARIBA_SOURCING_REQUESTS') }} p,
         lateral flatten(input => p.raw:result) f
),

typed as (
    select
        r:request_id::string                                   as request_id,
        r:short_description::string                            as short_description,
        r:category_id::string                                  as category_id,
        r:business_unit::string                                as business_unit,
        try_to_number(r:estimated_value::string)               as estimated_value,
        r:currency::string                                     as currency,
        r:requested_by:name::string                            as requested_by_name,
        r:requested_by:email::string                           as requested_by_email,
        r:status::string                                       as request_status,
        try_to_timestamp_ntz(r:created_at::string)             as created_at,
        try_to_timestamp_ntz(r:updated_at::string)             as updated_at_raw,
        -- source clock problem: updated_at can be earlier than created_at (AUD-R09)
        greatest(try_to_timestamp_ntz(r:created_at::string),
                 try_to_timestamp_ntz(r:updated_at::string))   as updated_at,
        try_to_date(r:sla_due_date::string)                    as sla_due_date,
        nullif(r:linked_event_id::string, '')                  as event_id,
        _file_name                                             as source_file,
        _loaded_at                                             as loaded_at
    from flattened
)

select *
from typed
where request_id is not null
qualify row_number() over (partition by request_id order by updated_at desc, loaded_at desc) = 1
