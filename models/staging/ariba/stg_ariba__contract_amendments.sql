/* stg_ariba__contract_amendments: one row per amendment. */
select
    c.contract_id,
    a.value:amendmentId::string                  as amendment_id,
    c.contract_id || '|' || a.value:amendmentId::string as amendment_key,
    try_to_date(a.value:effectiveDate::string)   as effective_date,
    a.value:valueChange::number(18, 2)           as value_change,
    a.value:reason::string                       as reason
from {{ ref('stg_ariba__contracts') }} c,
     lateral flatten(input => c.amendments_json) a
