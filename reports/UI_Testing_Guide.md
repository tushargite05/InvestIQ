# InvestIQ — UI Testing Guide

**Student:** Sarthak Bhagawatkar  
**App:** R Shiny investor dashboard (`app/app.R`)  
**Purpose:** Step-by-step checklist to verify every dashboard function before submission

---

## 1. Start the app

```bash
cd ~/Desktop/InvestIQ
Rscript -e 'shiny::runApp("app", launch.browser = TRUE)'
```

- Browser should open InvestIQ.
- If it does not, copy the URL from Terminal (usually `http://127.0.0.1:XXXX`).
- Stop later with `Ctrl + C` in Terminal.

**Pass if:** page loads with brand title **InvestIQ** and your name **Sarthak Bhagawatkar** in the sidebar/hero.

---

## 2. Sidebar controls (test on every tab)

| Control | What to do | Pass if |
|---------|------------|---------|
| Portfolio view | Switch **Max Sharpe Optimized** ↔ **Equal Weight** | Overview KPIs change; Holdings weight column changes |
| Sectors | Uncheck one sector, then re-check all | Holdings / weights / contribution charts filter |
| Stocks | Remove one stock, then restore all | Tables/plots update to selected names only |

---

## 3. Tab-by-tab functionality

### A. Overview
1. Confirm hero text: value screening → optimization → attribution → risk.
2. Check 4 KPI cards: Cumulative return, Active vs Nifty 50, Sharpe, Max drawdown.
3. Read **Portfolio mandate** and **Dates & data** panels.
4. Confirm disclaimer mentions historical simulation / backtest.

**Pass if:** KPIs show numbers (not blank/error); formation **31 Jul 2026**; window **Aug–Oct 2026**.

---

### B. Holdings
1. Open **Holdings & valuation summary** table.
2. Confirm 5 stocks: HDFCBANK, INFY, ITC, SUNPHARMA, HINDUNILVR.
3. Columns present: Symbol, Name, Sector, Weight, Score, P/E, P/B, MOS.
4. Open **Technical entry signals** — signal dates ≤ formation date.
5. Open **Investment theses** — thesis / catalyst / downside / invalidate-if filled.

**Pass if:** no empty required columns; weights sensible (sum near 100% for full selection).

---

### C. Performance
1. Check **Growth of INR 1 vs Nifty 50** chart (Equal, Optimized, Nifty 50 lines).
2. Open **Monthly returns** table.
3. Open **Active performance summary**.

**Pass if:** chart renders; tables have rows; active metrics visible.

---

### D. Risk
1. Confirm drawdown chart renders (area/line below zero).
2. Check diversification metrics (n holdings, effective N, HHI, correlation).
3. Check correlation matrix table.

**Pass if:** drawdown plot visible; correlation values between −1 and 1.

---

### E. Risk-Adjusted
1. Open metrics table.
2. Confirm columns / values for: Sharpe, Sortino, Treynor, Information ratio, M², Jensen's alpha (plus return/vol/beta/drawdown fields).
3. Read Definitions card.

**Pass if:** both Equal Weight and Max Sharpe rows present; definitions visible.

---

### F. Tail Risk
1. Open VaR & ES table.
2. Confirm method = Historical, confidence = 0.95, horizon = 1-day.
3. Confirm estimation-window and performance-window columns exist.

**Pass if:** VaR/ES values show for both portfolios; note about short-window weakness present in page text.

---

### G. Attribution
1. Check contribution bar chart (positive green / negative coral).
2. Confirm top contributor is highlighted in table (expect **INFY** as top on current run).
3. Open Brinson–Fachler table (allocation / selection / interaction).
4. Read disclosure note under Brinson (approximate benchmark sector weights).

**Pass if:** chart + contribution table + Brinson table + disclosure all visible.

---

### H. Optimization
1. Check grouped bar chart: Equal vs Max Sharpe weights.
2. Open weights detail table (equal / score / max Sharpe / min var + notionals).
3. Open optimizer settings (objective, caps 5–30%, long-only, rf, estimation window).

**Pass if:** optimized weights differ from equal weight; constraints documented.

---

### I. Commentary
1. Read “What drove performance” narrative (auto-filled from metrics).
2. Confirm Principal risks and Limitations lists.
3. Confirm student name appears in commentary footer.

**Pass if:** narrative matches the selected portfolio view KPIs; disclaimer present.

---

## 4. Interactivity smoke test (5 minutes)

1. Set portfolio = **Equal Weight** → note Cumulative KPI.  
2. Switch to **Max Sharpe Optimized** → KPI should change.  
3. On **Holdings**, deselect **HINDUNILVR** → row disappears.  
4. Go to **Attribution** → contribution chart excludes that stock.  
5. Restore all stocks/sectors.  
6. Resize browser window (desktop → narrower) → layout remains usable.

**Pass if:** no red error messages in the app; filters reverse cleanly.

---

## 5. Assignment coverage checklist

| Required dashboard content | Where in UI |
|----------------------------|-------------|
| Executive overview (objective, dates, benchmark, cumulative/active) | Overview |
| Holdings + rationale + technical signal | Holdings |
| Performance vs benchmark + periodic/active | Performance |
| Risk & diversification | Risk |
| Risk-adjusted metrics + definitions | Risk-Adjusted |
| VaR & ES with method/confidence/horizon | Tail Risk |
| Stock contribution + Brinson (disclosed) | Attribution |
| Baseline vs optimized weights | Optimization |
| Investor commentary + limitations | Commentary |
| Filters (stock/sector) + clear labels | Sidebar |

---

## 6. If something fails

| Problem | Fix |
|---------|-----|
| App won’t start | `Rscript -e 'source("scripts/00_packages.R")'` then retry |
| Empty tables / missing KPIs | From project root: `Rscript scripts/run_all.R` (or Python analytics scripts) |
| “Cannot find data/processed” | Run commands from `~/Desktop/InvestIQ`, not from inside `app/` |
| Chart blank | Soft-refresh browser; confirm `data/processed/*.csv` exists |

---

## 7. Screenshot pack (for submission)

Capture these 6 screens:

1. Overview (hero + KPIs)  
2. Holdings table  
3. Performance growth chart  
4. Risk-Adjusted metrics  
5. Attribution contribution chart  
6. Optimization weights chart  

Save under `output/screenshots/` if you create that folder.

---

*End of UI Testing Guide — InvestIQ / Sarthak Bhagawatkar*
