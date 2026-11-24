# InvestIQ — Stage 2C–D performance & risk-adjusted metrics

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
symbols <- weights$symbol

perf <- rets_df[rets_df$date >= PERF_START & rets_df$date <= PERF_END, ]
# Estimation sample for VaR/ES (longer history)
est <- rets_df[rets_df$date <= FORMATION_DATE, ]

build_port <- function(w_vec, rets_slice) {
  R <- as.matrix(rets_slice[, symbols, drop = FALSE])
  as.numeric(R %*% w_vec)
}

w_eq <- setNames(weights$weight_equal, weights$symbol)[symbols]
w_opt <- setNames(weights$weight_max_sharpe, weights$symbol)[symbols]

r_eq <- build_port(w_eq, perf)
r_opt <- build_port(w_opt, perf)
r_bmk <- perf$NIFTY50

port_xts <- xts(
  cbind(Equal = r_eq, Optimized = r_opt, Benchmark = r_bmk),
  order.by = perf$date
)

# Save portfolio daily returns
port_df <- data.frame(date = perf$date, equal = r_eq, optimized = r_opt, benchmark = r_bmk)
write.csv(port_df, file.path(PATH_PROCESSED, "portfolio_daily_returns.csv"), row.names = FALSE)

# Cumulative growth of 1
cum <- cumprod(1 + port_xts)
cum_df <- data.frame(date = index(cum), coredata(cum))
write.csv(cum_df, file.path(PATH_PROCESSED, "cumulative_growth.csv"), row.names = FALSE)

# Monthly returns
monthly <- apply.monthly(port_xts, function(x) apply(x, 2, function(z) prod(1 + z) - 1))
monthly_df <- data.frame(date = index(monthly), coredata(monthly))
write.csv(monthly_df, file.path(PATH_TABLES, "monthly_returns.csv"), row.names = FALSE)

ann_factor <- 252
rf_daily <- (1 + RF_ANNUAL)^(1 / 252) - 1

safe_sharpe <- function(r) {
  excess <- r - rf_daily
  if (sd(r) == 0) return(NA_real_)
  mean(excess) / sd(r) * sqrt(ann_factor)
}
safe_sortino <- function(r, mar = rf_daily) {
  downside <- pmin(r - mar, 0)
  dd <- sqrt(mean(downside^2))
  if (dd == 0) return(NA_real_)
  (mean(r) - mar) / dd * sqrt(ann_factor)
}
max_dd <- function(r) {
  wealth <- cumprod(1 + r)
  dd <- wealth / cummax(wealth) - 1
  min(dd)
}
beta_vs <- function(r, b) {
  cov(r, b) / var(b)
}
treynor <- function(r, b) {
  bet <- beta_vs(r, b)
  if (bet == 0) return(NA_real_)
  (mean(r) - rf_daily) * ann_factor / bet
}
info_ratio <- function(r, b) {
  active <- r - b
  te <- sd(active) * sqrt(ann_factor)
  if (te == 0) return(NA_real_)
  mean(active) * ann_factor / te
}
m2 <- function(r, b) {
  # Modigliani–Modigliani at benchmark vol
  sp <- safe_sharpe(r)
  sb_vol <- sd(b) * sqrt(ann_factor)
  RF_ANNUAL + sp * sb_vol
}
jensen_alpha <- function(r, b) {
  # CAPM: Rp - Rf = alpha + beta (Rb - Rf) + e  (daily OLS, annualize alpha)
  y <- r - rf_daily
  x <- b - rf_daily
  fit <- lm(y ~ x)
  as.numeric(coef(fit)[1]) * ann_factor
}
hist_var <- function(r, conf = 0.95) {
  as.numeric(quantile(r, probs = 1 - conf))
}
hist_es <- function(r, conf = 0.95) {
  v <- hist_var(r, conf)
  mean(r[r <= v])
}

calc_bundle <- function(r, b, label) {
  data.frame(
    portfolio = label,
    cumulative_return = prod(1 + r) - 1,
    benchmark_cumulative = prod(1 + b) - 1,
    active_return = (prod(1 + r) - 1) - (prod(1 + b) - 1),
    ann_vol = sd(r) * sqrt(ann_factor),
    benchmark_ann_vol = sd(b) * sqrt(ann_factor),
    beta = beta_vs(r, b),
    max_drawdown = max_dd(r),
    downside_deviation = sqrt(mean(pmin(r - rf_daily, 0)^2)) * sqrt(ann_factor),
    sharpe = safe_sharpe(r),
    sortino = safe_sortino(r),
    treynor = treynor(r, b),
    information_ratio = info_ratio(r, b),
    m2 = m2(r, b),
    jensen_alpha = jensen_alpha(r, b),
    tracking_error = sd(r - b) * sqrt(ann_factor),
    stringsAsFactors = FALSE
  )
}

metrics <- rbind(
  calc_bundle(r_eq, r_bmk, "Equal Weight"),
  calc_bundle(r_opt, r_bmk, "Max Sharpe Optimized")
)
write.csv(metrics, file.path(PATH_METRICS, "performance_metrics.csv"), row.names = FALSE)
write.csv(metrics, file.path(PATH_PROCESSED, "performance_metrics.csv"), row.names = FALSE)

# Tail risk: estimation window portfolio returns (disclose longer window)
r_eq_est <- build_port(w_eq, est)
r_opt_est <- build_port(w_opt, est)

tail_risk <- rbind(
  data.frame(
    portfolio = "Equal Weight",
    window = "estimation (<= formation)",
    method = "Historical",
    confidence = 0.95,
    horizon = "1-day",
    var = hist_var(r_eq_est, 0.95),
    es = hist_es(r_eq_est, 0.95),
    var_perf_window = hist_var(r_eq, 0.95),
    es_perf_window = hist_es(r_eq, 0.95),
    note = "Prefer estimation-window VaR/ES; 3-month window is statistically weak.",
    stringsAsFactors = FALSE
  ),
  data.frame(
    portfolio = "Max Sharpe Optimized",
    window = "estimation (<= formation)",
    method = "Historical",
    confidence = 0.95,
    horizon = "1-day",
    var = hist_var(r_opt_est, 0.95),
    es = hist_es(r_opt_est, 0.95),
    var_perf_window = hist_var(r_opt, 0.95),
    es_perf_window = hist_es(r_opt, 0.95),
    note = "Prefer estimation-window VaR/ES; 3-month window is statistically weak.",
    stringsAsFactors = FALSE
  )
)
write.csv(tail_risk, file.path(PATH_METRICS, "tail_risk.csv"), row.names = FALSE)
write.csv(tail_risk, file.path(PATH_PROCESSED, "tail_risk.csv"), row.names = FALSE)

# Drawdown series (optimized)
wealth <- cumprod(1 + r_opt)
dd <- wealth / cummax(wealth) - 1
dd_df <- data.frame(date = perf$date, drawdown = dd, wealth = wealth)
write.csv(dd_df, file.path(PATH_PROCESSED, "drawdown_optimized.csv"), row.names = FALSE)

# PNG chart: growth
png(file.path(PATH_CHARTS, "portfolio_vs_benchmark.png"), width = 1000, height = 600)
matplot(cum_df$date, cum_df[, -1], type = "l", lty = 1, lwd = 2,
        col = c("#1B4F72", "#117A65", "#B03A2E"),
        xlab = "Date", ylab = "Growth of INR 1",
        main = "Portfolio vs Nifty 50 (Aug–Oct 2026 Historical Simulation)")
legend("topleft", legend = c("Equal", "Optimized", "Nifty 50"),
       col = c("#1B4F72", "#117A65", "#B03A2E"), lty = 1, lwd = 2, bty = "n")
dev.off()

message("Performance & risk metrics saved.")
