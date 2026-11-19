/* stg_ref__categories: one row per category (3-level tree). */
select
    category_id,
    trim(category_name)                     as category_name,
    nullif(parent_category_id, '')          as parent_category_id,
    try_to_number(category_level)           as category_level,
    nullif(unspsc_code, '')                 as unspsc_code,
    nullif(sap_material_group, '')          as material_group,
    {{ to_boolean('is_active') }}           as is_active,
    try_to_date(valid_from)                 as valid_from,
    try_to_date(valid_to)                   as valid_to,
    _loaded_at                              as loaded_at
from {{ source('raw', 'REF_CATEGORIES') }}
where _file_row_number > 1
qualify row_number() over (partition by category_id order by _loaded_at desc) = 1
