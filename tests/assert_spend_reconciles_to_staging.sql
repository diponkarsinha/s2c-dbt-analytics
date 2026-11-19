-- Reconciliation: every invoice amount in staging must reach the spend fact.
-- Severity ERROR: a join that drops or duplicates rows would break every KPI.
with s as (select round(sum(amount), 2) as total, count(*) as n from {{ ref('stg_sap__invoices') }}),
     f as (select round(sum(amount), 2) as total, count(*) as n from {{ ref('fct_spend') }})
select s.total as staging_total, f.total as fact_total, s.n as staging_rows, f.n as fact_rows
from s cross join f
where s.total <> f.total or s.n <> f.n
