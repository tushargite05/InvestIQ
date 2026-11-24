# InvestIQ Research Report  
## Equity Portfolio Construction, Performance Attribution & Interactive Dashboard

**Student:** Sarthak Bhagawatkar  
**Course:** Financial Analytics — Practical Assignment (SBUP)  
**Platform:** InvestIQ — Smart Equity Portfolio Analytics & Optimization  
**Capital:** INR 20,00,000 (simulated)  
**Benchmark:** Nifty 50  
**Formation date:** 31 July 2026  
**Performance window:** 1 August 2026 – 30 October 2026 (last NSE session on/before 31 Oct 2026)  
**Classification:** Historical simulation / backtest  

> Re-run `Rscript scripts/run_all.R` and paste computed figures from `output/metrics/` into the bracketed placeholders before final submission. Approximate word target: 2,000–3,000.

---

### 1. Executive summary and portfolio mandate

InvestIQ implements an evidence-based long-only Indian equity process: screen for value using fundamentals, time entry with explicit technical rules, construct and optimize a multi-stock portfolio (≥5 names), then evaluate risk-adjusted performance and attribution versus Nifty 50 through a client-facing R Shiny dashboard.

The mandate assumes a **>3-year investment horizon**, INR 20 lakhs initial capital, and preference for NIFTY 500–style liquidity. Success is judged by process integrity—not whether the short Aug–Oct 2026 window produced a positive return.

**Key computed results (Yahoo adjusted closes; historical simulation):**  
- Equal-weight cumulative return: **−5.78%**  
- Max-Sharpe optimized cumulative return: **−8.64%**  
- Nifty 50 cumulative return: **−5.46%**  
- Active (optimized): **−3.19%** | Sharpe (opt): **−3.40** | Max drawdown (opt): **−11.0%**  
- Largest positive contributor (opt): **INFY** | Largest drag: **HINDUNILVR**  

Process integrity matters more than the sign of a three-month return. The soft market window is disclosed as a backtest, not a forecast.  

---

### 2. Sector context and fundamental value-screening methodology

A top-down filter emphasizes structurally sound sectors with identifiable earnings drivers:

| Sector | Structural notes |
|--------|------------------|
| Financials | Credit cycle, deposit franchise, asset quality |
| Information Technology | Global IT services demand, margin/wage dynamics |
| Healthcare | Domestic demand + specialty pipeline / regulatory risk |
| Energy | Integrated refining–retail–digital earnings mix |
| Consumer Staples | Pricing power, rural/urban demand, input costs |
| Utilities | Regulated ROE, capex cycle, interest-rate sensitivity |

**Scorecard (weights):** Growth 20%, Profitability 25%, Financial strength 20%, Valuation 25%, Governance 10%. Each criterion scored 1–5 with documented evidence. Selection rule: total score ≥ 3.2 plus liquidity/governance pass. Margin of safety uses midpoint of an intrinsic-value range versus price at formation.

Details: `data/fundamentals/scorecard.xlsx`, `reports/stock_selection_note.md`.

---

### 3. Company scorecards, valuation and selected-stock rationale

**Selected sleeve (score ≥ 3.2):** HDFCBANK (4.30), INFY (4.15), ITC (4.10), SUNPHARMA (4.05), HINDUNILVR (3.20).

**Screened out (transparent):** RELIANCE (2.20) and POWERGRID (2.60) ranked weakly on relative profitability/valuation within this peer set — illustrating that a familiar large-cap name is not automatically a value holding.

Each selected name carries an investment thesis, catalyst, downside risk and invalidation evidence in the scorecard. Valuation uses sector-appropriate multiples (P/E, P/B, EV/EBITDA) versus peers, not mechanical low-P/E screens.

**Important:** Fundamental qualification does **not** set the purchase date.

---

### 4. Technical timing rules and simulated portfolio formation

**Rule (repeatable):**  
Close > SMA(50) AND (SMA(50) > SMA(200) OR Close > SMA(200)) AND RSI(14) ∈ [40, 65], using only prices on or before **31 Jul 2026**.

- Observation / signal date: per stock in `technical_signals.csv`  
- Intended entry: first available session on/after **1 Aug 2026**  
- Price convention: adjusted close  
- Exit / stop: buy-and-hold over the performance window (no retrospective rule changes)  
- Charts: `output/charts/technical_*.png`  

Fundamentals answer *what*; technicals answer *when*. Price momentum is not treated as intrinsic value.

---

### 5. Portfolio weights, diversification and optimization

- **Baseline:** equal weight (1/N).  
- **Alternative:** score-tilted weights.  
- **Optimized:** maximize Sharpe using estimation-window means/covariance (to formation date), long-only, weight box **5–30%**, 20k random feasible portfolios.  
- **Rebalancing:** buy-and-hold in the performance window; transaction costs assumed 0 for the simulation (discuss frictional drag qualitatively).  
- **Diversification:** correlation matrix, HHI, effective N = 1/Σw² — stock count alone does not guarantee diversification.

Optimized weights are **not uniquely correct**; they are sensitive to lookback and constraints. See `weights.csv`, `diversification.csv`, `optimization_meta.csv`.

---

### 6. Performance period, benchmark, data and methodology

| Item | Choice |
|------|--------|
| Benchmark | Nifty 50 (`^NSEI`) |
| Prices | Yahoo Finance adjusted close via quantmod |
| Returns | Simple (discrete) daily returns for aggregation & reporting |
| Risk-free rate | 6.5% annualized proxy (document local T-bill/RBI convention if updated) |
| Dividends | Reflected via adjusted close |
| Estimation vs performance | Moments/VaR prefer longer history ≤ formation; P&L evaluated Aug–Oct 2026 |

Exact first/last observations are recorded in `data/processed/data_meta.csv`.

---

### 7. Risk/return results, risk-adjusted metrics and tail-risk analysis

Report and interpret (from pipeline outputs):

- Cumulative and monthly returns; portfolio vs benchmark growth chart  
- Annualized volatility, beta, maximum drawdown, downside deviation  
- **Sharpe, Sortino, Treynor, Information ratio, M², Jensen’s alpha**  
- **Historical 95% 1-day VaR & Expected Shortfall** on estimation window (primary) and performance window (sensitivity)

**Limitation:** three months of daily observations yield weak inference for ratios and tail risk. Do not treat short-sample ES as a reliable forecast of extreme losses.

---

### 8. Stock contribution and formal attribution

Stock contribution = portfolio weight × holding-period return (buy-and-hold). Identify largest positive/negative contributors in `stock_contribution.csv`.

**Brinson–Fachler:** sector allocation, selection and interaction effects are computed with **approximate static Nifty 50 sector weights** and sector returns proxied from overlapping portfolio constituents where needed. Residuals and methodology limits are disclosed in `brinson_summary.csv`. If the examiner prefers strict official index weights, treat Brinson as illustrative and rely on stock-level contribution.

---

### 9. Dashboard design, key investor insights and limitations

The Shiny app (`app/app.R`) presents: executive KPIs, holdings & rationale, performance, risk & diversification, risk-adjusted metrics, tail risk, attribution, optimization comparison and investor commentary. All metrics are read from pipeline outputs—no hard-coded KPIs.

**Insights:** process separation (value vs timing); diversification via sector mix and effective N; optimizer as a constrained alternative to equal weight; cautious reading of short-window risk stats.

---

### 10. Conclusion, sources and appendices

InvestIQ demonstrates a reproducible path from screening to client communication. Historical Aug–Oct 2026 results are educational, not a promise of future performance.

**Primary sources to cite:** company annual reports & quarterly filings; NSE index information; Yahoo Finance adjusted prices (access dates in scorecard / meta files).  

**Appendices:** `data/fundamentals/scorecard.xlsx`; `output/tables/*`; `output/charts/*`; `output/metrics/*`; Shiny screenshots (capture after local run).

---

*Word count will land in the 2,000–3,000 range once metric placeholders are expanded with pipeline numbers and brief sector write-ups per selected company.*
