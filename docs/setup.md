# Setup: from zip to a running dbt project

Prerequisite: **s2c-snowflake-data-source** is set up and its data is loaded (RAW has rows, the gate is PASS).

## 1. Unzip into your repo folder

```bash
cd ~/Downloads
unzip -o s2c-dbt-analytics.zip          # fills the existing s2c-dbt-analytics folder
cd s2c-dbt-analytics
source .venv/bin/activate                # the .venv you created earlier
dbt --version                            # Core 1.x + snowflake 1.x
```

## 2. Create the dbt service user (Snowsight, ACCOUNTADMIN)

1. Open `snowflake/dbt_user_setup.sql`, paste it into a new SQL file in Snowsight, Run All.
2. Add the public key (same key pair as before). In the terminal:
   ```bash
   echo "ALTER USER S2C_DBT_SVC SET RSA_PUBLIC_KEY = '$(grep -v 'PUBLIC KEY' ~/.ssh/snowflake/rsa_key.pub | tr -d '\n')';" | pbcopy
   ```
   Paste in Snowsight and run that one line.
3. Check: `DESC USER S2C_DBT_SVC;` → `RSA_PUBLIC_KEY_FP` starts with `SHA256:`.

## 3. Your dbt login (profiles.yml)

```bash
mkdir -p ~/.dbt
cp profiles.yml.example ~/.dbt/profiles.yml
dbt debug
```
Expected at the end: **All checks passed!**

If it fails:
| Message | Fix |
|---|---|
| `Could not find profile named 's2c'` | The file must be at `~/.dbt/profiles.yml` |
| `JWT token is invalid` | Public key not set on `S2C_DBT_SVC` (step 2) |
| `private key file not found` | Check `private_key_path` is the full path, no `~` |
| `Role 'S2C_TRANSFORMER' ... not granted` | Run `dbt_user_setup.sql` again |

## 4. Build

```bash
dbt build
```

`dbt build` runs everything in dependency order: the 2 seeds, the 48 models, the
2 snapshots (right after the staging views they read) and all tests. Takes about 1-2 minutes.

Useful smaller commands during development:

```bash
dbt build --select staging          # only the staging folder (+ its tests)
dbt build --select +fct_spend       # fct_spend and everything it depends on
dbt test  --select stg_sap__po_items
dbt test  --select test_type:unit   # the unit test
```

What "good" looks like for `dbt build`:
- `Pipeline gate: PASS` at the start
- every model `OK`
- tests: **PASS** or **WARN**, no **ERROR**
- the WARNs are the planted business problems, which is the point. Expect WARN on, for example:
  - `assert_no_po_to_blocked_supplier` (5 planted)
  - `assert_every_invoice_has_po` (5 planted orphans)
  - `assert_savings_math` (5 planted)
  - `assert_contract_dates_valid` (7 planted)
  - `assert_no_overlapping_contracts` (5 planted, possibly a few more created by chance)
- compare with `answer_key/planted_issues.csv` in repo 1 (`caught_by = dbt`)

## 5. Look at the results (Snowsight, role S2C_TRANSFORMER or S2C_ADMIN)

```sql
SELECT * FROM S2C_DEV.MARTS.KPI_SCORECARD;
SELECT * FROM S2C_DEV.MARTS.KPI_SPEND_MONTHLY ORDER BY MONTH_START DESC LIMIT 20;
SELECT * FROM S2C_DEV.MARTS.DIM_SUPPLIER WHERE HAS_DUPLICATES;
SELECT * FROM S2C_DEV.STAGING.QUARANTINE_SAP__PO_ITEMS;
```

## 6. Docs and lineage

```bash
dbt docs generate
dbt docs serve        # opens a browser: click the blue lineage button bottom-right
```

## 7. After dropping a wave in repo 1

```bash
dbt build             # snapshots catch supplier / contract changes (waves 8, 10);
                      # incremental facts read only the new loads
```

## 8. Push to GitHub

Create an empty repo `s2c-dbt-analytics` on GitHub, then:

```bash
git init -b main
git remote add origin https://github.com/diponkarsinha/s2c-dbt-analytics.git
git add .
git status            # profiles.yml, .venv, target/ must NOT be listed
git commit -m "feat: dbt project - staging, intermediate, snapshots, marts, KPIs, tests"
git push -u origin main
```

For the CI workflow (`.github/workflows/dbt_build.yml`) add secrets `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_DBT_USER` (`S2C_DBT_SVC`), `SNOWFLAKE_PRIVATE_KEY`. It runs `dbt build` on every pull request.
