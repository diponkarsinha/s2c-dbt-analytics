/* int_category_mapping: SAP material group -> leaf category (incl. inactive ones still used). */
select
    material_group,
    category_id,
    category_name,
    l1_category_name,
    l2_category_name,
    category_path,
    is_active
from {{ ref('int_category_hierarchy') }}
where material_group is not null
