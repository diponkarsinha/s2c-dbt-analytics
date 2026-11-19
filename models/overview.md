{% docs __overview__ %}
# S2C analytics (dbt)

Source-to-Contract procurement analytics for a fictional *Sample pharmaceutical company*.

**Flow:** RAW (Bronze, loaded by s2c-snowflake-data-source) → **staging** (clean, typed,
de-duplicated) → **intermediate** (golden supplier, ID mapping, FX, category tree) →
**marts** (star schema) → **KPIs**.

* Rows the audit layer flagged as ERROR are excluded in staging and kept in quarantine models.
* The `on-run-start` hook checks `AUDIT.V_PIPELINE_GATE` and stops if data is incomplete.
* Business problems (blocked suppliers, maverick spend, overlapping contracts, savings maths)
  are dbt tests with severity **warn**: reported, never hidden.
{% enddocs %}
