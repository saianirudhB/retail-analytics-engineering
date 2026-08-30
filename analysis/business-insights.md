# Business insights — Olist marketplace, Sep 2016 – Oct 2018

Scope: 98,666 orders with line items · 112,650 items · 13.43M BRL recognised
product revenue · 2.23M BRL freight. All figures from
[`run_eda.py`](run_eda.py) against the dbt marts. Data is a fixed historical
extract; "recent"/"growth" statements are within that window.

---

## 1. The marketplace grew ~4× in five quarters, then the data cuts off

| Quarter | Orders | Product revenue (BRL) |
|---|---:|---:|
| 2017 Q1 | 5,163 | 720k |
| 2017 Q2 | 9,268 | 1.27M |
| 2017 Q3 | 12,505 | 1.67M |
| 2017 Q4 | 17,643 | 2.39M |
| 2018 Q1 | 21,102 | 2.76M |
| 2018 Q2 | 19,947 | 2.85M |
| 2018 Q3 | 12,726 | 1.73M *(partial — data ends ~Aug 2018)* |

Revenue per quarter roughly quadrupled from 2017 Q1 to 2018 Q2. 2018 Q3 is
incomplete and should not be read as a decline. **AOV is stable at ~137 BRL**
throughout — growth is new orders, not bigger baskets.

## 2. Revenue is highly concentrated — geographically and by seller

- **Southeast Brazil = 65% of revenue** (8.78M of 13.43M BRL), driven by São
  Paulo. North + Central-West combined are under 9%.
- **The top 100 sellers (3.2% of 3,095 sellers) generate 45% of revenue**; the
  top 500 generate 79%. The long tail of ~2,600 sellers accounts for 21%.

Implication: marketplace health depends on a small set of sellers and one
region. Seller retention and Southeast logistics capacity are the leverage
points.

## 3. Delivery is fast on average but volatile, and lateness destroys reviews

- Average delivery time **12.5 days**; deliveries arrive on average ~12 days
  **before** the (generously padded) promised date; **on-time rate 89.8%**.
- But on-time rate swings hard by month: **83.8% in Nov 2017** (Black Friday
  volume) and a sustained dip to **82% (Feb 2018) and 77% (Mar 2018)** — a real
  operational incident, not noise.
- **On-time orders average a 4.29 review score; late orders average 2.57.**
  Late delivery is the single strongest predictor of a bad review in the data.

## 4. Review scores are bimodal, and a few high-volume categories drag

- 58% of orders are 5-star, but **14% are 1- or 2-star** — a heavy negative tail.
- Among categories with >200 orders, the **weakest are `office_furniture`
  (3.49), `bed_bath_table` (3.90) and `furniture_decor` (3.91)**. `bed_bath_table`
  is the **3rd-largest category by revenue (1.04M BRL)** — its low score is a
  material risk, likely tied to freight/damage on bulky items.
- Best-reviewed high-volume categories: `cool_stuff` (4.15), `health_beauty`
  (4.14), `sports_leisure` (4.11).

## 5. Category revenue leaders

| Category | Product revenue (BRL) | Items | Avg review |
|---|---:|---:|---:|
| health_beauty | 1.25M | 9,670 | 4.14 |
| watches_gifts | 1.19M | 5,991 | 4.02 |
| bed_bath_table | 1.04M | 11,115 | 3.90 |
| sports_leisure | 0.98M | 8,641 | 4.11 |
| computers_accessories | 0.90M | 7,827 | 3.93 |

Top 10 categories ≈ 60% of revenue.

## 6. Freight is a meaningful cost line

Freight is **16.6% of product revenue** (~20 BRL per item). On low-price, heavy
categories (bed/bath, furniture, garden tools) freight is a much larger share of
the customer's total and plausibly linked to their weaker reviews — a freight-to-
price ratio by category is the recommended next analysis.

## 7. Repeat purchase is essentially non-existent

**Only 3.1% of shoppers ever place a second order.** Whether that is a data
artefact (the window is short, `customer_unique_id` matching is imperfect) or a
real retention problem, it means **acquisition, not loyalty, drove all growth**
in this period. A cohort-retention view is the priority follow-up.

## 8. Payment behaviour

- **Credit card 75% of orders**, boleto (bank slip) 20%, voucher 3%, debit 2%.
- Credit-card orders average **3.6 instalments** — instalment plans are a core
  part of how Brazilian customers buy; boleto/debit are effectively single-payment.

---

## Recommended actions (from the data)

1. **Protect the promised date during peak.** The Nov-2017 and Feb/Mar-2018 dips
   show capacity, not routing, is the constraint. Model courier hand-off lead
   time (`purchased_at` → `delivered_to_carrier_at`) to find where the slippage
   starts.
2. **Fix bulky-goods experience.** `bed_bath_table` / furniture: high revenue,
   low reviews, high freight share. Investigate packaging, carrier, and whether
   the freight quote is putting customers off.
3. **Instrument retention.** Stand up cohort retention and a repeat-rate KPI now;
   3% is either a measurement gap or the biggest growth opportunity in the book.
4. **De-risk seller concentration.** 45% of revenue on 100 sellers — track their
   fulfilment health as a first-class dashboard, not a drill-down.
