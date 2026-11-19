/* dim_cost_center: one row per cost centre. */
select
    cost_center_id,
    cost_center_name,
    business_unit,
    company_code,
    valid_from,
    valid_to,
    is_closed
from {{ ref('stg_sap__cost_centers') }}
