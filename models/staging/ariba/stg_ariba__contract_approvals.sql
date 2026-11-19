/*
  stg_ariba__contract_approvals: one row per approval step.
  approver_manager_id lets us walk the org chart with a recursive CTE (see dim_employee).
*/
{{ config(post_hook="{{ mask_email('approver_email') }}") }}

select
    approval_id,
    contract_id,
    try_to_number(step)                      as approval_step,
    approver_id,
    approver_name,
    approver_email,
    nullif(approver_manager_id, '')          as approver_manager_id,
    approver_title,
    decision,
    try_to_timestamp_ntz(decided_at)         as decided_at,
    _loaded_at                               as loaded_at
from {{ source('raw', 'ARIBA_CONTRACT_APPROVALS') }}
where _file_row_number > 1
qualify row_number() over (partition by approval_id order by _loaded_at desc) = 1
