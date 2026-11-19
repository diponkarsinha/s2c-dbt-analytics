# KPI catalog

| ID | KPI | Business question | Formula | Grain | Model | Refresh | Target |
|---|---|---|---|---|---|---|---|
| KPI-01 | Spend under contract % | How much spend follows a contract? | `SUM(amount_eur WHERE is_under_contract) / SUM(amount_eur)` | Month × category × BU | `kpi_spend_monthly`, `kpi_scorecard` | Batch, daily | ≥ 80% |
| KPI-02 | Maverick spend | How much do we buy without a contract? | `SUM(amount_eur WHERE is_maverick)` | Month × category × BU | `kpi_spend_monthly` | Batch | ≤ 10% |
| KPI-03 | Total spend (EUR) | Where does the money go? | `SUM(amount_eur)` (invoices, credit memos negative) | Month × category × BU | `kpi_spend_monthly` | Batch | n/a |
| KPI-04 | Source-to-award cycle time | How fast do we source? | `AVG(award_date - request_created)` in days | Quarter × category | `kpi_sourcing_performance` | Batch | ≤ 60 days |
| KPI-05 | Requests breaching SLA | Which requests are late? | `COUNT(is_sla_breached) / COUNT(*)`, SLA = 45 days | Quarter × category | `kpi_sourcing_performance` | Batch | ≤ 15% |
| KPI-06 | Validated savings | Are reported savings real? | `SUM(recalculated WHERE validated) / SUM(reported)` | Quarter × category | `kpi_savings_validation` | Batch, weekly | ≥ 90% |
| KPI-07 | Savings reconciliation gap | Where do reported and proven savings differ? | `SUM(reported - (baseline - awarded))` | Quarter × category | `kpi_savings_validation` | Batch | 0 |
| KPI-08 | Contracts expiring in 90 days | Which renewals need action? | Active contracts with `end_date` in 0-90 days, with dependent spend | Contract | `kpi_contract_renewals` | Batch | n/a |
| KPI-09 | Spend with high-risk suppliers | Are we exposed? | `SUM(spend WHERE risk_band IN ('High','Not assessed') OR sanctions)` | Supplier | `kpi_supplier_risk_exposure` | **Stream** score + batch spend | ≤ 5% |
| KPI-10 | Single-source events % | How often is there no competition? | `COUNT(bidder_count = 1) / COUNT(events)` | Quarter × category | `kpi_sourcing_performance` | Batch | ≤ 15% |
| KPI-11 | Invoice price variance | Are we billed above the agreed price? | `SUM(amount - qty × PO price)` when positive | Month × supplier | `kpi_invoice_price_variance` | Batch | ≤ 1% |

## Why each KPI is batch or stream
- **KPI-09 uses the live score** from the speed layer (`STREAMING.RISK_CURRENT`): a supplier that becomes high-risk today must be visible today, before the next award or PO.
- Everything else is reviewed weekly or monthly, so a daily batch is enough and cheaper.
- Both paths share one supplier key (VAT) and one definition (`risk_band` macro), so the numbers agree; `assert_risk_alerts_reconcile` checks it.

## Definitions that matter
- **Spend** = invoice lines in EUR at the monthly average rate (SAP TCURR, type M). Credit memos and reversals are negative.
- **Under contract** = the PO line references a contract (`KONNR`) that is not deleted and whose term covers the PO date.
- **Maverick** = not under contract (includes invoices without a PO line).
- **Not assessed** suppliers count as risky: there is no evidence they are safe.
