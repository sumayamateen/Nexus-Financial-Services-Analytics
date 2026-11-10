# Fraud Transaction & Churn Monitoring Analytics — Nexus Bank Case Study

SQL-driven investigation into fraud, churn, and transaction anomalies at a mid-market commercial bank — using window functions, CTEs, and multi-table joins across 25,000+ customers and 8M+ monthly transactions to trace a coordinated fraud spike back to its root cause.

## Why this project

Built to demonstrate the core of a data analytics & assurance role: writing optimized SQL against large transactional datasets, detecting fraud patterns and anomalies, profiling customer behavior, and turning raw findings into decisions leadership can act on.

## Repo structure

```
├── README.md
├── sql/
│   ├── 1- Onboarding Audit.sql        # baseline: customers, accounts, branches, bankers
│   ├── 2- Churn Analysis.sql          # churn trends by month, industry, risk tier, banker
│   ├── 3- Fraud Analysis.sql          # fraud volume, loss $, case types, flag rates, fraud-churn overlap
│   └── 4- Branch Profitability.sql    # branch scorecards, deposits, loans, channel mix, restructuring candidates
│   └── Executive Summary              # full write-up: problem → approach → findings → recommendations
```

---

## Business Problem

Nexus Financial Services (a simulated mid-market commercial bank, ~$4.2B AUM, ~320,000 business customers, 8M+ transactions/month) had three symptoms land on the board pack at once:

- Customer churn spiked in H2 2024
- Fee income declined despite flat transaction volumes
- Loan approval-to-disbursement times nearly doubled

The brief: find out what's actually driving it — using data, not assumptions.

## Approach

1. **Baseline the business** — customer/account counts, industry mix, branch footprint, onboarding trends (`01`)
2. **Isolate the churn signal** — month-over-month trend, segment by industry/risk tier/banker/tenure to find where attrition concentrates (`02`)
3. **Investigate fraud independently** — case volume, dollar loss, case-type mix, and wire-transaction flag rates over the same time window, then directly test whether fraud victims are more likely to churn (`03`)
4. **Roll up to branch level** — combine deposits, loans, transactions, and fraud loss into a composite scorecard, then apply a compound distress filter to flag restructuring candidates (`04`)
5. **Connect the dots** — cross-reference timing and segment overlap across all four analyses, reporting where the evidence confirms the hypothesis and where it doesn't

**Key SQL techniques used:** window functions (`SUM() OVER`, `RANK()`, `NTILE()`, `PERCENTILE_CONT`) for running totals, rankings, and quartile bucketing; `FILTER (WHERE ...)` for conditional aggregation without repeated subqueries; multi-CTE pipelines to build composite scorecards from five joined sources; cohort comparison via `CASE`-derived churn flags joined against fraud history; YoY/MoM comparisons via date-bounded conditional aggregates; multi-table joins across customers, accounts, transactions, loans, fraud cases, branches, and bankers.

## Findings

Full write-up: [`Executive_Summary.md`](Executive%20Summary.md)

- **A single inflection point.** Churn, fraud case volume, fraud dollar losses, and wire-fraud flag rates all step-change starting **July 2024**, not gradually — four independent metrics moving together in the same month, consistent with one triggering event rather than four unrelated trends.
- **Fraud and churn concentrate in the same three industries at the aggregate level** (Construction, Accommodation & Food, Retail Trade) — both sit far above every other industry on fraud rate (17–20%) and churn rate (14%+).
- **But the direct customer-level join tells a different story.** Among customers onboarded in 2024, the fraud cohort churned at just 0.7% vs. 8.6% for the non-fraud cohort — the opposite of what the industry-level pattern implies. Most likely explained by recency (both events are recent, and churn typically takes 1-2 years to materialize) and a small fraud-cohort sample size (293 customers, 2 churned). Reported as-is rather than forced to fit the industry-level story.
- **Churn is a people problem, not a regional one.** Regional churn is flat (9–10%) across all five regions, but individual relationship managers run as high as 3x the network average.
- **Bimodal customer tenure at churn**, with 40.5% leaving in the 1–2 year window and 26.5% leaving before 6 months.
- **No single branch meets a compound distress threshold.** A restructuring-candidate query (low customers + low lending + high fraud loss + low retention, all at once) returned zero branches — branch-level fraud loss never exceeds ~$3,700 in the data, an order of magnitude below the $50,000 threshold used, so the underlying issues are diffuse across the network rather than concentrated in identifiable branches.

## Recommendations

1. Investigate what changed operationally in June/July 2024 — the single strongest lead in the data.
2. Re-run the fraud-churn cohort comparison on the full customer base and with a longer observation window, since the current result may be a recency artifact rather than a true negative relationship.
3. Tighten fraud controls and onboarding review for Construction, Retail Trade, and Accommodation & Food — still the highest-fraud, highest-churn segments in aggregate.
4. Coach or reassign the top-churn relationship managers — a contained, fixable issue independent of the fraud investigation.
5. Reconcile the two fraud-loss data sources before any dollar figure is used externally.
6. Recalibrate the branch restructuring thresholds to the actual scale of branch-level fraud loss, then re-run the compound filter.

## Next Steps

- Re-test the fraud-churn relationship on a mature cohort (customers onboarded 18+ months ago) to control for the recency effect
- Extend the analysis to loan approval-to-disbursement time, flagged by leadership but not yet in the dataset
- Recalibrate and re-run the branch restructuring query with data-driven thresholds (e.g., percentile-based rather than fixed dollar cutoffs)
- Formally reconcile and document the two fraud-loss table sources

## Tools

SQL (PostgreSQL syntax)
