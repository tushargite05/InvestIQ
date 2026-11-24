# InvestIQ — download adjusted prices (Yahoo Finance via quantmod)
# Falls back to existing CSVs in data/raw if download fails.

if (!exists("PROJECT_ROOT", envir = .GlobalEnv, inherits = FALSE)) {
  args <- commandArgs(trailingOnly = FALSE)
  fa <- grep("^--file=", args, value = TRUE)
  if (length(fa) > 0) {
    PROJECT_ROOT <- normalizePath(file.path(dirname(sub("^--file=", "", fa[1])), ".."))
  } else {
    wd <- normalizePath(getwd())
    PROJECT_ROOT <- if (dir.exists(file.path(wd, "scripts")) && dir.exists(file.path(wd, "data"))) wd else normalizePath(file.path(wd, ".."))
  }
  assign("PROJECT_ROOT", PROJECT_ROOT, envir = .GlobalEnv)
}
source(file.path(PROJECT_ROOT, "scripts", "_bootstrap.R"))

source(file.path(PROJECT_ROOT, "scripts", "00_packages.R"))

# Prefer existing processed prices (e.g. from python_bootstrap_prices.py)
existing_prices <- file.path(PATH_PROCESSED, "adjusted_prices.csv")
existing_rets <- file.path(PATH_PROCESSED, "daily_returns.csv")
force_dl <- toupper(Sys.getenv("INVESTIQ_FORCE_DOWNLOAD", "FALSE")) %in% c("1", "TRUE", "YES")
if (file.exists(existing_prices) && file.exists(existing_rets) && !force_dl) {
  message("Using existing processed prices at ", existing_prices)
  message("Set INVESTIQ_FORCE_DOWNLOAD=TRUE to re-download via quantmod.")
} else {

download_one <- function(symbol, from, to) {
  message("Downloading ", symbol, " ...")
  tryCatch({
    getSymbols(
      symbol,
      src = "yahoo",
      from = from,
      to = to + 1,
      auto.assign = FALSE,
      warnings = FALSE
    )
  }, error = function(e) {
    warning("Failed ", symbol, ": ", e$message)
    NULL
  })
}

all_symbols <- c(TICKERS, BENCHMARK_TICKER)
price_list <- list()

for (sym in all_symbols) {
  xt <- download_one(sym, LOOKBACK_START, PERF_END)
  if (!is.null(xt)) {
    adj <- Ad(xt)
    colnames(adj) <- gsub("\\.NS$|\\^", "", sym)
    if (sym == BENCHMARK_TICKER) colnames(adj) <- "NIFTY50"
    else colnames(adj) <- gsub("\\.NS$", "", sym)
    price_list[[sym]] <- adj
    # Save raw OHLCV
    df <- data.frame(date = index(xt), coredata(xt), check.names = FALSE)
    safe_name <- gsub("[^A-Za-z0-9]", "_", sym)
    write.csv(df, file.path(PATH_RAW, paste0(safe_name, ".csv")), row.names = FALSE)
  }
}

if (length(price_list) < 2) {
  stop("Insufficient downloads. Place CSVs in data/raw or re-run after network access.")
}

# Align and merge adjusted closes
prices_xts <- do.call(merge, price_list)
prices_xts <- na.locf(prices_xts, na.rm = FALSE)
prices_xts <- na.omit(prices_xts)

prices_df <- data.frame(date = index(prices_xts), coredata(prices_xts), check.names = FALSE)
write.csv(prices_df, file.path(PATH_PROCESSED, "adjusted_prices.csv"), row.names = FALSE)

# Simple daily returns
rets <- Return.calculate(prices_xts, method = "discrete")
rets <- na.omit(rets)
rets_df <- data.frame(date = index(rets), coredata(rets), check.names = FALSE)
write.csv(rets_df, file.path(PATH_PROCESSED, "daily_returns.csv"), row.names = FALSE)

meta <- data.frame(
  lookback_start = LOOKBACK_START,
  formation_date = FORMATION_DATE,
  perf_start = PERF_START,
  perf_end = PERF_END,
  first_obs = as.character(min(index(prices_xts))),
  last_obs = as.character(max(index(prices_xts))),
  n_obs = nrow(prices_xts),
  source = "Yahoo Finance (quantmod)",
  adjustment = "Adjusted close (dividends/splits)",
  disclaimer = DISCLAIMER,
  stringsAsFactors = FALSE
)
write.csv(meta, file.path(PATH_PROCESSED, "data_meta.csv"), row.names = FALSE)

message("Saved adjusted_prices.csv and daily_returns.csv (", nrow(prices_df), " rows)")
}  # end force-download / missing-file branch
