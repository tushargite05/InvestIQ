# InvestIQ

**Smart Equity Portfolio Analytics & Optimization Platform**

From Value Stock Screening to Portfolio Optimization, Performance Attribution and Risk Analytics.

**Start here (all-in-one):** [`START_TO_END.md`](START_TO_END.md) — requirements, setup, run, test, present, submit.

| Field | Value |
|-------|--------|
| Student name | Sarthak Bhagawatkar |
| Course / batch | Financial Analytics — SEM III (2025–27) |
| Institution | Sri Balaji University, Pune (SBUP) |
| Assignment | Equity Portfolio Construction, Performance Attribution & R Shiny Dashboard |
| Capital | INR 20,00,000 (simulated) |
| Benchmark | Nifty 50 |
| Performance window | 1 Aug 2026 – 30 Oct 2026 (last NSE session on/before 31 Oct) |
| Formation date | 31 Jul 2026 |
| Label | **Historical simulation / backtest** |

## What this project does

1. **Fundamental value screening** — sector-aware scorecard, valuation & margin of safety  
2. **Technical timing** — SMA50/SMA200 + RSI entry rules (no look-ahead)  
3. **Portfolio construction & optimization** — equal weight vs max Sharpe (long-only caps)  
4. **Performance & risk** — returns, beta, drawdown, Sharpe/Sortino/Treynor/IR/M²/alpha, VaR & ES  
5. **Attribution** — stock contributions + illustrative Brinson–Fachler  
6. **R Shiny investor dashboard** — interactive client-facing views  

## Folder structure

```
InvestIQ/
  app/                 # Shiny dashboard
  data/raw/            # Downloaded OHLCV
  data/processed/      # Prices, returns, weights, metrics
  data/fundamentals/   # Scorecard CSV/XLSX
  scripts/             # Reproducible pipeline
  output/              # Charts, tables, metrics
  reports/             # Research report & executive summary
  README.md
```

## Requirements

- R ≥ 4.3  
- Internet access for first-time package install and Yahoo Finance downloads  

## Setup

```r
# From project root
setwd("/path/to/InvestIQ")
source("scripts/00_packages.R")   # installs dependencies once
```

## Run the full pipeline

```bash
cd /path/to/InvestIQ
Rscript scripts/run_all.R
```

This regenerates prices, scorecard, technical signals, weights, risk metrics and attribution outputs under `data/` and `output/`.

## Launch the dashboard

```r
setwd("/path/to/InvestIQ")
shiny::runApp("app")
```

Or:

```bash
Rscript -e 'shiny::runApp("app", launch.browser = TRUE)'
```

## Portfolio (scorecard-validated)

| Symbol | Sector | Score |
|--------|--------|------:|
| HDFCBANK | Financials | 4.30 |
| INFY | Information Technology | 4.15 |
| ITC | Consumer Staples | 4.10 |
| SUNPHARMA | Healthcare | 4.05 |
| HINDUNILVR | Consumer Staples | 3.20 |

Screened out of final sleeve: RELIANCE (2.20), POWERGRID (2.60) — below selection threshold on relative scorecard.

## Quick start

```bash
# A) Prices (Yahoo) + analytics — either Python or R

# Python path (fast bootstrap)
python3 scripts/python_bootstrap_prices.py
python3 scripts/python_run_analytics.py

# R path (assignment-primary scripts; skips re-download if processed prices exist)
Rscript scripts/run_all.R

# B) Launch investor dashboard
Rscript -e 'shiny::runApp("app", launch.browser = TRUE)'
```

First-time R package install (once):

```r
source("scripts/00_packages.R")
```

On macOS, if `sass` / `textshaping` fail, install system libs first:

```bash
brew install harfbuzz fribidi pango cairo pkg-config
```

## Important disclosures

- Analysis after the performance window is a **historical simulation**. Formation decisions use only information on/before the formation date.  
- Risk-adjusted ratios and VaR/ES from a ~3-month window are statistically weak; estimation-window tail risk is preferred.  
- Brinson–Fachler uses **approximate** Nifty 50 sector weights — see report for residual/limitations.  
- Not investment advice. Educational assignment only.  

## Deliverables checklist

- [x] Excel/CSV scorecard (`data/fundamentals/`)  
- [x] R source scripts (`scripts/`)  
- [x] Working Shiny app (`app/`)  
- [x] Supporting data (`data/processed/`)  
- [x] Research report skeleton (`reports/research_report.md`)  
- [x] Executive summary (`reports/executive_summary.md`)  
