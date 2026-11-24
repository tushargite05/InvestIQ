# Stock Selection Note — InvestIQ Value Sleeve

**Student:** Sarthak Bhagawatkar  
**Format:** Concise equity research–style selection note  
**Universe:** NSE-listed / NIFTY 500–style  
**Formation:** 31 July 2026  
**Sources:** Company annual reports, quarterly results, NSE disclosures, screening platforms (verify material figures before final submission)

## Screening philosophy

Value investing here means **business quality + valuation discipline**, not “cheap because price fell.” We combine:

- Structural sector context (growth drivers, cyclicality, regulation)  
- Company economics (returns, cash, leverage)  
- Relative and absolute valuation with an explicit **margin of safety**  
- Governance / liquidity gates  

Technical indicators are **timing tools only** and do not establish intrinsic value.

## Selected names (scorecard-validated)

| Symbol | Sector | Score | Role in portfolio |
|--------|--------|------:|-------------------|
| HDFCBANK | Financials | 4.30 | Quality deposit franchise; earnings visibility |
| INFY | Information Technology | 4.15 | High-ROE cash compounder; global diversification |
| ITC | Consumer Staples | 4.10 | Cash generation; valuation discount vs pure FMCG |
| SUNPHARMA | Healthcare | 4.05 | Specialty/domestic mix; margin resilience |
| HINDUNILVR | Consumer Staples | 3.20 | Pricing power; fortress balance sheet (modest size given rich multiples) |

**Not selected:** RELIANCE (2.20) and POWERGRID (2.60) failed the relative valuation/profitability gates in this peer scorecard — documenting exclusion is part of process integrity.

## Why these qualify as potential value investments

- Diversified across **uncorrelated earnings drivers** (credit cycle, IT spend, healthcare, energy, staples, regulated utilities).  
- Scorecard totals clear the selection threshold with documented criterion scores (see `data/fundamentals/scorecard.xlsx`).  
- Each name has an articulated thesis, catalyst, downside risk and **invalidation evidence**.  
- Mid/large liquidity supports institutional-style simulation sizing (INR 20L).

## What would make us walk away

Sustained thesis invalidation (asset-quality shock, structural margin collapse, material regulatory hit, or governance deterioration) — not short-term price noise.

## Next step

Technical entry rules in `scripts/03_technical_timing.R` and `data/processed/technical_signals.csv` define simulated purchase timing for the Aug–Oct 2026 window.
