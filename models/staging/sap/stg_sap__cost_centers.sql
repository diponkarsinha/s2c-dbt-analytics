/* stg_sap__cost_centers: one row per cost centre (latest file). valid_to 9999-12-31 = open. */
select
    kostl                                   as cost_center_id,
    kokrs                                   as controlling_area,
    bukrs                                   as company_code,
    trim(cost_center_name)                  as cost_center_name,
    trim(business_unit)                     as business_unit,
    trim(responsible)                       as responsible_person,
    try_to_date(valid_from)                 as valid_from,
    try_to_date(valid_to)                   as valid_to,
    try_to_date(valid_to) < current_date()  as is_closed,
    try_to_timestamp_ntz(updated_at)        as updated_at,
    _file_name                              as source_file,
    _loaded_at                              as loaded_at
from {{ source('raw', 'SAP_COST_CENTERS') }}
where _file_row_number > 1
qualify row_number() over (partition by kostl order by _loaded_at desc) = 1
