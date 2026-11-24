# InvestIQ — Stage 2B portfolio construction & optimization

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
selected <- read.csv(file.path(PATH_PROCESSED, "selected_stocks.csv"), stringsAsFactors = FALSE)
symbols <- selected$symbol

# Estimation window: lookback up to formation (not performance window)
est <- rets_df[rets_df$date <= FORMATION_DATE & rets_df$date >= LOOKBACK_START, ]
R <- as.matrix(est[, symbols, drop = FALSE])
R <- R[complete.cases(R), ]

mu <- colMeans(R) * 252
cov_mat <- cov(R) * 252
n <- length(symbols)

# ---- Baseline: equal weight ----
w_eq <- rep(1 / n, n)
names(w_eq) <- symbols

# ---- Score-tilted alternative (normalize fundamental scores) ----
sc <- selected$total_score
names(sc) <- selected$symbol
sc <- sc[symbols]
w_score <- as.numeric(sc) / sum(sc)
names(w_score) <- symbols

# ---- Max Sharpe (analytic with box constraints via grid / simple QP-free approach) ----
# Long-only, min/max weight; use random portfolios + refine
set.seed(42)
n_sims <- 20000
rand <- matrix(rexp(n_sims * n), ncol = n)
rand <- rand / rowSums(rand)
# Enforce caps by rejection / rescale
ok <- apply(rand, 1, function(w) all(w >= MIN_WEIGHT - 1e-8) & all(w <= MAX_WEIGHT + 1e-8))
if (sum(ok) < 100) {
  # Soften: clip and renormalize repeatedly
  for (i in seq_len(n_sims)) {
    w <- rand[i, ]
    for (k in 1:20) {
      w <- pmin(pmax(w, MIN_WEIGHT), MAX_WEIGHT)
      w <- w / sum(w)
    }
    rand[i, ] <- w
  }
  ok <- apply(rand, 1, function(w) all(w >= MIN_WEIGHT - 1e-6) & all(w <= MAX_WEIGHT + 1e-6))
}
cand <- rand[ok, , drop = FALSE]
port_ret <- as.numeric(cand %*% mu)
port_vol <- sqrt(rowSums((cand %*% cov_mat) * cand))
sharpe <- (port_ret - RF_ANNUAL) / port_vol
best <- which.max(sharpe)
w_opt <- cand[best, ]
names(w_opt) <- symbols

# Min variance for comparison
port_var <- rowSums((cand %*% cov_mat) * cand)
w_minvar <- cand[which.min(port_var), ]
names(w_minvar) <- symbols

weights <- data.frame(
  symbol = symbols,
  sector = selected$sector[match(symbols, selected$symbol)],
  weight_equal = as.numeric(w_eq),
  weight_score = as.numeric(w_score),
  weight_max_sharpe = as.numeric(w_opt),
  weight_min_var = as.numeric(w_minvar),
  stringsAsFactors = FALSE
)
weights$notional_equal_inr <- round(weights$weight_equal * INITIAL_CAPITAL_INR, 2)
weights$notional_opt_inr <- round(weights$weight_max_sharpe * INITIAL_CAPITAL_INR, 2)

write.csv(weights, file.path(PATH_PROCESSED, "weights.csv"), row.names = FALSE)
write.csv(weights, file.path(PATH_TABLES, "weights.csv"), row.names = FALSE)

# Diversification diagnostics on estimation returns
cors <- cor(R)
write.csv(cors, file.path(PATH_PROCESSED, "correlation_matrix.csv"))
eff_n <- function(w) 1 / sum(w^2)
div <- data.frame(
  metric = c(
    "n_holdings", "eff_n_equal", "eff_n_opt",
    "max_weight_equal", "max_weight_opt",
    "hhi_equal", "hhi_opt",
    "avg_pairwise_cor"
  ),
  value = c(
    n,
    eff_n(w_eq),
    eff_n(w_opt),
    max(w_eq),
    max(w_opt),
    sum(w_eq^2),
    sum(w_opt^2),
    mean(cors[lower.tri(cors)])
  )
)
write.csv(div, file.path(PATH_METRICS, "diversification.csv"), row.names = FALSE)

opt_meta <- data.frame(
  objective = "Maximize Sharpe (mu-rf)/sigma using estimation-window moments",
  estimation_start = min(est$date),
  estimation_end = max(est$date[est$date <= FORMATION_DATE]),
  rf_annual = RF_ANNUAL,
  min_weight = MIN_WEIGHT,
  max_weight = MAX_WEIGHT,
  long_only = TRUE,
  transaction_costs = "Assumed 0 for simulation; discuss in report",
  rebalancing = "Buy-and-hold over performance window (no intra-window rebalance)",
  n_simulations = n_sims,
  opt_sharpe_est = max(sharpe),
  equal_sharpe_est = (sum(w_eq * mu) - RF_ANNUAL) / sqrt(as.numeric(t(w_eq) %*% cov_mat %*% w_eq)),
  note = "Optimized weights are estimation-sensitive; not uniquely correct.",
  stringsAsFactors = FALSE
)
write.csv(opt_meta, file.path(PATH_METRICS, "optimization_meta.csv"), row.names = FALSE)

# Sector concentration
sector_w <- aggregate(weight_max_sharpe ~ sector, data = weights, sum)
write.csv(sector_w, file.path(PATH_TABLES, "sector_weights_opt.csv"), row.names = FALSE)

message("Weights & diversification saved. Eff N (opt) = ", round(eff_n(w_opt), 2))
