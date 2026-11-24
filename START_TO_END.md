# InvestIQ — Complete Start-to-End Guide (All-in-One)

**Student:** Sarthak Bhagawatkar  
**Project:** InvestIQ — Smart Equity Portfolio Analytics & Optimization Platform  
**Course:** Financial Analytics — SEM III (SBUP)  
**Tech required:** R + Shiny (with supporting R packages)

This is the **one file** to follow from beginning to end: requirements → setup → run → test → present → submit.

---

## 0. What this project is

InvestIQ is an **R Shiny investor dashboard** that shows a full equity process:

1. Fundamental value screening  
2. Technical entry timing  
3. Portfolio construction & optimization  
4. Performance vs Nifty 50  
5. Risk, risk-adjusted metrics, VaR/ES  
6. Contribution & attribution  

**Capital:** INR 20,00,000  
**Benchmark:** Nifty 50  
**Window:** 1 Aug 2026 – 30 Oct 2026 (historical simulation / backtest)  
**Formation date:** 31 Jul 2026  

---

## 1. Assignment requirements (checklist)

### Stage 1 — Fundamental screening
- [x] NSE / NIFTY 500–style universe  
- [x] Sector + business assessment  
- [x] Metrics: growth, profitability, strength, valuation, governance  
- [x] Weighted scorecard (1–5)  
- [x] Margin of safety / valuation rationale  
- [x] At least 5 stocks selected  

**Files:** `data/fundamentals/scorecard.xlsx`, `reports/stock_selection_note.md`

### Stage 2 — Technical + portfolio + analytics + dashboard
- [x] Technical entry rule (SMA50/SMA200 + RSI), no look-ahead  
- [x] Portfolio ≥ 5 stocks, weights sum ~100%  
- [x] Baseline (equal) vs optimized (max Sharpe, long-only caps)  
- [x] Diversification (correlation, concentration, effective N)  
- [x] Returns, vol, beta, drawdown  
- [x] Sharpe, Sortino, Treynor, IR, M², Jensen’s alpha  
- [x] VaR & ES (method/confidence/horizon disclosed)  
- [x] Stock contribution + Brinson (approx + disclosure)  
- [x] Interactive R Shiny dashboard (all required sections)  
- [x] Reproducible scripts + data + README  

**Marks focus:** process quality, not whether return is positive.

---

## 2. Project folder (keep this structure)

```
InvestIQ/
  START_TO_END.md          ← this file
  README.md
  DESCRIPTION
  LICENSE
  app/
    app.R                  ← Shiny website
    www/styles.css
  data/
    raw/                   ← downloaded prices
    processed/             ← returns, weights, metrics
    fundamentals/          ← scorecard
  scripts/
    00_packages.R
    00_config.R
    01_download_prices.R
    02_fundamental_screen.R
    03_technical_timing.R
    04_portfolio_optimize.R
    05_performance_risk.R
    06_attribution.R
    run_all.R
    python_bootstrap_prices.py
    python_run_analytics.py
  output/
    charts/
    tables/
    metrics/
  reports/
    research_report.md
    executive_summary.md
    stock_selection_note.md
    Teacher_Presentation_Brief.md
    UI_Testing_Guide.md
    Run_On_Another_PC.md
```

---

## 3. Final portfolio (current)

| Symbol | Sector | Score |
|--------|--------|------:|
| HDFCBANK | Financials | 4.30 |
| INFY | Information Technology | 4.15 |
| ITC | Consumer Staples | 4.10 |
| SUNPHARMA | Healthcare | 4.05 |
| HINDUNILVR | Consumer Staples | 3.20 |

Screened out: RELIANCE, POWERGRID (below score threshold).

---

## 4. Requirements to run (any PC)

### Must install
1. **R** (≥ 4.3)  
2. Internet (first-time package install / data download)

### Recommended
3. **RStudio** (easier “Run App”)  
4. **Python 3** (optional fast data bootstrap)

### R packages used
`shiny`, `bslib`, `DT`, `ggplot2`, `dplyr`, `scales`,  
`quantmod`, `PerformanceAnalytics`, `xts`, `zoo`, `TTR`, `openxlsx`

---

## 5. Start-to-end on THIS computer

### Step 1 — Go to project
```bash
cd ~/Desktop/InvestIQ
```

### Step 2 — Install packages (once)
```bash
Rscript -e 'source("scripts/00_packages.R")'
```

macOS if package build fails:
```bash
brew install harfbuzz fribidi pango cairo pkg-config
```

### Step 3 — Build all analytics
```bash
Rscript scripts/run_all.R
```

(Optional Python path)
```bash
python3 scripts/python_bootstrap_prices.py
python3 scripts/python_run_analytics.py
```

### Step 4 — Launch website
```bash
Rscript -e 'shiny::runApp("app", launch.browser = TRUE)'
```

Or in RStudio: open `app/app.R` → **Run App**

### Step 5 — Stop
Press `Ctrl + C` in Terminal (or Stop in RStudio).

---

## 6. Start-to-end on ANOTHER computer

1. **Copy** whole `InvestIQ` folder (zip / USB / Drive / Git)  
2. Install **R** on that PC  
3. Open Terminal / RStudio  
4. Run the same Steps 1–4 from Section 5 (change `cd` path)  

If `data/processed/` already exists, you can skip Step 3 and only:
- install packages once  
- launch Shiny  

Force fresh download (optional):
```bash
INVESTIQ_FORCE_DOWNLOAD=TRUE Rscript scripts/run_all.R
```

More detail: `reports/Run_On_Another_PC.md`

---

## 7. How to test the website (short)

1. Open app  
2. **Overview** → KPIs + dates visible  
3. **Holdings** → 5 stocks, scores, signals  
4. **Performance** → growth chart vs Nifty 50  
5. **Risk** → drawdown + correlation  
6. **Risk-Adjusted** → Sharpe/Sortino/Treynor/IR/M²/alpha  
7. **Tail Risk** → VaR & ES  
8. **Attribution** → contribution + Brinson note  
9. **Optimization** → equal vs max Sharpe  
10. **Commentary** → narrative + limitations  
11. Sidebar: switch Equal ↔ Max Sharpe; filter sector/stock  

Full checklist: `reports/UI_Testing_Guide.md`

---

## 8. Key results to tell teacher

| Metric | Equal Weight | Max Sharpe | Nifty 50 |
|--------|-------------:|-----------:|---------:|
| Cumulative return | −5.78% | −8.23% | −5.46% |
| Active return | −0.32% | −2.78% | — |
| Max drawdown | −11.5% | −10.9% | — |

- Top contributor: **INFY**  
- Largest drag: **HINDUNILVR**  
- Focus: **methodology**, not positive return  

Teacher talk track: `reports/Teacher_Presentation_Brief.md`

---

## 9. Dashboard tabs (demo order)

1. Overview  
2. Holdings  
3. Performance  
4. Risk  
5. Risk-Adjusted  
6. Tail Risk  
7. Attribution  
8. Optimization  
9. Commentary  

---

## 10. Submission pack

Zip / submit these:

- [x] `app/` (working Shiny)  
- [x] `scripts/` (reproducible R code)  
- [x] `data/` (prices, processed outputs, scorecard)  
- [x] `output/` (charts, tables, metrics)  
- [x] `reports/` (report + summaries)  
- [x] `README.md`  
- [x] `START_TO_END.md` (this file)  
- [ ] Screenshots of main tabs (capture yourself before submit)

Suggested screenshots:
1. Overview  
2. Holdings  
3. Performance chart  
4. Risk-Adjusted metrics  
5. Attribution  
6. Optimization  

Save to `output/screenshots/` if you create that folder.

---

## 11. One-page cheat commands

```bash
cd ~/Desktop/InvestIQ

# first time only
Rscript -e 'source("scripts/00_packages.R")'

# rebuild analytics
Rscript scripts/run_all.R

# open website
Rscript -e 'shiny::runApp("app", launch.browser = TRUE)'
```

---

## 12. Related docs (optional deep dive)

| File | Use |
|------|-----|
| `README.md` | Project overview |
| `reports/UI_Testing_Guide.md` | Full UI test steps |
| `reports/Run_On_Another_PC.md` | Other-PC setup detail |
| `reports/Teacher_Presentation_Brief.md` | Viva / teacher talk |
| `reports/research_report.md` | Written research report |
| `reports/executive_summary.md` | Client summary |

---

## 13. Your start-to-end order (do this)

1. Read this file once  
2. Run package install  
3. Run `run_all.R`  
4. Launch Shiny  
5. Test all tabs with Section 7  
6. Practice teacher speech from Section 8  
7. Take screenshots  
8. Zip project for submission  

---

*Prepared by Sarthak Bhagawatkar — InvestIQ / SBUP Financial Analytics*
