/*
  stg_sap__fx_rates
  Grain: one row per currency per month.
  XML: <Cube time="2026-01"><Cube currency="USD" rate="1.08" rateType="M"/>...</Cube>
  GET(xml, '@attr') reads an attribute. TO_ARRAY makes FLATTEN safe even if a month
  has only one child element.
*/
with months as (
    select
        to_date(get(raw, '@time')::string || '-01')   as rate_month,
        raw:"$"                                         as children,
        _loaded_at
    from {{ source('raw', 'SAP_FX_RATES') }}
)

select
    m.rate_month,
    get(c.value, '@currency')::string        as from_currency,
    get(c.value, '@rate')::number(18, 6)     as units_per_eur,
    get(c.value, '@rateType')::string        as rate_type,
    m._loaded_at                              as loaded_at
from months m,
     lateral flatten(input => to_array(m.children)) c
qualify row_number() over (partition by m.rate_month, from_currency order by m._loaded_at desc) = 1
