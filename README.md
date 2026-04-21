# SAP O2C Process Simulation

> A complete **Order-to-Cash (O2C)** process simulation built in three layers:
> ABAP backend logic · HTML/CSS/JS dashboard · JSON sample data

---

## 📁 Project Files

| File | Description |
|---|---|
| `O2C_SIMULATION.abap` | Full ABAP report program (T-Code: ZO2C_SIM) |
| `sap_o2c_dashboard.html` | Frontend dashboard (no backend required) |
| `o2c_data.json` | Sample O2C records in JSON format |
| `README.md` | This file |

---

## 🔄 What is Order-to-Cash (O2C)?

The O2C cycle is a core SAP business process that tracks the full journey from receiving a customer order to collecting payment.

```
Customer → Sales Order → Delivery → Invoice → Payment → Reconciliation
 XD01        VA01         VL01N      VF01       F-28       FBL5N
```

---

## 🗂️ Project Components

### 1. ABAP Program — `O2C_SIMULATION.abap`

A modular ABAP report that simulates the full O2C process using only internal tables — no real SAP database tables are used.

**Key features:**
- Custom `TYPES` structures for Customer, Sales Order, Invoice, Payment, and Report output
- Sample data populated with `APPEND VALUE #(...)`
- `FORM` subroutines for each logical step (load data, build report, apply filters, display)
- Selection screen with Customer ID filter, Status filter, and Delayed-only checkbox
- Payment status logic based on delay days
- Structured `WRITE` output with color-coded status

**Payment Status Rules:**

| Delay Days | Status |
|---|---|
| 0 – 5 days | ✅ On Time |
| 6 – 15 days | ⚠️ Late |
| > 15 days | 🔴 High Risk |

**Simulated SAP Tables:**

| Internal Table | Mirrors SAP Table | T-Code |
|---|---|---|
| `gt_customers` | KNA1 | XD01 / XD03 |
| `gt_orders` | VBAK | VA01 / VA03 |
| `gt_invoices` | VBRK | VF01 / VF03 |
| `gt_payments` | BSID | F-28 / FBL5N |

**How to run in SAP:**
1. Open **SE38** → enter program name `ZO2C_SIMULATION` → paste code → Activate (`Ctrl+F3`)
2. Register T-Code via **SE93** → assign to `ZO2C_SIMULATION`
3. Execute via `ZO2C_SIM` or press `F8` in SE38
4. Enter filter values on the selection screen → Execute

---

### 2. Frontend Dashboard — `sap_o2c_dashboard.html`

A self-contained HTML file that renders a business dashboard for the O2C report. No framework, no server, no build step — open directly in any browser.

**Features:**
- SAP-style top navigation bar with live clock
- O2C process flow diagram with T-Code labels
- 4 KPI summary cards (Total / On Time / Late / High Risk) with count-up animation
- Filter panel: Customer ID, Date From/To, Payment Status
- Sortable report table (click any column header)
- Color-coded status badges
- Staggered row fade-in animation on report generation
- Fully responsive layout

**How to run:**
```
1. Download sap_o2c_dashboard.html
2. Double-click to open in any browser (Chrome, Firefox, Edge)
3. No installation needed
```

---

### 3. Sample Data — `o2c_data.json`

Seven O2C records in JSON format covering all three payment status categories.

**Fields:**

| Field | Type | Description |
|---|---|---|
| `customer_id` | string | Unique customer identifier |
| `order_id` | string | Sales order number |
| `invoice_id` | string | Billing document number |
| `amount` | number | Invoice amount in INR |
| `invoice_date` | string | Date invoice was raised (YYYY-MM-DD) |
| `payment_date` | string | Date payment was received (YYYY-MM-DD) |
| `delay_days` | number | Days between invoice date and payment date |
| `status` | string | On Time / Late / High Risk |

**Sample record:**
```json
{
  "customer_id": "CUST001",
  "order_id":    "ORD0000001",
  "invoice_id":  "INV0000001",
  "amount":      150000,
  "invoice_date": "2024-01-05",
  "payment_date": "2024-01-08",
  "delay_days":  3,
  "status":      "On Time"
}
```

---

## 🧪 Sample Customers

| Customer ID | Company Name | City |
|---|---|---|
| CUST001 | Tata Consultancy Services | Mumbai |
| CUST002 | Infosys Limited | Bangalore |
| CUST003 | Wipro Technologies | Hyderabad |
| CUST004 | HCL Technologies | Noida |
| CUST005 | Tech Mahindra Ltd | Pune |

---

## 🧩 ABAP Concepts Used

| Concept | Usage |
|---|---|
| `TYPES` | Define all data structures |
| `STANDARD TABLE` | Hold multiple rows of data |
| `APPEND VALUE #(...)` | Populate sample records inline |
| `LOOP AT ... INTO` | Iterate over internal tables |
| `READ TABLE ... WITH KEY` | Look up related records (like a JOIN) |
| `CASE / WHEN` | Apply payment status business rules |
| `FORM / ENDFORM` | Modular subroutines |
| `PARAMETERS` | Selection screen input fields |
| `WRITE` | Structured report output |
| `ULINE` | Horizontal separator lines |
| `COLOR` | Row/field color coding |

---

## 📐 Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                  SELECTION SCREEN                   │
│         Customer ID · Status · Date Range           │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│               DATA LAYER (Internal Tables)          │
│  gt_customers → gt_orders → gt_invoices → gt_payments│
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│              BUSINESS LOGIC (FORM routines)         │
│  build_o2c_report: Link tables + calc delay/status  │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│               OUTPUT (WRITE statements)             │
│  Structured report with color-coded status          │
└─────────────────────────────────────────────────────┘
```

---

## 📌 Notes

- This project uses **no real SAP database tables** — all data is simulated in memory using internal tables.
- The HTML dashboard is completely standalone — no npm, no framework, no internet connection required after the Google Fonts load.
- The JSON file can be imported into any tool (Excel, Power BI, Postman, frontend apps) for further use.
- All amounts are in **INR (Indian Rupee)**.

---

## 📄 License

This project is provided for **educational and learning purposes**. Free to use, modify, and share.
