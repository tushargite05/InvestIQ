# InvestIQ — Run on Another Computer (Start to End)

**Student:** Sarthak Bhagawatkar  
**Project:** InvestIQ (R Shiny Financial Analytics Assignment)

Use this guide to copy the project to another PC and run everything from zero.

---

## A. What you must copy

Copy the full folder:

```
InvestIQ/
  app/
  data/
  scripts/
  output/
  reports/
  README.md
  DESCRIPTION
  LICENSE
```

Best options:
1. Zip `InvestIQ` → copy via USB / Google Drive / email
2. Or push to GitHub / Git and clone on the other PC

Keep folder name **InvestIQ**.

---

## B. Requirements on the new PC

### Required
- **R** (version 4.3 or newer recommended)
- **RStudio** (optional, but easier)
- Internet (first time: package install + Yahoo price download)

### Optional but useful
- **Python 3** (for fast price/analytics bootstrap)
- On macOS: Homebrew  
- On Windows: install R from https://cran.r-project.org

### Assignment tech used
- R
- Shiny
- bslib, DT, ggplot2
- quantmod / PerformanceAnalytics / TTR / xts / zoo / openxlsx

---

## C. Install R (if not installed)

### Windows
1. Download R from CRAN and install  
2. (Optional) Install RStudio  
3. Open **R** or **RStudio**

### macOS
```bash
brew install r
```

### Check
```bash
Rscript --version
```

---

## D. Open project on new PC

```bash
cd path/to/InvestIQ
```

Example:
- Windows: `cd C:\Users\YourName\Desktop\InvestIQ`
- Mac: `cd ~/Desktop/InvestIQ`

Always run commands from this project root (not from inside `app/`).

---

## E. Start-to-end setup (first time on that PC)

### Step 1 — Install R packages (once)

In Terminal / RStudio console:

```r
setwd("path/to/InvestIQ")   # change to your path
source("scripts/00_packages.R")
```

Or:

```bash
cd path/to/InvestIQ
Rscript -e 'source("scripts/00_packages.R")'
```

**macOS tip:** if `sass` / `textshaping` fail:
```bash
brew install harfbuzz fribidi pango cairo pkg-config
```
Then run package install again.

**Windows tip:** if install fails, run R/RStudio **as Administrator** once, or install Rtools.

---

### Step 2 — Generate / refresh data & analytics

#### Option A — R (assignment primary)

```bash
cd path/to/InvestIQ
Rscript scripts/run_all.R
```

This will:
1. Use existing prices (or download if forced)
2. Build fundamental scorecard
3. Technical signals
4. Weights / optimization
5. Performance, risk, VaR/ES
6. Attribution

#### Option B — Python bootstrap (fast, if Python available)

```bash
cd path/to/InvestIQ
python3 -m pip install yfinance pandas numpy matplotlib openpyxl
python3 scripts/python_bootstrap_prices.py
python3 scripts/python_run_analytics.py
```

Then still use R for the Shiny website.

---

### Step 3 — Launch the website (dashboard)

```bash
cd path/to/InvestIQ
Rscript -e 'shiny::runApp("app", launch.browser = TRUE)'
```

Or in RStudio:
1. Open `app/app.R`
2. Click **Run App**

Browser opens InvestIQ.

Stop with `Ctrl + C` (Terminal) or stop button in RStudio.

---

## F. Quick test on the new PC (5 minutes)

1. Overview tab → KPIs visible  
2. Holdings → 5 stocks visible  
3. Performance → growth chart visible  
4. Sidebar: switch Equal ↔ Max Sharpe → numbers change  
5. No red error page  

Full UI checklist: `reports/UI_Testing_Guide.md`

---

## G. If data already exists (faster)

If you copied `data/processed/` and `output/` with the project, you can often skip Step 2 and go straight to Step 3:

```bash
cd path/to/InvestIQ
Rscript -e 'shiny::runApp("app", launch.browser = TRUE)'
```

Still install packages once (Step 1).

To force fresh Yahoo download in R:
```bash
# Mac/Linux
INVESTIQ_FORCE_DOWNLOAD=TRUE Rscript scripts/run_all.R
```

---

## H. Common problems & fixes

| Problem | Fix |
|---------|-----|
| `there is no package called 'shiny'` | Run `source("scripts/00_packages.R")` |
| `Cannot find data/processed` | `cd` into InvestIQ root, then launch app |
| Empty tables | Run `Rscript scripts/run_all.R` again |
| Yahoo download fails | Use Python bootstrap, or keep existing `data/processed` files |
| Port already in use | Close old R/Shiny session, or reboot |
| Windows path issues | Use forward slashes in R: `setwd("C:/Users/.../InvestIQ")` |

---

## I. What to submit / show teacher

1. Working Shiny app  
2. `data/fundamentals/scorecard.xlsx`  
3. `reports/research_report.md`  
4. `reports/executive_summary.md`  
5. `reports/Teacher_Presentation_Brief.md`  
6. Screenshots of main tabs  

---

## J. One-page cheat sheet

```bash
# 1) Go to project
cd path/to/InvestIQ

# 2) Install packages (first time only)
Rscript -e 'source("scripts/00_packages.R")'

# 3) Build analytics
Rscript scripts/run_all.R

# 4) Open website
Rscript -e 'shiny::runApp("app", launch.browser = TRUE)'
```

That’s the full start-to-end flow on any computer.

---

*Sarthak Bhagawatkar — InvestIQ / SBUP Financial Analytics*
