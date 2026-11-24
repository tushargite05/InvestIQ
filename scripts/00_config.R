# InvestIQ — shared configuration
# Historical simulation / backtest (formation & performance window)

PROJECT_ROOT <- if (exists("PROJECT_ROOT") && nzchar(PROJECT_ROOT)) {
  PROJECT_ROOT
} else {
  normalizePath(file.path(dirname(sys.frame(1)$ofile), ".."), mustWork = FALSE)
}

# Paths
PATH_RAW         <- file.path(PROJECT_ROOT, "data", "raw")
PATH_PROCESSED   <- file.path(PROJECT_ROOT, "data", "processed")
PATH_FUNDAMENTALS <- file.path(PROJECT_ROOT, "data", "fundamentals")
PATH_OUTPUT      <- file.path(PROJECT_ROOT, "output")
PATH_CHARTS      <- file.path(PATH_OUTPUT, "charts")
PATH_TABLES      <- file.path(PATH_OUTPUT, "tables")
PATH_METRICS     <- file.path(PATH_OUTPUT, "metrics")

dir.create(PATH_RAW, recursive = TRUE, showWarnings = FALSE)
dir.create(PATH_PROCESSED, recursive = TRUE, showWarnings = FALSE)
dir.create(PATH_FUNDAMENTALS, recursive = TRUE, showWarnings = FALSE)
dir.create(PATH_CHARTS, recursive = TRUE, showWarnings = FALSE)
dir.create(PATH_TABLES, recursive = TRUE, showWarnings = FALSE)
dir.create(PATH_METRICS, recursive = TRUE, showWarnings = FALSE)

# Mandate
INITIAL_CAPITAL_INR <- 2000000  # 20 lakhs
BENCHMARK_TICKER    <- "^NSEI"
BENCHMARK_NAME      <- "Nifty 50"
RF_ANNUAL           <- 0.065    # ~RBI / T-bill proxy for period (document in report)

# Dates (historical simulation)
LOOKBACK_START   <- as.Date("2024-08-01")
FORMATION_DATE    <- as.Date("2026-07-31")  # decisions use info on/before this date
PERF_START       <- as.Date("2026-08-01")
PERF_END         <- as.Date("2026-10-30")  # last NSE session on/before 31 Oct 2026 (Sat)

# Universe (NIFTY 500–style value candidates)
TICKERS <- c(
  "HDFCBANK.NS",
  "INFY.NS",
  "SUNPHARMA.NS",
  "RELIANCE.NS",
  "HINDUNILVR.NS",
  "ITC.NS",
  "POWERGRID.NS"
)

SECTOR_MAP <- data.frame(
  ticker = TICKERS,
  symbol = gsub("\\.NS$", "", TICKERS),
  sector = c(
    "Financials",
    "Information Technology",
    "Healthcare",
    "Energy",
    "Consumer Staples",
    "Consumer Staples",
    "Utilities"
  ),
  name = c(
    "HDFC Bank Ltd",
    "Infosys Ltd",
    "Sun Pharmaceutical Industries Ltd",
    "Reliance Industries Ltd",
    "Hindustan Unilever Ltd",
    "ITC Ltd",
    "Power Grid Corporation of India Ltd"
  ),
  stringsAsFactors = FALSE
)

# Optimization constraints
MAX_WEIGHT       <- 0.30
MIN_WEIGHT       <- 0.05
OPT_OBJECTIVE    <- "max_sharpe"  # or "min_variance"

# Technical rule parameters
SMA_FAST <- 50
SMA_SLOW <- 200
RSI_PERIOD <- 14
RSI_LOW  <- 40
RSI_HIGH <- 65

DISCLAIMER <- paste(
  "HISTORICAL SIMULATION / BACKTEST:",
  "Portfolio formation uses only information available on or before",
  format(FORMATION_DATE, "%d %b %Y"),
  ". Performance window:",
  format(PERF_START, "%d %b %Y"),
  "to",
  format(PERF_END, "%d %b %Y"),
  "(last NSE session on/before 31 Oct 2026). Not investment advice."
)
