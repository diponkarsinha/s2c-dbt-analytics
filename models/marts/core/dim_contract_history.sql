/* dim_contract_history: SCD2 view of contract status from the snapshot. */
select
    contract_id,
    contract_status,
    contract_value,
    start_date,
    end_date,
    is_deleted,
    dbt_valid_from                    as valid_from,
    dbt_valid_to                      as valid_to,
    dbt_valid_to is null              as is_current
from {{ ref('snap_contract_status') }}
