# InvestIQ — regenerate full analytics pipeline
# Usage (from project root): Rscript scripts/run_all.R
# Alternative (no CRAN wait): python3 scripts/python_bootstrap_prices.py &&
#                             python3 scripts/python_run_analytics.py

args_trailing <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_trailing, value = TRUE)
if (length(file_arg) > 0) {
  script_path <- normalizePath(sub("^--file=", "", file_arg))
  PROJECT_ROOT <- normalizePath(file.path(dirname(script_path), ".."))
} else {
  PROJECT_ROOT <- normalizePath(getwd())
}
assign("PROJECT_ROOT", PROJECT_ROOT, envir = .GlobalEnv)
setwd(PROJECT_ROOT)
message("PROJECT_ROOT = ", PROJECT_ROOT)

source(file.path(PROJECT_ROOT, "scripts", "00_packages.R"))

scripts <- c(
  "01_download_prices.R",
  "02_fundamental_screen.R",
  "03_technical_timing.R",
  "04_portfolio_optimize.R",
  "05_performance_risk.R",
  "06_attribution.R"
)

for (s in scripts) {
  message("\n========== Running ", s, " ==========")
  # Each script bootstraps PROJECT_ROOT; source in fresh env but inherit root
  env <- new.env(parent = globalenv())
  assign("PROJECT_ROOT", PROJECT_ROOT, envir = env)
  sys.source(file.path(PROJECT_ROOT, "scripts", s), envir = env)
}

message("\nAll pipeline steps complete. Launch dashboard with:")
message('  shiny::runApp("app")')
