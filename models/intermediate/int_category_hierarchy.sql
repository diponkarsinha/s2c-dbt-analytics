/*
  int_category_hierarchy
  Grain: one row per category, with its full path from the top.
  A RECURSIVE CTE walks parent_category_id from level 1 down to level 3.
*/
with recursive tree as (
    -- anchor: top level (no parent)
    select
        category_id,
        category_name,
        parent_category_id,
        material_group,
        is_active,
        1::number(10, 0)                    as depth,
        category_name::varchar(1000)        as category_path,
        category_id                         as l1_category_id,
        category_name                       as l1_category_name,
        null::varchar                       as l2_category_id,
        null::varchar                       as l2_category_name
    from {{ ref('stg_ref__categories') }}
    where parent_category_id is null

    union all

    -- recursive step: children of the rows found so far
    select
        c.category_id,
        c.category_name,
        c.parent_category_id,
        c.material_group,
        c.is_active,
        t.depth + 1,
        t.category_path || ' > ' || c.category_name,
        t.l1_category_id,
        t.l1_category_name,
        iff(t.depth + 1 = 2, c.category_id,   t.l2_category_id),
        iff(t.depth + 1 = 2, c.category_name, t.l2_category_name)
    from {{ ref('stg_ref__categories') }} c
    join tree t on c.parent_category_id = t.category_id
)

select * from tree
