# Executive Summary: Fraud, Churn & Branch Performance at Nexus Bank

Churn, fraud losses, and fraud case volume all spike in the **same month — July 2024** — and concentrate in the **same three industries** at an aggregate level. But a direct customer-level test complicates the obvious story: 2024-onboarded customers with a fraud case actually churned *less* than those without one, likely a recency effect rather than a true protective relationship. The highest-priority action is still identifying what changed operationally in June/July 2024, but the fraud→churn causal link needs a longer observation window before it's treated as confirmed.

---

## Business Problem

Nexus Financial Services is a mid-market commercial bank serving small and medium-sized businesses, managing ~$4.2B in assets and ~320,000 business customers across lending, payments, treasury, and trade finance. Three symptoms landed on the board pack simultaneously:

- Customer churn spiked, particularly in the second half of 2024
- Fee income declined despite flat transaction volumes
- Loan approval-to-disbursement times nearly doubled

Leadership needed a data-driven investigation into what was actually happening beneath these numbers — not assumptions, but evidence.

## Approach

The investigation was run in four stages, each building on the last:

1. **Onboarding audit** — established a baseline: customer counts, industry mix, branch footprint, banker headcount, monthly onboarding volume, and account composition, to confirm whether the issue was systemic or concentrated.
2. **Churn analysis** — broke churn down by month, industry, risk tier, banker, and customer tenure to find where and when attrition was concentrated.
3. **Fraud analysis** — examined fraud case volume, dollar losses, case-type mix, and wire-transaction flag rates over the same period, then built a direct cohort comparison joining fraud history against churn status to test the fraud→churn hypothesis explicitly, rather than inferring it from industry-level overlap alone.
4. **Branch profitability** — rolled deposits, loan origination, transaction volume, and fraud loss into a composite scorecard per branch, then applied a compound distress filter (low customers + low lending + high fraud loss + low retention, simultaneously) to flag restructuring candidates.

Each stage used SQL window functions (`SUM() OVER`, `RANK()`, `NTILE()`, `PERCENTILE_CONT`), `FILTER (WHERE ...)` for conditional aggregation, multi-CTE pipelines, cohort-flagging via `CASE` expressions joined against related tables, and YoY/MoM date-bounded comparisons across joined customer, account, transaction, loan, fraud, and branch tables.

## Findings

**1. The business baseline is healthy.** 25,000 customers (22,649 active), 58,910 accounts, stable account status mix (~86% active, ~9% closed, ~5% dormant). Whatever's wrong is concentrated, not systemic.

**2. Churn is a second-half-2024 shock.** 2024 churn hit 1,848 customers vs. 503 in 2023 (+267%). Monthly churn held steady at 46-79/month through June, then jumped to 231-278/month from July onward.

**3. Fraud shows the same shock, more sharply.** Fraud cases jumped from ~30-52/month to 150-213/month starting July 2024; dollar losses jumped from ~$125K-500K/month to $1.1M-1.6M/month. Every fraud case type grew YoY (check fraud +182%, wire fraud +174%, suspected fraud +159%, identity theft +145%).

**4. The clearest anomaly signal: wire transaction flag rate.** Flat at 0.4-0.8% for 24 consecutive months (Jan 2023-Jun 2024), then jumps to 4.7-5.5% starting July 2024 and holds there — a stable two-year baseline followed by a persistent 10x step-change, a strong technical anomaly signature.

**5. Fraud and churn concentrate in the same three industries — at the aggregate level.** Construction, Accommodation & Food, and Retail Trade show fraud rates of 17-20% and churn rates of 13-14%+, both 2-8x higher than every other industry.

**6. But the direct customer-level test tells a different story.** Joining fraud case history against churn status for customers onboarded in 2024: the fraud cohort (293 customers) churned at 0.7%, while the non-fraud cohort (3,963 customers) churned at 8.6% — the opposite of what the industry-level pattern suggests. Two plausible explanations, not mutually exclusive:
   - **Recency:** tenure-at-churn data shows most churn happens 1-2 years after onboarding. Since both the fraud case and the churn event have to occur within the same recent window (2024 onboards only), fraud victims may simply not have had enough time to churn yet.
   - **Sample size:** the fraud cohort is small (293 customers, only 2 churned), so the 0.7% figure has wide uncertainty and could shift substantially with more data.

   This result is reported as-is rather than adjusted to match the industry-level narrative — a genuine test of a hypothesis sometimes doesn't confirm it, and that's a more useful finding than forcing a fit.

**7. Churn is a banker issue, not a regional one.** Regional churn is flat (9.1-10.0%) across all five regions. The top-10 relationship managers by churn run 18-28.6% against a 9% network average — Maria Rodgers (28.6%), Julie Alvarez (24.2%), Nicholas Johnson (23.1%) are each 2-3x the network rate.

**8. Customer tenure at churn is bimodal.** 40.5% of churned customers left in year 1-2, and 26.5% left before 6 months.

**9. Regional fraud growth confirms a national pattern.** Every region shows 113-250% YoY fraud loss growth, ruling out a single-market cause.

**10. No branch meets a compound distress threshold.** The restructuring-candidate query required a branch to simultaneously have bottom-quartile active customers, under $5M in 2024 loan principal, over $50,000 in 2024 fraud loss, and under 85% retention. It returned zero rows. Checking against the branch scorecard, no branch's fraud loss exceeds ~$3,700 — an order of magnitude below the $50,000 threshold — so the query correctly shows that branch-level problems, at least on fraud, are diffuse across the network rather than concentrated in identifiable outlier branches. The threshold itself should be recalibrated to the network's actual scale before concluding there's genuinely nothing to flag.

**11. A data integrity issue.** A recovery-scenario query sources gross fraud loss ($96,596 for 2024) from a different table (`pbi_nexus.fact_fraud_cases`) than the main fraud analysis (`nexus_banking.fraud_cases`), whose monthly totals sum to roughly $9.6M for the same year — a two-order-of-magnitude discrepancy.

## Recommendations

1. **Investigate the July 2024 trigger.** Pull change logs, staffing changes, and control changes from June/July 2024 — still the single strongest lead in the dataset.
2. **Re-test the fraud-churn relationship on a mature cohort** — customers onboarded 18+ months ago — to rule out the recency effect before drawing conclusions from the current result.
3. **Tighten fraud controls and onboarding review** for Construction, Retail Trade, and Accommodation & Food — still the highest-exposure segments in aggregate, regardless of how the direct causal test resolves.
4. **Coach or reassign the top-churn relationship managers** — a contained, fixable issue independent of the fraud investigation.
5. **Reconcile the two fraud-loss data sources** before any dollar figure from this analysis is used externally or in a board deck.
6. **Recalibrate the branch restructuring thresholds** to the network's actual fraud-loss scale, then re-run the compound filter to see if any branches surface.

## Next Steps

- Re-run the fraud-churn cohort comparison on the full customer base with a longer observation window
- Build the branch restructuring query with percentile-based thresholds instead of fixed dollar cutoffs
- Extend the analysis to loan approval-to-disbursement time, which leadership flagged but which isn't yet covered in the dataset
- Document root-cause findings from the June/July 2024 operational review once available
- Formally reconcile and document the two fraud-loss table sources
