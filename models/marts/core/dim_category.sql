/* dim_category: one row per category with its level-1 / level-2 parents and full path. */
{{ config(contract={'enforced': true}) }}

select
    category_id::varchar            as category_id,
    category_name::varchar          as category_name,
    depth::number(10, 0)            as category_level,
    l1_category_name::varchar       as l1_category_name,
    l2_category_name::varchar       as l2_category_name,
    category_path::varchar          as category_path,
    material_group::varchar         as material_group,
    is_active::boolean              as is_active
from {{ ref('int_category_hierarchy') }}
