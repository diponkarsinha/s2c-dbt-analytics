# Dimensional model (Gold layer)

Kimball star schema in `S2C_DEV.MARTS`. Facts hold events and amounts; dimensions describe them.

```mermaid
erDiagram
    DIM_SUPPLIER ||--o{ FCT_SPEND : supplier_id
    DIM_CATEGORY ||--o{ FCT_SPEND : category_id
    DIM_COST_CENTER ||--o{ FCT_SPEND : cost_center_id
    DIM_CONTRACT ||--o{ FCT_SPEND : contract_id
    DIM_DATE ||--o{ FCT_SPEND : posting_date

    DIM_SUPPLIER ||--o{ FCT_PURCHASE_ORDER_LINE : supplier_id
    DIM_CATEGORY ||--o{ FCT_PURCHASE_ORDER_LINE : category_id
    DIM_COST_CENTER ||--o{ FCT_PURCHASE_ORDER_LINE : cost_center_id
    FCT_PURCHASE_ORDER_LINE ||--o{ FCT_INVOICE_LINE : po_item_key
    FCT_INVOICE_LINE ||--|| FCT_SPEND : invoice_item_key

    DIM_CATEGORY ||--o{ FCT_SOURCING_EVENT : category_id
    DIM_SUPPLIER ||--o{ FCT_SOURCING_EVENT : awarded_supplier_id
    FCT_SOURCING_EVENT ||--o{ FCT_BID : event_id
    FCT_SOURCING_EVENT ||--o{ FCT_SAVINGS : event_id
    FCT_SOURCING_EVENT ||--o| FCT_REQUEST_PIPELINE : event_id
    DIM_SUPPLIER ||--o{ DIM_CONTRACT : supplier_id
    DIM_CONTRACT ||--o{ DIM_CONTRACT_HISTORY : contract_id

    FCT_SPEND {
        string invoice_item_key PK
        date posting_date FK
        string supplier_id FK
        string category_id FK
        string cost_center_id FK
        string contract_id FK
        number amount_eur
        boolean is_under_contract
        boolean is_maverick
        number price_variance_eur
    }
    FCT_PURCHASE_ORDER_LINE {
        string po_item_key PK
        date po_date
        string supplier_id FK
        number net_value_eur
        boolean is_blocked_supplier
        boolean is_closed_cost_center
    }
    FCT_INVOICE_LINE {
        string invoice_item_key PK
        string po_item_key FK
        number amount_eur
        boolean is_over_invoiced
    }
    FCT_SOURCING_EVENT {
        string event_id PK
        number bidder_count
        boolean is_single_source
        number calculated_savings_eur
    }
    FCT_BID {
        string bid_key PK
        string event_id FK
        number bid_amount
        number bid_rank_in_round
    }
    FCT_SAVINGS {
        string savings_id PK
        string event_id FK
        number reported_savings_eur
        number savings_gap_eur
    }
    FCT_REQUEST_PIPELINE {
        string request_id PK
        string event_id FK
        number cycle_time_days
        boolean is_sla_breached
    }
    DIM_SUPPLIER {
        string supplier_id PK
        string vat_number
        string risk_band
        boolean is_blocked
    }
    DIM_CATEGORY {
        string category_id PK
        string l1_category_name
        string category_path
    }
    DIM_COST_CENTER {
        string cost_center_id PK
        string business_unit
        boolean is_closed
    }
    DIM_CONTRACT {
        string contract_id PK
        string supplier_id FK
        date end_date
        date notice_deadline
    }
    DIM_CONTRACT_HISTORY {
        string contract_id FK
        timestamp valid_from
        timestamp valid_to
    }
    DIM_DATE {
        date date_day PK
        string year_month
    }
```

## Grain of every table

| Table | Grain | Type |
|---|---|---|
| `fct_spend` | One invoice line | Fact (main spend fact) |
| `fct_invoice_line` | One invoice line | Fact, incremental |
| `fct_purchase_order_line` | One PO line | Fact, incremental |
| `fct_sourcing_event` | One sourcing event | Fact (accumulating) |
| `fct_bid` | One bid per round | Fact |
| `fct_savings` | One savings line | Fact |
| `fct_request_pipeline` | One request | Fact (accumulating snapshot of the S2C chain) |
| `dim_supplier` | One real supplier (golden record by VAT) | Dimension, type 1 (current) |
| `dim_supplier_history` | One version of an SAP supplier | Dimension, type 2 (from snapshot) |
| `dim_contract` | One contract (current) | Dimension |
| `dim_contract_history` | One version of a contract | Dimension, type 2 (from snapshot) |
| `dim_category` | One category | Dimension (model contract enforced) |
| `dim_cost_center` | One cost centre | Dimension |
| `dim_employee` | One approver | Dimension (recursive org chart) |
| `dim_date` | One day | Dimension |

## Why spend = invoices, not POs
A PO is a promise to buy; an invoice is money actually owed. Finance reports invoices, so `fct_spend` is built on invoice lines. PO-level facts are kept for compliance checks (blocked suppliers, closed cost centres) that happen *before* money is spent.

## Why one golden supplier
SAP has the same company under several IDs (duplicates), and Ariba uses its own IDs. Joining facts on raw SAP IDs would split one supplier's spend into several rows. All facts carry the **golden** `supplier_id` (oldest SAP ID for the VAT number).
