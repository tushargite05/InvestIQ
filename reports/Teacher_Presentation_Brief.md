# InvestIQ — Teacher Presentation Brief

**Student:** Sarthak Bhagawatkar  
**Project:** InvestIQ — Smart Equity Portfolio Analytics & Optimization Platform  
**Course:** Financial Analytics (SBUP) — Practical Assignment  
**Tech:** R, Shiny, bslib, DT, ggplot2, quantmod / PerformanceAnalytics  

---

## 1. One-line pitch

InvestIQ is an **interactive R Shiny investor dashboard** that shows a full evidence-based equity process: **value screening → technical timing → portfolio construction/optimization → performance & risk → attribution**.

---

## 2. Objective (what the website does)

The website is a **client-facing analytics dashboard** (not a trading app). It helps a teacher/investor see:

1. Which stocks were selected and why (fundamentals)  
2. When they were entered (technical rules, no look-ahead)  
3. How the portfolio was weighted (equal vs optimized)  
4. How it performed vs **Nifty 50** (Aug–Oct 2026 historical simulation)  
5. Risk, risk-adjusted ratios, VaR/ES, and contribution/attribution  

**Initial capital:** INR 20,00,000  
**Mandate:** Long-only, long-term value (>3 years horizon)  
**Label:** Historical simulation / backtest (not live advice)

---

## 3. Process shown on the website

| Stage | What we did | Where to show |
|-------|-------------|----------------|
| Fundamental screening | Weighted scorecard (growth, profit, strength, valuation, governance) | Holdings tab + Excel scorecard |
| Technical timing | SMA50/SMA200 + RSI(14) entry rule on/before 31 Jul 2026 | Holdings → Technical signals |
| Construction | Equal weight baseline | Optimization tab |
| Optimization | Max Sharpe, long-only, 5–30% caps | Optimization tab |
| Performance/risk | Returns, vol, beta, drawdown, ratios, VaR/ES | Performance / Risk / Risk-Adjusted / Tail Risk |
| Attribution | Stock contribution + Brinson–Fachler (approx, disclosed) | Attribution tab |

---

## 4. Final portfolio (5 stocks)

| Symbol | Sector | Score |
|--------|--------|------:|
| HDFCBANK | Financials | 4.30 |
| INFY | Information Technology | 4.15 |
| ITC | Consumer Staples | 4.10 |
| SUNPHARMA | Healthcare | 4.05 |
| HINDUNILVR | Consumer Staples | 3.20 |

**Screened out:** RELIANCE (2.20), POWERGRID (2.60) — below selection threshold (shows process discipline).

---

## 5. Key results (1 Aug – 30 Oct 2026)

| Metric | Equal Weight | Max Sharpe | Nifty 50 |
|--------|-------------:|-----------:|---------:|
| Cumulative return | −5.78% | −8.23% | −5.46% |
| Active vs Nifty 50 | −0.32% | −2.78% | — |
| Ann. volatility | 14.4% | 12.6% | 11.4% |
| Beta | 0.96 | 0.85 | 1.00 |
| Max drawdown | −11.5% | −10.9% | — |
| Sharpe (ann.) | −2.05 | −3.21 | — |

- **Top contributor (optimized):** INFY  
- **Largest drag:** HINDUNILVR  

**Important talking point for teacher:**  
Marks are for **methodology and interpretation**, not for a positive return. The soft three-month window is disclosed; ratios/VaR from a short sample are statistically weak.

---

## 6. Website tabs (demo order)

1. **Overview** — mandate, dates, KPIs  
2. **Holdings** — scores, valuation, technical signals, theses  
3. **Performance** — growth vs Nifty 50, monthly/active returns  
4. **Risk** — drawdown, diversification, correlation  
5. **Risk-Adjusted** — Sharpe, Sortino, Treynor, IR, M², Jensen’s alpha  
6. **Tail Risk** — Historical 95% VaR & ES  
7. **Attribution** — stock contribution + Brinson note  
8. **Optimization** — equal vs max Sharpe weights  
9. **Commentary** — drivers, risks, limitations  

**Filters:** Portfolio view, sector, stock (sidebar)

---

## 7. How to open during presentation

```bash
cd ~/Desktop/InvestIQ
Rscript -e 'shiny::runApp("app", launch.browser = TRUE)'
```

---

## 8. 60-second speech (you can read this)

> Sir/Madam, my project is **InvestIQ**, a Smart Equity Portfolio Analytics platform built in **R Shiny**.  
> I screened NSE value candidates with a transparent fundamental scorecard, timed entries with SMA and RSI rules without look-ahead bias, then built a five-stock INR 20 lakh portfolio.  
> I compared equal weight with max-Sharpe optimization and evaluated Aug–Oct 2026 performance against Nifty 50, including risk ratios, VaR/ES, and attribution.  
> The dashboard is for investor communication — all metrics are computed from data, not hard-coded. The window was soft, so returns are negative; the focus is process integrity and clear limitations.

---

## 9. Files to mention if asked

- Dashboard: `app/app.R`  
- Pipeline: `scripts/01`–`06` + `run_all.R`  
- Scorecard: `data/fundamentals/scorecard.xlsx`  
- Report: `reports/research_report.md`  
- Testing guide: `reports/UI_Testing_Guide.md`  

---

*Prepared by Sarthak Bhagawatkar — InvestIQ / SBUP Financial Analytics*
