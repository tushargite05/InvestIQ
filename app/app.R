# InvestIQ — Smart Equity Portfolio Analytics & Optimization Platform
# Modern investor dashboard (R Shiny + bslib + DT + ggplot2)
# Prepared by: Sarthak Bhagawatkar

suppressPackageStartupMessages({
  library(shiny)
  library(bslib)
  library(DT)
  library(ggplot2)
})

PROJECT_ROOT <- NULL
candidates <- c(
  normalizePath("..", mustWork = FALSE),
  normalizePath(file.path(getwd(), ".."), mustWork = FALSE),
  getwd()
)
for (cnd in candidates) {
  if (file.exists(file.path(cnd, "data", "processed", "performance_metrics.csv"))) {
    PROJECT_ROOT <- normalizePath(cnd)
    break
  }
}
if (is.null(PROJECT_ROOT)) {
  stop("Cannot find InvestIQ data/processed. Run scripts/run_all.R first.")
}

PROC <- file.path(PROJECT_ROOT, "data", "processed")
MET  <- file.path(PROJECT_ROOT, "output", "metrics")
TAB  <- file.path(PROJECT_ROOT, "output", "tables")

read_csv_safe <- function(path) {
  if (!file.exists(path)) return(NULL)
  read.csv(path, stringsAsFactors = FALSE)
}

pct <- function(x, digits = 2) {
  if (is.null(x) || length(x) == 0 || is.na(x[1])) return("—")
  sprintf(paste0("%+.", digits, "f%%"), 100 * as.numeric(x[1]))
}

num <- function(x, digits = 2) {
  if (is.null(x) || length(x) == 0 || is.na(x[1])) return("—")
  format(round(as.numeric(x[1]), digits), nsmall = digits)
}

iq_theme_plot <- function() {
  theme_minimal(base_family = "sans") +
    theme(
      plot.title = element_text(face = "bold", size = 13, color = "#102a43"),
      plot.subtitle = element_text(size = 10, color = "#627d98"),
      axis.title = element_text(size = 10, color = "#627d98"),
      axis.text = element_text(size = 9, color = "#334e68"),
      legend.position = "top",
      legend.title = element_blank(),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "#d9e2ec"),
      plot.background = element_rect(fill = "transparent", color = NA),
      panel.background = element_rect(fill = "transparent", color = NA)
    )
}

iq_theme <- bs_theme(
  version = 5,
  bootswatch = "flatly",
  primary = "#102a43",
  secondary = "#0f766e",
  success = "#0f766e",
  danger = "#c2410c",
  warning = "#b45309",
  base_font = font_google("Manrope"),
  heading_font = font_google("Fraunces"),
  "navbar-bg" = "#102a43"
)

ui <- page_navbar(
  title = "InvestIQ",
  id = "main_nav",
  theme = iq_theme,
  fillable = FALSE,
  header = tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css"),
    tags$title("InvestIQ | Sarthak Bhagawatkar")
  ),
  sidebar = sidebar(
    width = 280,
    div(class = "sidebar-title", "Controls"),
    selectInput(
      "portfolio", "Portfolio view",
      choices = c("Max Sharpe Optimized" = "optimized", "Equal Weight" = "equal"),
      selected = "optimized"
    ),
    uiOutput("sector_filter"),
    uiOutput("stock_filter"),
    hr(),
    tags$p(tags$strong("Prepared by"), br(), "Sarthak Bhagawatkar"),
    tags$p(tags$strong("Capital"), br(), "INR 20,00,000"),
    tags$p(tags$strong("Benchmark"), br(), "Nifty 50"),
    tags$p(tags$strong("Window"), br(), "1 Aug – 30 Oct 2026"),
    tags$p(tags$strong("Formation"), br(), "31 Jul 2026"),
    helpText("Historical simulation / backtest. Not investment advice.")
  ),

  nav_panel(
    "Overview",
    div(
      class = "investiq-hero",
      div(class = "eyebrow", "Smart Equity Portfolio Analytics"),
      h1("InvestIQ"),
      p(
        class = "tagline",
        "From value stock screening to portfolio optimization, performance attribution and risk analytics — built for investor-ready decisions."
      ),
      div(
        class = "meta-strip",
        span(class = "meta-chip", "Long-only value sleeve"),
        span(class = "meta-chip", "NIFTY 500–style names"),
        span(class = "meta-chip", "R Shiny dashboard"),
        span(class = "meta-chip", "Sarthak Bhagawatkar")
      )
    ),
    uiOutput("kpi_boxes"),
    div(
      class = "mandate-grid",
      div(
        class = "soft-panel",
        h4("Portfolio mandate"),
        p("Long-only Indian equity value portfolio with a multi-year horizon (>3 years). Fundamentals decide what to own; technical rules decide when to enter. Capital: INR 20 lakhs."),
        p(class = "section-note", "Assessment focus is process integrity — not whether the short window delivered a positive return.")
      ),
      div(
        class = "soft-panel",
        h4("Dates & data"),
        verbatimTextOutput("meta_block")
      )
    ),
    div(class = "disclaimer", textOutput("disclaimer"))
  ),

  nav_panel(
    "Holdings",
    p(class = "section-note", "Fundamental scorecard + technical entry signals. Required: symbols, sectors, weights, valuation/score summary and entry evidence."),
    layout_columns(
      col_widths = c(12),
      card(
        card_header("Holdings & valuation summary"),
        DTOutput("holdings_table")
      )
    ),
    layout_columns(
      col_widths = c(12, 12),
      card(
        card_header("Technical entry signals"),
        DTOutput("signals_table")
      ),
      card(
        card_header("Investment theses"),
        DTOutput("thesis_table")
      )
    )
  ),

  nav_panel(
    "Performance",
    p(class = "section-note", "Portfolio versus benchmark growth, periodic returns and active performance."),
    card(
      card_header("Growth of INR 1 vs Nifty 50"),
      plotOutput("growth_plot", height = "430px")
    ),
    layout_columns(
      col_widths = c(6, 6),
      card(card_header("Monthly returns"), DTOutput("monthly_table")),
      card(card_header("Active performance summary"), DTOutput("active_table"))
    )
  ),

  nav_panel(
    "Risk",
    p(class = "section-note", "Volatility, beta, drawdown, correlation and concentration. Stock count alone does not guarantee diversification."),
    card(
      card_header("Optimized portfolio drawdown"),
      plotOutput("dd_plot", height = "360px")
    ),
    layout_columns(
      col_widths = c(5, 7),
      card(card_header("Diversification metrics"), DTOutput("div_table")),
      card(card_header("Correlation matrix"), DTOutput("corr_table"))
    )
  ),

  nav_panel(
    "Risk-Adjusted",
    p(class = "section-note", "Sharpe, Sortino, Treynor, Information ratio, M² and Jensen's alpha. Short three-month window — interpret cautiously."),
    card(
      card_header("Risk-adjusted performance table"),
      DTOutput("metrics_table")
    ),
    card(
      card_header("Definitions"),
      tags$ul(
        tags$li(tags$strong("Sharpe:"), " excess return per unit of total volatility."),
        tags$li(tags$strong("Sortino:"), " excess return vs downside deviation (MAR = daily rf)."),
        tags$li(tags$strong("Treynor:"), " excess return per unit of beta."),
        tags$li(tags$strong("Information ratio:"), " active return / tracking error vs Nifty 50."),
        tags$li(tags$strong("M²:"), " risk-adjusted return at benchmark volatility."),
        tags$li(tags$strong("Jensen's alpha:"), " CAPM intercept (annualized) from daily OLS.")
      )
    )
  ),

  nav_panel(
    "Tail Risk",
    p(class = "section-note", "Historical VaR & Expected Shortfall at 95%, 1-day horizon. Prefer estimation-window estimates over the short performance window."),
    card(
      card_header("VaR & Expected Shortfall"),
      DTOutput("tail_table")
    )
  ),

  nav_panel(
    "Attribution",
    p(class = "section-note", "Stock-level contribution (primary). Brinson–Fachler shown as an illustrative approximation with disclosed limitations."),
    card(
      card_header("Stock contribution to optimized return"),
      plotOutput("contrib_plot", height = "400px")
    ),
    card(card_header("Contribution table"), DTOutput("contrib_table")),
    card(
      card_header("Brinson–Fachler (approximate)"),
      DTOutput("brinson_table"),
      verbatimTextOutput("brinson_note")
    )
  ),

  nav_panel(
    "Optimization",
    p(class = "section-note", "Baseline equal weight vs max-Sharpe optimized weights under long-only and position caps (5–30%)."),
    card(
      card_header("Baseline vs optimized weights"),
      plotOutput("weights_plot", height = "400px")
    ),
    layout_columns(
      col_widths = c(7, 5),
      card(card_header("Weights detail"), DTOutput("weights_table")),
      card(card_header("Optimizer settings"), DTOutput("opt_meta_table"))
    )
  ),

  nav_panel(
    "Commentary",
    card(
      card_header("What drove performance"),
      uiOutput("commentary_perf")
    ),
    layout_columns(
      col_widths = c(6, 6),
      card(
        card_header("Principal risks"),
        tags$ul(
          tags$li("Estimation risk: optimized weights sensitive to lookback covariance/returns."),
          tags$li("Concentration: caps mitigate but do not eliminate idiosyncratic risk."),
          tags$li("Benchmark mismatch: active Nifty 50 vs multi-sector value sleeve."),
          tags$li("Data: Yahoo adjusted closes may differ slightly from official NSE series.")
        )
      ),
      card(
        card_header("Limitations"),
        tags$ul(
          tags$li("Performance window is only ~3 months — ratios and VaR/ES are noisy."),
          tags$li("Brinson sector weights for the benchmark are approximate."),
          tags$li("Historical results are not a guarantee of future performance."),
          tags$li("Educational assignment — not personalized investment advice.")
        )
      )
    ),
    div(class = "disclaimer", textOutput("disclaimer2"))
  )
)

server <- function(input, output, session) {
  metrics <- read_csv_safe(file.path(PROC, "performance_metrics.csv"))
  weights <- read_csv_safe(file.path(PROC, "weights.csv"))
  selected <- read_csv_safe(file.path(PROC, "selected_stocks.csv"))
  signals <- read_csv_safe(file.path(PROC, "technical_signals.csv"))
  growth <- read_csv_safe(file.path(PROC, "cumulative_growth.csv"))
  monthly <- read_csv_safe(file.path(TAB, "monthly_returns.csv"))
  active <- read_csv_safe(file.path(MET, "active_return_summary.csv"))
  divm <- read_csv_safe(file.path(MET, "diversification.csv"))
  corr <- read_csv_safe(file.path(PROC, "correlation_matrix.csv"))
  tailr <- read_csv_safe(file.path(PROC, "tail_risk.csv"))
  contrib <- read_csv_safe(file.path(PROC, "stock_contribution.csv"))
  brinson <- read_csv_safe(file.path(PROC, "brinson_fachler.csv"))
  brinson_sum <- read_csv_safe(file.path(MET, "brinson_summary.csv"))
  opt_meta <- read_csv_safe(file.path(MET, "optimization_meta.csv"))
  dd <- read_csv_safe(file.path(PROC, "drawdown_optimized.csv"))
  meta <- read_csv_safe(file.path(PROC, "data_meta.csv"))

  disclaimer_txt <- if (!is.null(meta) && "disclaimer" %in% names(meta)) meta$disclaimer[1]
  else "Historical simulation / backtest. Not investment advice."

  output$sector_filter <- renderUI({
    secs <- sort(unique(weights$sector))
    selectInput("sectors", "Sectors", choices = secs, selected = secs, multiple = TRUE)
  })
  output$stock_filter <- renderUI({
    selectInput("stocks", "Stocks", choices = weights$symbol, selected = weights$symbol, multiple = TRUE)
  })

  filtered_weights <- reactive({
    req(weights)
    w <- weights
    if (!is.null(input$sectors)) w <- w[w$sector %in% input$sectors, , drop = FALSE]
    if (!is.null(input$stocks)) w <- w[w$symbol %in% input$stocks, , drop = FALSE]
    w
  })

  selected_metrics <- reactive({
    req(metrics)
    label <- if (identical(input$portfolio, "equal")) "Equal Weight" else "Max Sharpe Optimized"
    metrics[metrics$portfolio == label, , drop = FALSE]
  })

  output$kpi_boxes <- renderUI({
    m <- selected_metrics()
    if (is.null(m) || nrow(m) == 0) return(NULL)
    cr <- m$cumulative_return[1]
    ar <- m$active_return[1]
    div(
      class = "kpi-row",
      div(
        class = "kpi",
        div(class = "label", "Cumulative return"),
        div(class = paste("value", ifelse(cr >= 0, "pos", "neg")), pct(cr)),
        div(class = "hint", "Selected portfolio view")
      ),
      div(
        class = "kpi",
        div(class = "label", "Active vs Nifty 50"),
        div(class = paste("value", ifelse(ar >= 0, "pos", "neg")), pct(ar)),
        div(class = "hint", "Excess over benchmark")
      ),
      div(
        class = "kpi",
        div(class = "label", "Sharpe (ann.)"),
        div(class = "value", num(m$sharpe[1])),
        div(class = "hint", "Noisy on 3-month sample")
      ),
      div(
        class = "kpi",
        div(class = "label", "Max drawdown"),
        div(class = "value neg", pct(m$max_drawdown[1])),
        div(class = "hint", sprintf("Beta %s · Vol %s", num(m$beta[1], 2), pct(m$ann_vol[1], 1)))
      )
    )
  })

  output$meta_block <- renderText({
    if (is.null(meta)) return("Run analytics pipeline to generate metadata.")
    paste0(
      "Student: Sarthak Bhagawatkar\n",
      "First observation: ", meta$first_obs[1], "\n",
      "Last observation: ", meta$last_obs[1], "\n",
      "Formation date: ", meta$formation_date[1], "\n",
      "Performance: ", meta$perf_start[1], " to ", meta$perf_end[1], "\n",
      "Source: ", meta$source[1], "\n",
      "Adjustment: ", meta$adjustment[1]
    )
  })
  output$disclaimer <- renderText(disclaimer_txt)
  output$disclaimer2 <- renderText(disclaimer_txt)

  dt_opts <- list(pageLength = 8, scrollX = TRUE, dom = "tip")

  output$holdings_table <- renderDT({
    w <- filtered_weights()
    s <- selected
    df <- merge(w, s[, c("symbol", "total_score", "pe", "pb", "mos", "name")], by = "symbol", all.x = TRUE)
    col <- if (identical(input$portfolio, "equal")) "weight_equal" else "weight_max_sharpe"
    df$weight <- df[[col]]
    datatable(
      df[, c("symbol", "name", "sector", "weight", "total_score", "pe", "pb", "mos")],
      rownames = FALSE,
      options = dt_opts,
      class = "compact stripe hover",
      colnames = c("Symbol", "Name", "Sector", "Weight", "Score", "P/E", "P/B", "MOS")
    ) %>%
      formatPercentage(c("weight", "mos"), 1) %>%
      formatRound(c("total_score", "pe", "pb"), 2)
  })

  output$signals_table <- renderDT({
    req(signals)
    datatable(signals, rownames = FALSE, options = dt_opts, class = "compact stripe hover")
  })
  output$thesis_table <- renderDT({
    req(selected)
    datatable(
      selected[, c("symbol", "thesis", "catalyst", "downside_risk", "invalidate_if")],
      rownames = FALSE,
      options = dt_opts,
      class = "compact stripe hover",
      colnames = c("Symbol", "Thesis", "Catalyst", "Downside risk", "Invalidate if")
    )
  })

  output$growth_plot <- renderPlot({
    req(growth)
    growth$date <- as.Date(growth$date)
    long <- data.frame(
      date = rep(growth$date, 3),
      series = factor(
        rep(c("Equal", "Optimized", "Nifty 50"), each = nrow(growth)),
        levels = c("Equal", "Optimized", "Nifty 50")
      ),
      value = c(growth$Equal, growth$Optimized, growth$Benchmark)
    )
    ggplot(long, aes(date, value, color = series)) +
      geom_line(linewidth = 1.05) +
      scale_color_manual(values = c("Equal" = "#1B4F72", "Optimized" = "#0f766e", "Nifty 50" = "#c2410c")) +
      labs(title = "Portfolio vs Nifty 50", subtitle = "Aug–Oct 2026 historical simulation", x = NULL, y = "Growth of INR 1") +
      iq_theme_plot()
  }, bg = "transparent")

  output$monthly_table <- renderDT({
    req(monthly)
    datatable(monthly, rownames = FALSE, options = dt_opts, class = "compact stripe hover")
  })
  output$active_table <- renderDT({
    req(active)
    datatable(active, rownames = FALSE, options = dt_opts, class = "compact stripe hover")
  })

  output$dd_plot <- renderPlot({
    req(dd)
    dd$date <- as.Date(dd$date)
    ggplot(dd, aes(date, drawdown)) +
      geom_area(fill = "#c2410c", alpha = 0.18) +
      geom_line(color = "#c2410c", linewidth = 1) +
      scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
      labs(title = "Drawdown path (optimized)", x = NULL, y = "Drawdown") +
      iq_theme_plot()
  }, bg = "transparent")

  output$div_table <- renderDT({
    req(divm)
    datatable(divm, rownames = FALSE, options = dt_opts, class = "compact stripe hover") %>%
      formatRound("value", 4)
  })
  output$corr_table <- renderDT({
    req(corr)
    datatable(corr, rownames = FALSE, options = dt_opts, class = "compact stripe hover") %>%
      formatRound(setdiff(names(corr), names(corr)[1]), 3)
  })
  output$metrics_table <- renderDT({
    req(metrics)
    datatable(metrics, rownames = FALSE, options = list(scrollX = TRUE, pageLength = 5, dom = "t"), class = "compact stripe hover")
  })
  output$tail_table <- renderDT({
    req(tailr)
    datatable(tailr, rownames = FALSE, options = list(scrollX = TRUE, pageLength = 5, dom = "t"), class = "compact stripe hover")
  })

  output$contrib_plot <- renderPlot({
    req(contrib)
    cf <- contrib
    if (!is.null(input$stocks)) cf <- cf[cf$symbol %in% input$stocks, , drop = FALSE]
    cf$symbol <- factor(cf$symbol, levels = cf$symbol)
    ggplot(cf, aes(symbol, contribution_opt, fill = contribution_opt >= 0)) +
      geom_col(width = 0.72) +
      scale_fill_manual(values = c("TRUE" = "#0f766e", "FALSE" = "#c2410c"), guide = "none") +
      scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
      labs(title = "Stock contribution (optimized)", x = NULL, y = "Weight × return") +
      iq_theme_plot()
  }, bg = "transparent")

  output$contrib_table <- renderDT({
    req(contrib)
    datatable(contrib, rownames = FALSE, options = dt_opts, class = "compact stripe hover") %>%
      formatPercentage(c("weight_equal", "weight_opt", "holding_return", "contribution_equal", "contribution_opt"), 2)
  })
  output$brinson_table <- renderDT({
    req(brinson)
    datatable(brinson, rownames = FALSE, options = dt_opts, class = "compact stripe hover") %>%
      formatPercentage(c("w_p", "w_b", "r_p", "r_b", "allocation", "selection", "interaction", "total_effect"), 2)
  })
  output$brinson_note <- renderText({
    if (is.null(brinson_sum)) "" else brinson_sum$disclosure[1]
  })

  output$weights_plot <- renderPlot({
    w <- filtered_weights()
    long <- data.frame(
      symbol = rep(w$symbol, 2),
      method = factor(rep(c("Equal", "Max Sharpe"), each = nrow(w)), levels = c("Equal", "Max Sharpe")),
      weight = c(w$weight_equal, w$weight_max_sharpe)
    )
    ggplot(long, aes(symbol, weight, fill = method)) +
      geom_col(position = position_dodge(width = 0.72), width = 0.68) +
      scale_fill_manual(values = c("Equal" = "#1B4F72", "Max Sharpe" = "#0f766e")) +
      scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
      labs(title = "Baseline vs optimized weights", x = NULL, y = "Weight") +
      iq_theme_plot()
  }, bg = "transparent")

  output$weights_table <- renderDT({
    datatable(filtered_weights(), rownames = FALSE, options = dt_opts, class = "compact stripe hover") %>%
      formatPercentage(c("weight_equal", "weight_score", "weight_max_sharpe", "weight_min_var"), 1)
  })
  output$opt_meta_table <- renderDT({
    req(opt_meta)
    long <- data.frame(
      item = names(opt_meta),
      value = as.character(unlist(opt_meta[1, ], use.names = FALSE)),
      stringsAsFactors = FALSE
    )
    datatable(long, rownames = FALSE, options = list(pageLength = 12, dom = "t", scrollX = TRUE), class = "compact stripe hover")
  })

  output$commentary_perf <- renderUI({
    m <- selected_metrics()
    req(contrib)
    top <- contrib$symbol[1]
    bot <- contrib$symbol[nrow(contrib)]
    tagList(
      p(sprintf(
        "Over the Aug–Oct 2026 historical simulation, the selected portfolio view returned %s versus Nifty 50 %s (active %s). Largest positive contributor: %s; largest drag: %s.",
        pct(m$cumulative_return), pct(m$benchmark_cumulative), pct(m$active_return), top, bot
      )),
      p("Value screening established the opportunity set; technical rules governed entry timing near the formation date without using future information."),
      p(tags$em("Prepared for submission by Sarthak Bhagawatkar — InvestIQ / SBUP Financial Analytics."))
    )
  })
}

shinyApp(ui, server)
