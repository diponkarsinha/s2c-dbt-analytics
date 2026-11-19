/* stg_ariba__contract_lines: agreed unit price per material group (one row per contract line). */
select
    c.contract_id,
    l.value:lineNo::number                      as line_number,
    c.contract_id || '-' || l.value:lineNo::string as contract_line_key,
    l.value:materialGroup::string               as material_group,
    l.value:description::string                 as line_description,
    l.value:unitPrice::number(18, 2)            as agreed_unit_price,
    l.value:uom::string                         as unit_of_measure
from {{ ref('stg_ariba__contracts') }} c,
     lateral flatten(input => c.line_items_json) l
