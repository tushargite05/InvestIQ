# InvestIQ — install & load required packages (lean set for Shiny + analytics)

required_pkgs <- c(
  "shiny", "bslib", "DT", "dplyr", "ggplot2", "scales",
  "quantmod", "PerformanceAnalytics", "xts", "zoo", "TTR",
  "openxlsx"
)

# Optional richer visuals
optional_pkgs <- c("plotly")

install_if_missing <- function(pkgs) {
  missing <- pkgs[!pkgs %in% rownames(installed.packages())]
  if (length(missing) > 0) {
    message("Installing: ", paste(missing, collapse = ", "))
    install.packages(missing, repos = "https://cloud.r-project.org", dependencies = FALSE)
  }
}

install_if_missing(required_pkgs)
# Best-effort optional packages
try(install_if_missing(optional_pkgs), silent = TRUE)

suppressPackageStartupMessages({
  library(shiny)
  library(DT)
  library(dplyr)
  library(quantmod)
  library(PerformanceAnalytics)
  library(xts)
  library(zoo)
  library(TTR)
  library(openxlsx)
})

message("Packages ready.")
