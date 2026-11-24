# InvestIQ — Stage 2E contribution & Brinson–Fachler attribution (approx)

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

rets_df <- read.csv(file.path(PATH_PROCESSED, "daily_returns.csv"), stringsAsFactors = FALSE)
rets_df$date <- as.Date(rets_df$date)
weights <- read.csv(file.path(PATH_PROCESSED, "weights.csv"), stringsAsFactors = FALSE)
selected <- read.csv(file.path(PATH_PROCESSED, "selected_stocks.csv"), stringsAsFactors = FALSE)

perf <- rets_df[rets_df$date >= PERF_START & rets_df$date <= PERF_END, ]
symbols <- weights$symbol

# Holding-period simple return per stock (buy-and-hold)
stock_ret <- sapply(symbols, function(s) prod(1 + perf[[s]]) - 1)
bmk_ret <- prod(1 + perf$NIFTY50) - 1

w_eq <- setNames(weights$weight_equal, weights$symbol)
w_opt <- setNames(weights$weight_max_sharpe, weights$symbol)

contrib <- data.frame(
  symbol = symbols,
  sector = weights$sector,
  weight_equal = as.numeric(w_eq[symbols]),
  weight_opt = as.numeric(w_opt[symbols]),
  holding_return = as.numeric(stock_ret[symbols]),
  stringsAsFactors = FALSE
)
contrib$contribution_equal <- contrib$weight_equal * contrib$holding_return
contrib$contribution_opt <- contrib$weight_opt * contrib$holding_return
contrib <- contrib[order(-contrib$contribution_opt), ]

write.csv(contrib, file.path(PATH_PROCESSED, "stock_contribution.csv"), row.names = FALSE)
write.csv(contrib, file.path(PATH_TABLES, "stock_contribution.csv"), row.names = FALSE)

# Active / excess
port_ret_opt <- sum(contrib$contribution_opt)
port_ret_eq <- sum(contrib$contribution_equal)
active <- data.frame(
  metric = c(
    "portfolio_return_equal", "portfolio_return_opt", "benchmark_return",
    "active_equal", "active_opt", "top_contributor_opt", "bottom_contributor_opt"
  ),
  value = c(
    port_ret_eq, port_ret_opt, bmk_ret,
    port_ret_eq - bmk_ret, port_ret_opt - bmk_ret,
    contrib$symbol[1], contrib$symbol[nrow(contrib)]
  ),
  stringsAsFactors = FALSE
)
write.csv(active, file.path(PATH_METRICS, "active_return_summary.csv"), row.names = FALSE)

# ---- Brinson–Fachler (sector-level approximation) ----
# Benchmark sector weights: approximate Nifty 50 sector mix (static, disclosed as approximation)
# Sources: NSE index factsheet-style approximations for assignment; not official live weights.
bmk_sector <- data.frame(
  sector = c(
    "Financials", "Information Technology", "Energy", "Consumer Staples",
    "Healthcare", "Utilities", "Other"
  ),
  w_b = c(0.35, 0.14, 0.12, 0.09, 0.05, 0.03, 0.22),
  stringsAsFactors = FALSE
)

# Portfolio sector weights (optimized) and sector returns (weight-weighted within sector)
port_sec <- aggregate(
  cbind(weight_opt, contribution_opt) ~ sector,
  data = contrib,
  FUN = sum
)
port_sec$r_p <- port_sec$contribution_opt / port_sec$weight_opt

# Sector returns for benchmark: use portfolio stock returns as proxy within overlapping sectors,
# and Nifty total for "Other" — DISCLOSED LIMITATION
sec_ret_map <- setNames(port_sec$r_p, port_sec$sector)
# For sectors only in portfolio
bmk_sector$r_b <- ifelse(
  bmk_sector$sector %in% names(sec_ret_map),
  as.numeric(sec_ret_map[bmk_sector$sector]),
  bmk_ret  # fallback for Other
)
# Utilities/Healthcare etc. already mapped if present

# Align portfolio sectors to bmk table
merged <- merge(bmk_sector, port_sec[, c("sector", "weight_opt", "r_p")], by = "sector", all = TRUE)
merged$w_b[is.na(merged$w_b)] <- 0
merged$w_p <- ifelse(is.na(merged$weight_opt), 0, merged$weight_opt)
merged$r_p[is.na(merged$r_p)] <- 0
merged$r_b[is.na(merged$r_b)] <- bmk_ret

# Renormalize portfolio weights to 1 (should already)
merged$w_p <- merged$w_p / sum(merged$w_p)
# Benchmark Other absorbs residual already in table; renormalize lightly
merged$w_b <- merged$w_b / sum(merged$w_b)

# Brinson–Fachler:
# Allocation = (w_p - w_b) * (r_b - r_total_b)
# Selection  = w_b * (r_p - r_b)
# Interaction = (w_p - w_b) * (r_p - r_b)
r_total_b <- sum(merged$w_b * merged$r_b)
merged$allocation <- (merged$w_p - merged$w_b) * (merged$r_b - r_total_b)
merged$selection <- merged$w_b * (merged$r_p - merged$r_b)
merged$interaction <- (merged$w_p - merged$w_b) * (merged$r_p - merged$r_b)
merged$total_effect <- merged$allocation + merged$selection + merged$interaction

brinson <- merged[, c("sector", "w_p", "w_b", "r_p", "r_b", "allocation", "selection", "interaction", "total_effect")]
write.csv(brinson, file.path(PATH_PROCESSED, "brinson_fachler.csv"), row.names = FALSE)
write.csv(brinson, file.path(PATH_TABLES, "brinson_fachler.csv"), row.names = FALSE)

brinson_sum <- data.frame(
  allocation = sum(brinson$allocation),
  selection = sum(brinson$selection),
  interaction = sum(brinson$interaction),
  total_active_approx = sum(brinson$total_effect),
  portfolio_vs_bmk_actual = port_ret_opt - bmk_ret,
  residual = (port_ret_opt - bmk_ret) - sum(brinson$total_effect),
  disclosure = paste(
    "Brinson–Fachler uses approximate static Nifty 50 sector weights and",
    "sector returns proxied from portfolio constituents where overlap exists.",
    "Residual may remain; not official NSE constituent-weight attribution.",
    "If treating as illustrative only, prefer stock-level contribution analysis."
  ),
  stringsAsFactors = FALSE
)
write.csv(brinson_sum, file.path(PATH_METRICS, "brinson_summary.csv"), row.names = FALSE)

png(file.path(PATH_CHARTS, "stock_contribution.png"), width = 900, height = 600)
barplot(
  contrib$contribution_opt,
  names.arg = contrib$symbol,
  las = 2,
  col = ifelse(contrib$contribution_opt >= 0, "#117A65", "#B03A2E"),
  main = "Stock Contribution to Optimized Portfolio Return",
  ylab = "Contribution (weight x return)"
)
dev.off()

message("Attribution saved. Top contributor: ", contrib$symbol[1])
