/*
  stg_risk__assessments
  Grain: one row per supplier VAT per weekly file (generatedAt).
  Scores outside 1-9 are set to NULL (AUD-R11 logged them) so the supplier
  counts as "not assessed" instead of carrying a wrong number.
*/
with flattened as (
    select
        try_to_timestamp_ntz(x.raw:generatedAt::string) as generated_at,
        x.raw:provider::string                          as provider,
        s.value                                         as s,
        x._loaded_at
    from {{ source('raw', 'RISK_ESG') }} x,
         lateral flatten(input => x.raw:suppliers) s
),

typed as (
    select
        upper(replace(s:supplier:vatNumber::string, ' ', ''))  as vat_number,
        s:supplier:dunsNumber::string                          as duns_number,
        generated_at,
        provider,
        try_to_number(s:scores:financialRisk::string)          as financial_risk_raw,
        iff(try_to_number(s:scores:financialRisk::string) between 1 and 9,
            try_to_number(s:scores:financialRisk::string), null) as financial_risk_score,
        try_to_number(s:scores:paydex::string)                 as paydex_score,
        try_to_number(s:scores:failureScore::string)           as failure_score,
        try_to_number(s:esg:ecovadisScore::string)             as esg_score,
        s:esg:medal::string                                    as esg_medal,
        try_to_date(s:assessedAt::string)                      as assessed_on,
        try_to_date(s:nextReviewDue::string)                   as next_review_due,
        _loaded_at                                             as loaded_at
    from flattened
)

select
    *,
    {{ risk_band('financial_risk_score') }}  as risk_band,
    next_review_due < current_date()         as is_review_overdue
from typed
where vat_number is not null
qualify row_number() over (partition by vat_number, generated_at order by loaded_at desc) = 1
