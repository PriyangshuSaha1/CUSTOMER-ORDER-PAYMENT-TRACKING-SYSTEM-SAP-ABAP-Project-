*&---------------------------------------------------------------------*
*& Program     : ZO2C_SIMULATION
*& Description : Order-to-Cash (O2C) Process Simulation
*&               Simulates: Customer → Sales Order → Invoice → Payment
*&               Uses only internal tables (no real DB tables)
*& Author      : ABAP Learning Example
*& Created     : 2024
*&---------------------------------------------------------------------*
*& T-CODE      : ZO2C_SIM  (assign via SE93 in real SAP system)
*&---------------------------------------------------------------------*

REPORT zo2c_simulation
  NO STANDARD PAGE HEADING
  LINE-SIZE 220
  LINE-COUNT 65.

*&---------------------------------------------------------------------*
*& SECTION 1: TYPE DEFINITIONS
*& Define all structures (like blueprints for our data)
*&---------------------------------------------------------------------*

"── Customer Master Structure ──────────────────────────────────────────
TYPES: BEGIN OF ty_customer,
         kunnr TYPE c LENGTH 10,      "Customer Number
         name1 TYPE c LENGTH 40,      "Customer Name
         city  TYPE c LENGTH 25,      "City
         land1 TYPE c LENGTH 3,       "Country Code
         waers TYPE c LENGTH 5,       "Currency Key
       END OF ty_customer.

"── Sales Order Header Structure ────────────────────────────────────────
TYPES: BEGIN OF ty_sales_order,
         vbeln TYPE c LENGTH 10,      "Sales Order Number
         kunnr TYPE c LENGTH 10,      "Customer Number (FK → Customer)
         erdat TYPE d,                "Order Creation Date
         netwr TYPE p DECIMALS 2,     "Net Order Value
         waers TYPE c LENGTH 5,       "Currency
         status TYPE c LENGTH 15,     "Order Status
       END OF ty_sales_order.

"── Invoice (Billing Document) Structure ───────────────────────────────
TYPES: BEGIN OF ty_invoice,
         vbeln_inv TYPE c LENGTH 10,  "Invoice Number
         vbeln_ord TYPE c LENGTH 10,  "Reference Sales Order (FK)
         kunnr     TYPE c LENGTH 10,  "Customer Number
         fkdat     TYPE d,            "Invoice (Billing) Date
         netwr     TYPE p DECIMALS 2, "Invoice Amount
         waers     TYPE c LENGTH 5,   "Currency
       END OF ty_invoice.

"── Payment Record Structure ────────────────────────────────────────────
TYPES: BEGIN OF ty_payment,
         pay_id    TYPE c LENGTH 10,  "Payment ID
         vbeln_inv TYPE c LENGTH 10,  "Reference Invoice (FK)
         kunnr     TYPE c LENGTH 10,  "Customer Number
         zfbdt     TYPE d,            "Payment Date
         dmbtr     TYPE p DECIMALS 2, "Payment Amount
         waers     TYPE c LENGTH 5,   "Currency
       END OF ty_payment.

"── O2C Report Output Structure ─────────────────────────────────────────
TYPES: BEGIN OF ty_o2c_report,
         kunnr        TYPE c LENGTH 10,  "Customer Number
         cust_name    TYPE c LENGTH 40,  "Customer Name
         city         TYPE c LENGTH 25,  "City
         vbeln_ord    TYPE c LENGTH 10,  "Sales Order Number
         order_date   TYPE d,            "Order Date
         vbeln_inv    TYPE c LENGTH 10,  "Invoice Number
         invoice_date TYPE d,            "Invoice Date
         invoice_amt  TYPE p DECIMALS 2, "Invoice Amount
         pay_id       TYPE c LENGTH 10,  "Payment ID
         pay_date     TYPE d,            "Payment Date
         pay_amount   TYPE p DECIMALS 2, "Payment Amount
         delay_days   TYPE i,            "Days Delay (Pay Date - Inv Date)
         pay_status   TYPE c LENGTH 15,  "On Time / Late / High Risk
         waers        TYPE c LENGTH 5,   "Currency
       END OF ty_o2c_report.


*&---------------------------------------------------------------------*
*& SECTION 2: INTERNAL TABLE & WORK AREA DECLARATIONS
*&---------------------------------------------------------------------*

"Internal tables (hold multiple rows of data)
DATA: gt_customers    TYPE STANDARD TABLE OF ty_customer,
      gt_orders       TYPE STANDARD TABLE OF ty_sales_order,
      gt_invoices     TYPE STANDARD TABLE OF ty_invoice,
      gt_payments     TYPE STANDARD TABLE OF ty_payment,
      gt_o2c_report   TYPE STANDARD TABLE OF ty_o2c_report.

"Work areas (hold a single row – used for processing)
DATA: gs_customer     TYPE ty_customer,
      gs_order        TYPE ty_sales_order,
      gs_invoice      TYPE ty_invoice,
      gs_payment      TYPE ty_payment,
      gs_report       TYPE ty_o2c_report.

"Helper variables
DATA: lv_delay_days   TYPE i,
      lv_pay_status   TYPE c LENGTH 15,
      lv_total_inv    TYPE p DECIMALS 2,
      lv_total_paid   TYPE p DECIMALS 2,
      lv_line_count   TYPE i.


*&---------------------------------------------------------------------*
*& SECTION 3: SELECTION SCREEN (Parameters for Filtering)
*& T-Code users see this screen first when executing ZO2C_SIM
*&---------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.

  "Filter by Customer Number (optional)
  PARAMETERS: p_kunnr TYPE c LENGTH 10 OBLIGATORY DEFAULT 'ALL'
              LOWER CASE.

  "Filter by Payment Status
  PARAMETERS: p_status TYPE c LENGTH 15 DEFAULT 'ALL'
              LOWER CASE.

  "Show only delayed payments?
  PARAMETERS: p_delay  TYPE c LENGTH 1 AS CHECKBOX DEFAULT ' '.

SELECTION-SCREEN END OF BLOCK b1.


*&---------------------------------------------------------------------*
*& SECTION 4: INITIALIZATION EVENT
*& Set screen titles and defaults
*&---------------------------------------------------------------------*

INITIALIZATION.
  TEXT-001 = 'O2C Simulation Filter Options'.


*&---------------------------------------------------------------------*
*& SECTION 5: START-OF-SELECTION (Main Program Logic)
*&---------------------------------------------------------------------*

START-OF-SELECTION.

  "Step 1: Load all simulated master and transactional data
  PERFORM load_customer_data.
  PERFORM load_sales_order_data.
  PERFORM load_invoice_data.
  PERFORM load_payment_data.

  "Step 2: Build the O2C report by linking all data
  PERFORM build_o2c_report.

  "Step 3: Apply filters from selection screen
  PERFORM apply_filters.

  "Step 4: Display the final report
  PERFORM display_report.


*&---------------------------------------------------------------------*
*& SECTION 6: FORM ROUTINES (Modular Subroutines)
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& FORM: LOAD_CUSTOMER_DATA
*& Simulates Customer Master (like SAP table KNA1)
*&---------------------------------------------------------------------*
FORM load_customer_data.

  "Clear table before loading
  CLEAR gt_customers.

  "Append sample customer records using APPEND VALUE syntax
  APPEND VALUE #(
    kunnr = 'CUST001'
    name1 = 'Tata Consultancy Services'
    city  = 'Mumbai'
    land1 = 'IN'
    waers = 'INR'
  ) TO gt_customers.

  APPEND VALUE #(
    kunnr = 'CUST002'
    name1 = 'Infosys Limited'
    city  = 'Bangalore'
    land1 = 'IN'
    waers = 'INR'
  ) TO gt_customers.

  APPEND VALUE #(
    kunnr = 'CUST003'
    name1 = 'Wipro Technologies'
    city  = 'Hyderabad'
    land1 = 'IN'
    waers = 'INR'
  ) TO gt_customers.

  APPEND VALUE #(
    kunnr = 'CUST004'
    name1 = 'HCL Technologies'
    city  = 'Noida'
    land1 = 'IN'
    waers = 'INR'
  ) TO gt_customers.

  APPEND VALUE #(
    kunnr = 'CUST005'
    name1 = 'Tech Mahindra Ltd'
    city  = 'Pune'
    land1 = 'IN'
    waers = 'INR'
  ) TO gt_customers.

ENDFORM.


*&---------------------------------------------------------------------*
*& FORM: LOAD_SALES_ORDER_DATA
*& Simulates Sales Orders (like SAP table VBAK – T-Code VA01/VA03)
*&---------------------------------------------------------------------*
FORM load_sales_order_data.

  CLEAR gt_orders.

  "CUST001 - Two orders
  APPEND VALUE #(
    vbeln  = 'ORD0000001'
    kunnr  = 'CUST001'
    erdat  = '20240101'
    netwr  = '150000.00'
    waers  = 'INR'
    status = 'COMPLETED'
  ) TO gt_orders.

  APPEND VALUE #(
    vbeln  = 'ORD0000002'
    kunnr  = 'CUST001'
    erdat  = '20240210'
    netwr  = '95000.00'
    waers  = 'INR'
    status = 'COMPLETED'
  ) TO gt_orders.

  "CUST002 - One order
  APPEND VALUE #(
    vbeln  = 'ORD0000003'
    kunnr  = 'CUST002'
    erdat  = '20240115'
    netwr  = '220000.00'
    waers  = 'INR'
    status = 'COMPLETED'
  ) TO gt_orders.

  "CUST003 - One order
  APPEND VALUE #(
    vbeln  = 'ORD0000004'
    kunnr  = 'CUST003'
    erdat  = '20240120'
    netwr  = '75000.00'
    waers  = 'INR'
    status = 'COMPLETED'
  ) TO gt_orders.

  "CUST004 - Two orders
  APPEND VALUE #(
    vbeln  = 'ORD0000005'
    kunnr  = 'CUST004'
    erdat  = '20240201'
    netwr  = '310000.00'
    waers  = 'INR'
    status = 'COMPLETED'
  ) TO gt_orders.

  APPEND VALUE #(
    vbeln  = 'ORD0000006'
    kunnr  = 'CUST004'
    erdat  = '20240215'
    netwr  = '180000.00'
    waers  = 'INR'
    status = 'COMPLETED'
  ) TO gt_orders.

  "CUST005 - One order
  APPEND VALUE #(
    vbeln  = 'ORD0000007'
    kunnr  = 'CUST005'
    erdat  = '20240205'
    netwr  = '430000.00'
    waers  = 'INR'
    status = 'COMPLETED'
  ) TO gt_orders.

ENDFORM.


*&---------------------------------------------------------------------*
*& FORM: LOAD_INVOICE_DATA
*& Simulates Invoices/Billing Docs (like SAP table VBRK – T-Code VF01/VF03)
*&---------------------------------------------------------------------*
FORM load_invoice_data.

  CLEAR gt_invoices.

  "Invoice for ORD0000001
  APPEND VALUE #(
    vbeln_inv = 'INV0000001'
    vbeln_ord = 'ORD0000001'
    kunnr     = 'CUST001'
    fkdat     = '20240105'
    netwr     = '150000.00'
    waers     = 'INR'
  ) TO gt_invoices.

  "Invoice for ORD0000002
  APPEND VALUE #(
    vbeln_inv = 'INV0000002'
    vbeln_ord = 'ORD0000002'
    kunnr     = 'CUST001'
    fkdat     = '20240214'
    netwr     = '95000.00'
    waers     = 'INR'
  ) TO gt_invoices.

  "Invoice for ORD0000003
  APPEND VALUE #(
    vbeln_inv = 'INV0000003'
    vbeln_ord = 'ORD0000003'
    kunnr     = 'CUST002'
    fkdat     = '20240118'
    netwr     = '220000.00'
    waers     = 'INR'
  ) TO gt_invoices.

  "Invoice for ORD0000004
  APPEND VALUE #(
    vbeln_inv = 'INV0000004'
    vbeln_ord = 'ORD0000004'
    kunnr     = 'CUST003'
    fkdat     = '20240124'
    netwr     = '75000.00'
    waers     = 'INR'
  ) TO gt_invoices.

  "Invoice for ORD0000005
  APPEND VALUE #(
    vbeln_inv = 'INV0000005'
    vbeln_ord = 'ORD0000005'
    kunnr     = 'CUST004'
    fkdat     = '20240205'
    netwr     = '310000.00'
    waers     = 'INR'
  ) TO gt_invoices.

  "Invoice for ORD0000006
  APPEND VALUE #(
    vbeln_inv = 'INV0000006'
    vbeln_ord = 'ORD0000006'
    kunnr     = 'CUST004'
    fkdat     = '20240218'
    netwr     = '180000.00'
    waers     = 'INR'
  ) TO gt_invoices.

  "Invoice for ORD0000007
  APPEND VALUE #(
    vbeln_inv = 'INV0000007'
    vbeln_ord = 'ORD0000007'
    kunnr     = 'CUST005'
    fkdat     = '20240210'
    netwr     = '430000.00'
    waers     = 'INR'
  ) TO gt_invoices.

ENDFORM.


*&---------------------------------------------------------------------*
*& FORM: LOAD_PAYMENT_DATA
*& Simulates Incoming Payments (like SAP table BSID – T-Code F-28/FBL5N)
*& Payment delay varies to test all 3 status categories
*&---------------------------------------------------------------------*
FORM load_payment_data.

  CLEAR gt_payments.

  "Payment for INV0000001 → Invoice date: 05-Jan → Paid: 08-Jan = 3 days → ON TIME
  APPEND VALUE #(
    pay_id    = 'PAY0000001'
    vbeln_inv = 'INV0000001'
    kunnr     = 'CUST001'
    zfbdt     = '20240108'
    dmbtr     = '150000.00'
    waers     = 'INR'
  ) TO gt_payments.

  "Payment for INV0000002 → Invoice date: 14-Feb → Paid: 25-Feb = 11 days → LATE
  APPEND VALUE #(
    pay_id    = 'PAY0000002'
    vbeln_inv = 'INV0000002'
    kunnr     = 'CUST001'
    zfbdt     = '20240225'
    dmbtr     = '95000.00'
    waers     = 'INR'
  ) TO gt_payments.

  "Payment for INV0000003 → Invoice date: 18-Jan → Paid: 22-Jan = 4 days → ON TIME
  APPEND VALUE #(
    pay_id    = 'PAY0000003'
    vbeln_inv = 'INV0000003'
    kunnr     = 'CUST002'
    zfbdt     = '20240122'
    dmbtr     = '220000.00'
    waers     = 'INR'
  ) TO gt_payments.

  "Payment for INV0000004 → Invoice date: 24-Jan → Paid: 12-Feb = 19 days → HIGH RISK
  APPEND VALUE #(
    pay_id    = 'PAY0000004'
    vbeln_inv = 'INV0000004'
    kunnr     = 'CUST003'
    zfbdt     = '20240212'
    dmbtr     = '75000.00'
    waers     = 'INR'
  ) TO gt_payments.

  "Payment for INV0000005 → Invoice date: 05-Feb → Paid: 07-Feb = 2 days → ON TIME
  APPEND VALUE #(
    pay_id    = 'PAY0000005'
    vbeln_inv = 'INV0000005'
    kunnr     = 'CUST004'
    zfbdt     = '20240207'
    dmbtr     = '310000.00'
    waers     = 'INR'
  ) TO gt_payments.

  "Payment for INV0000006 → Invoice date: 18-Feb → Paid: 03-Mar = 14 days → LATE
  APPEND VALUE #(
    pay_id    = 'PAY0000006'
    vbeln_inv = 'INV0000006'
    kunnr     = 'CUST004'
    zfbdt     = '20240303'
    dmbtr     = '180000.00'
    waers     = 'INR'
  ) TO gt_payments.

  "Payment for INV0000007 → Invoice date: 10-Feb → Paid: 15-Mar = 34 days → HIGH RISK
  APPEND VALUE #(
    pay_id    = 'PAY0000007'
    vbeln_inv = 'INV0000007'
    kunnr     = 'CUST005'
    zfbdt     = '20240315'
    dmbtr     = '430000.00'
    waers     = 'INR'
  ) TO gt_payments.

ENDFORM.


*&---------------------------------------------------------------------*
*& FORM: BUILD_O2C_REPORT
*& Links Orders → Invoices → Payments and calculates delay + status
*& This is the core business logic of the O2C simulation
*&---------------------------------------------------------------------*
FORM build_o2c_report.

  CLEAR gt_o2c_report.

  "─── OUTER LOOP: Iterate over each Sales Order ─────────────────────
  LOOP AT gt_orders INTO gs_order.

    "─── Step A: Find Customer details for this order ─────────────────
    READ TABLE gt_customers INTO gs_customer
      WITH KEY kunnr = gs_order-kunnr.

    IF sy-subrc <> 0.
      "Customer not found – skip this order (data integrity check)
      CONTINUE.
    ENDIF.

    "─── Step B: Find Invoice linked to this Sales Order ──────────────
    READ TABLE gt_invoices INTO gs_invoice
      WITH KEY vbeln_ord = gs_order-vbeln.

    IF sy-subrc <> 0.
      "No invoice found for this order – skip
      CONTINUE.
    ENDIF.

    "─── Step C: Find Payment linked to this Invoice ──────────────────
    READ TABLE gt_payments INTO gs_payment
      WITH KEY vbeln_inv = gs_invoice-vbeln_inv.

    IF sy-subrc <> 0.
      "No payment found – still include with empty payment info
      CLEAR gs_payment.
    ENDIF.

    "─── Step D: Calculate Payment Delay (in days) ────────────────────
    "Formula: Payment Date minus Invoice Date = Delay Days
    IF gs_payment-zfbdt IS NOT INITIAL AND gs_invoice-fkdat IS NOT INITIAL.
      lv_delay_days = gs_payment-zfbdt - gs_invoice-fkdat.
    ELSE.
      lv_delay_days = 0.
    ENDIF.

    "─── Step E: Assign Payment Status based on delay ─────────────────
    "Business Rules:
    "  0–5 days   → On Time
    "  6–15 days  → Late
    "  >15 days   → High Risk
    CASE lv_delay_days.
      WHEN 0 OR 1 OR 2 OR 3 OR 4 OR 5.
        lv_pay_status = 'On Time'.
      WHEN 6 OR 7 OR 8 OR 9 OR 10 OR 11 OR 12 OR 13 OR 14 OR 15.
        lv_pay_status = 'Late'.
      WHEN OTHERS.
        IF lv_delay_days > 15.
          lv_pay_status = 'High Risk'.
        ELSE.
          lv_pay_status = 'Unknown'.
        ENDIF.
    ENDCASE.

    "─── Step F: Build report output line ─────────────────────────────
    CLEAR gs_report.
    gs_report-kunnr        = gs_order-kunnr.
    gs_report-cust_name    = gs_customer-name1.
    gs_report-city         = gs_customer-city.
    gs_report-vbeln_ord    = gs_order-vbeln.
    gs_report-order_date   = gs_order-erdat.
    gs_report-vbeln_inv    = gs_invoice-vbeln_inv.
    gs_report-invoice_date = gs_invoice-fkdat.
    gs_report-invoice_amt  = gs_invoice-netwr.
    gs_report-pay_id       = gs_payment-pay_id.
    gs_report-pay_date     = gs_payment-zfbdt.
    gs_report-pay_amount   = gs_payment-dmbtr.
    gs_report-delay_days   = lv_delay_days.
    gs_report-pay_status   = lv_pay_status.
    gs_report-waers        = gs_customer-waers.

    "Add completed row to the report table
    APPEND gs_report TO gt_o2c_report.

  ENDLOOP. "End of Sales Order Loop

ENDFORM.


*&---------------------------------------------------------------------*
*& FORM: APPLY_FILTERS
*& Filters the report table based on user's selection screen input
*&---------------------------------------------------------------------*
FORM apply_filters.

  DATA: lt_temp_report TYPE STANDARD TABLE OF ty_o2c_report.

  CLEAR lt_temp_report.

  LOOP AT gt_o2c_report INTO gs_report.

    "── Filter 1: Customer Number (skip if ALL entered) ────────────────
    IF p_kunnr <> 'ALL' AND p_kunnr <> space.
      IF gs_report-kunnr <> p_kunnr.
        CONTINUE. "Skip this row
      ENDIF.
    ENDIF.

    "── Filter 2: Payment Status ───────────────────────────────────────
    IF p_status <> 'ALL' AND p_status <> space.
      "Convert input to proper case for comparison
      DATA: lv_filter_status TYPE c LENGTH 15.
      lv_filter_status = p_status.
      TRANSLATE lv_filter_status TO UPPER CASE.

      IF gs_report-pay_status <> lv_filter_status.
        CONTINUE.
      ENDIF.
    ENDIF.

    "── Filter 3: Show only delayed payments ──────────────────────────
    IF p_delay = 'X'.
      IF gs_report-delay_days <= 5.
        CONTINUE. "Skip on-time payments
      ENDIF.
    ENDIF.

    "Row passes all filters – keep it
    APPEND gs_report TO lt_temp_report.

  ENDLOOP.

  "Replace report table with filtered version
  gt_o2c_report = lt_temp_report.

ENDFORM.


*&---------------------------------------------------------------------*
*& FORM: DISPLAY_REPORT
*& Displays the O2C report using WRITE statements
*& Simulates what ALV or SE38 output would look like
*&---------------------------------------------------------------------*
FORM display_report.

  "═══════════════════════════════════════════════════════════════════════
  "  REPORT HEADER
  "═══════════════════════════════════════════════════════════════════════
  WRITE: / ''.
  WRITE: /1 '╔══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗'.
  WRITE: /1 '║           SAP O2C (Order-to-Cash) Process Simulation Report                                                                    ║'.
  WRITE: /1 '║           T-Code: ZO2C_SIM  |  Program: ZO2C_SIMULATION  |  Simulated Data Only – No Real SAP DB Tables Used                  ║'.
  WRITE: /1 '╚══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝'.

  "Display filter info
  WRITE: /1 'Applied Filters → Customer:', p_kunnr,
            '  Status:', p_status,
            '  Delayed Only:', p_delay.

  "Check if any data to display
  IF gt_o2c_report IS INITIAL.
    WRITE: / ''.
    WRITE: /1 '*** No records found for the selected filter criteria. ***'.
    RETURN.
  ENDIF.

  WRITE: / ''.

  "═══════════════════════════════════════════════════════════════════════
  "  COLUMN HEADERS
  "═══════════════════════════════════════════════════════════════════════
  WRITE: /1   SY-VLINE,
          2   'CustNo'    COLOR 1,
          13  SY-VLINE,
          14  'Customer Name'    COLOR 1,
          40  SY-VLINE,
          41  'City'      COLOR 1,
          54  SY-VLINE,
          55  'Order No'  COLOR 1,
          66  SY-VLINE,
          67  'Ord Date'  COLOR 1,
          77  SY-VLINE,
          78  'Invoice No' COLOR 1,
          89  SY-VLINE,
          90  'Inv Date'  COLOR 1,
          100 SY-VLINE,
          101 'Inv Amount' COLOR 1,
          115 SY-VLINE,
          116 'Payment ID' COLOR 1,
          127 SY-VLINE,
          128 'Pay Date'  COLOR 1,
          138 SY-VLINE,
          139 'Pay Amount' COLOR 1,
          153 SY-VLINE,
          154 'Days'      COLOR 1,
          159 SY-VLINE,
          160 'Status'    COLOR 1,
          175 SY-VLINE.

  "Separator line under headers
  ULINE /1(175).

  "Reset totals
  lv_total_inv  = 0.
  lv_total_paid = 0.
  lv_line_count = 0.

  "═══════════════════════════════════════════════════════════════════════
  "  DATA ROWS
  "═══════════════════════════════════════════════════════════════════════
  LOOP AT gt_o2c_report INTO gs_report.

    "Determine row color based on payment status
    DATA: lv_color TYPE i.
    CASE gs_report-pay_status.
      WHEN 'On Time'.
        lv_color = 5.   "Green-ish
      WHEN 'Late'.
        lv_color = 6.   "Yellow
      WHEN 'High Risk'.
        lv_color = 7.   "Red-ish
      WHEN OTHERS.
        lv_color = 0.   "No color
    ENDCASE.

    "Write data row
    WRITE: /1   SY-VLINE,
            2   gs_report-kunnr,
            13  SY-VLINE,
            14  gs_report-cust_name(26),
            40  SY-VLINE,
            41  gs_report-city(13),
            54  SY-VLINE,
            55  gs_report-vbeln_ord,
            66  SY-VLINE,
            67  gs_report-order_date,
            77  SY-VLINE,
            78  gs_report-vbeln_inv,
            89  SY-VLINE,
            90  gs_report-invoice_date,
            100 SY-VLINE,
            101 gs_report-invoice_amt CURRENCY gs_report-waers,
            115 SY-VLINE,
            116 gs_report-pay_id,
            127 SY-VLINE,
            128 gs_report-pay_date,
            138 SY-VLINE,
            139 gs_report-pay_amount CURRENCY gs_report-waers,
            153 SY-VLINE,
            154 gs_report-delay_days,
            159 SY-VLINE,
            160 gs_report-pay_status COLOR lv_color,
            175 SY-VLINE.

    "Accumulate totals
    lv_total_inv  = lv_total_inv  + gs_report-invoice_amt.
    lv_total_paid = lv_total_paid + gs_report-pay_amount.
    lv_line_count = lv_line_count + 1.

  ENDLOOP.

  "═══════════════════════════════════════════════════════════════════════
  "  SUMMARY TOTALS SECTION
  "═══════════════════════════════════════════════════════════════════════
  ULINE /1(175).

  WRITE: /1 '  TOTALS:',
            101 lv_total_inv,
            139 lv_total_paid.

  WRITE: / ''.
  WRITE: /1 '  Total Records Displayed:', lv_line_count.

  "═══════════════════════════════════════════════════════════════════════
  "  STATUS LEGEND
  "═══════════════════════════════════════════════════════════════════════
  WRITE: / ''.
  ULINE /1(80).
  WRITE: /1 '  PAYMENT STATUS LEGEND:'.
  WRITE: /1 '  ■  On Time   = Payment received within 0-5 days of Invoice Date'.
  WRITE: /1 '  ■  Late      = Payment received within 6-15 days of Invoice Date'.
  WRITE: /1 '  ■  High Risk = Payment received after more than 15 days (collection risk)'.
  ULINE /1(80).

  "═══════════════════════════════════════════════════════════════════════
  "  O2C FLOW REFERENCE
  "═══════════════════════════════════════════════════════════════════════
  WRITE: / ''.
  WRITE: /1 '  O2C PROCESS FLOW SIMULATED:'.
  WRITE: /1 '  [Customer] → VA01 (Sales Order) → VF01 (Invoice) → F-28 (Payment) → FBL5N (Reconcile)'.
  WRITE: / ''.

ENDFORM.

*& END OF PROGRAM: ZO2C_SIMULATION
*&---------------------------------------------------------------------*
