/*
  int_fx_monthly
  Grain: one row per currency per month, EUR included (rate 1).
  amount_eur = amount / units_per_eur
*/
with months as (
    select distinct rate_month from {{ ref('stg_sap__fx_rates') }}
)

select rate_month, from_currency, units_per_eur
from {{ ref('stg_sap__fx_rates') }}
union all
select rate_month, 'EUR', 1
from months
