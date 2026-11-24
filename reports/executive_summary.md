# InvestIQ — Executive Summary (Client / Investor)

**Prepared by:** Sarthak Bhagawatkar  
**Portfolio:** Smart Equity Value Sleeve (simulated)  
**Capital:** INR 20,00,000  
**Benchmark:** Nifty 50  
**Formation date:** 31 July 2026  
**Performance window:** 1 August 2026 – 30 October 2026  
**Label:** Historical simulation / backtest  

## Mandate

Construct a long-only Indian equity portfolio of at least five NIFTY 500–style names using a **value-first fundamental process**, timed with a **rules-based technical entry**, then measure risk-adjusted performance, diversification and attribution versus Nifty 50.

## Process in brief

1. **What to own** — Sector-aware fundamental scorecard (growth, profitability, strength, valuation, governance) with explicit margin of safety.  
2. **When to enter** — SMA50 / SMA200 and RSI(14) band; signals use only data on or before formation.  
3. **How to weight** — Equal-weight baseline versus max-Sharpe optimization (long-only, 5–30% caps).  
4. **How to judge** — Cumulative/active return, volatility, beta, drawdown, Sharpe/Sortino/Treynor/IR/M²/alpha, VaR & ES, stock contribution and illustrative Brinson effects.

## Holdings (final sleeve)

HDFCBANK, INFY, SUNPHARMA, HINDUNILVR, ITC — diversified across financials, IT, healthcare and staples. RELIANCE and POWERGRID were screened out on the fundamental scorecard.

## Snapshot (Aug–Oct 2026 historical simulation)

| View | Cumulative | vs Nifty 50 | Max DD |
|------|------------:|------------:|-------:|
| Equal weight | −5.78% | −0.32% active | −11.5% |
| Max Sharpe | −8.64% | −3.19% active | −11.0% |
| Nifty 50 | −5.46% | — | — |

Top contributor (optimized): INFY. Largest drag: HINDUNILVR.

## Investor takeaways

- Methodology quality matters more than whether the three-month window delivered a positive return.  
- Optimized weights are **estimation-sensitive**; treat them as one constrained solution, not a unique truth.  
- Tail-risk and ratio estimates from ~3 months of daily data are **noisy**; prefer longer estimation windows for VaR/ES.  
- This summary is educational and **not personalized investment advice**.

## Where to look next

Open the **InvestIQ Shiny dashboard** for live charts, holdings rationale, risk metrics and attribution. Full narrative: `reports/research_report.md`.
