# InvestIQ — Stage 2A technical timing (no look-ahead past FORMATION_DATE)

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

if (!nzchar(Sys.getenv("INVESTIQ_SKIP_PKGS"))) {
  source(file.path(PROJECT_ROOT, "scripts", "00_packages.R"))
} else {
  suppressPackageStartupMessages({
    library(dplyr); library(quantmod); library(PerformanceAnalytics)
    library(xts); library(zoo); library(TTR); library(openxlsx)
  })
}

prices <- read.csv(file.path(PATH_PROCESSED, "adjusted_prices.csv"), stringsAsFactors = FALSE)
prices$date <- as.Date(prices$date)
selected <- read.csv(file.path(PATH_PROCESSED, "selected_stocks.csv"), stringsAsFactors = FALSE)
symbols <- selected$symbol

# Restrict indicator computation to <= formation date for signal validity
hist <- prices[prices$date <= FORMATION_DATE, ]

rsi_calc <- function(x, n = RSI_PERIOD) {
  TTR::RSI(x, n = n)
}

signals <- list()

for (sym in symbols) {
  if (!sym %in% names(hist)) next
  px <- hist[[sym]]
  dt <- hist$date
  sma_f <- TTR::SMA(px, n = SMA_FAST)
  sma_s <- TTR::SMA(px, n = SMA_SLOW)
  rsi <- rsi_calc(px)

  # Entry rule: Close > SMA50, Close > SMA200 (or SMA50 > SMA200), RSI in [40, 65]
  # Prefer most recent valid signal on/before formation
  ok <- !is.na(sma_f) & !is.na(sma_s) & !is.na(rsi) &
    (px > sma_f) & (sma_f > sma_s | px > sma_s) &
    (rsi >= RSI_LOW) & (rsi <= RSI_HIGH)

  if (any(ok, na.rm = TRUE)) {
    idx <- max(which(ok))
  } else {
    # Fallback: closest date to formation with Close > SMA50 (document as soft signal)
    soft <- !is.na(sma_f) & (px > sma_f)
    idx <- if (any(soft)) max(which(soft)) else nrow(hist)
  }

  signal_date <- dt[idx]
  entry_date <- min(prices$date[prices$date >= PERF_START], na.rm = TRUE)
  # Entry price: first available close on/after PERF_START
  entry_row <- which(prices$date >= PERF_START)[1]
  entry_price <- prices[entry_row, sym]

  signals[[sym]] <- data.frame(
    symbol = sym,
    signal_definition = sprintf(
      "Close>SMA%d & (SMA%d>SMA%d or Close>SMA%d) & RSI(%d) in [%d,%d]",
      SMA_FAST, SMA_FAST, SMA_SLOW, SMA_SLOW, RSI_PERIOD, RSI_LOW, RSI_HIGH
    ),
    observation_date = signal_date,
    formation_date = FORMATION_DATE,
    intended_entry_date = entry_date,
    entry_price = entry_price,
    close_at_signal = px[idx],
    sma50_at_signal = sma_f[idx],
    sma200_at_signal = sma_s[idx],
    rsi_at_signal = rsi[idx],
    rule_passed = isTRUE(ok[idx]),
    stringsAsFactors = FALSE
  )

  # Chart evidence (base R png)
  png(file.path(PATH_CHARTS, paste0("technical_", sym, ".png")), width = 1000, height = 700)
  par(mfrow = c(2, 1), mar = c(3, 4, 3, 2))
  plot(dt, px, type = "l", col = "black", main = paste(sym, "Price / SMAs (pre-formation)"),
       xlab = "", ylab = "Adj Close")
  lines(dt, sma_f, col = "steelblue")
  lines(dt, sma_s, col = "darkorange")
  abline(v = signal_date, col = "forestgreen", lty = 2)
  legend("topleft", c("Close", "SMA50", "SMA200", "Signal"),
         col = c("black", "steelblue", "darkorange", "forestgreen"),
         lty = c(1, 1, 1, 2), bty = "n", cex = 0.8)
  plot(dt, rsi, type = "l", col = "purple", main = "RSI(14)", ylab = "RSI", xlab = "Date",
       ylim = c(0, 100))
  abline(h = c(RSI_LOW, RSI_HIGH), col = "grey50", lty = 3)
  abline(v = signal_date, col = "forestgreen", lty = 2)
  dev.off()
}

sig_df <- do.call(rbind, signals)
write.csv(sig_df, file.path(PATH_PROCESSED, "technical_signals.csv"), row.names = FALSE)
write.csv(sig_df, file.path(PATH_TABLES, "technical_signals.csv"), row.names = FALSE)

message("Technical signals saved for ", nrow(sig_df), " stocks. Rule: no look-ahead past formation.")
