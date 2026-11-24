#!/usr/bin/env python3
"""Full InvestIQ analytics pipeline (Python mirror of R scripts) for reproducibility without waiting on CRAN."""
from __future__ import annotations

import math
from pathlib import Path

import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
PROC = ROOT / "data" / "processed"
FUND = ROOT / "data" / "fundamentals"
CHARTS = ROOT / "output" / "charts"
TABLES = ROOT / "output" / "tables"
METRICS = ROOT / "output" / "metrics"
for p in (PROC, FUND, CHARTS, TABLES, METRICS):
    p.mkdir(parents=True, exist_ok=True)

FORMATION = pd.Timestamp("2026-07-31")
PERF_START = pd.Timestamp("2026-08-01")
PERF_END = pd.Timestamp("2026-10-30")
LOOKBACK = pd.Timestamp("2024-08-01")
RF_ANNUAL = 0.065
RF_DAILY = (1 + RF_ANNUAL) ** (1 / 252) - 1
CAPITAL = 2_000_000
MIN_W, MAX_W = 0.05, 0.30

SECTOR = {
    "HDFCBANK": ("Financials", "HDFC Bank Ltd"),
    "INFY": ("Information Technology", "Infosys Ltd"),
    "SUNPHARMA": ("Healthcare", "Sun Pharmaceutical Industries Ltd"),
    "RELIANCE": ("Energy", "Reliance Industries Ltd"),
    "HINDUNILVR": ("Consumer Staples", "Hindustan Unilever Ltd"),
    "ITC": ("Consumer Staples", "ITC Ltd"),
    "POWERGRID": ("Utilities", "Power Grid Corporation of India Ltd"),
}


def score_1_5(x: pd.Series, higher_better: bool = True) -> pd.Series:
    s = x if higher_better else -x
    r = s.rank(method="average", na_option="keep")
    mx = r.max(skipna=True)
    out = np.ceil(5 * r / mx).clip(1, 5)
    return out.fillna(3).astype(int)


def fundamentals() -> pd.DataFrame:
    rows = dict(
        ticker=[f"{k}.NS" for k in SECTOR],
        symbol=list(SECTOR.keys()),
        sector=[v[0] for v in SECTOR.values()],
        name=[v[1] for v in SECTOR.values()],
        rev_growth=[18, 12, 14, 15, 8, 10, 9],
        ebitda_growth=[16, 11, 15, 14, 7, 9, 8],
        eps_growth=[15, 10, 16, 12, 6, 11, 10],
        gross_margin=[np.nan, 30, 72, 22, 52, 58, np.nan],
        ebitda_margin=[np.nan, 24, 28, 18, 24, 36, 88],
        net_margin=[22, 17, 20, 9, 16, 28, 32],
        roe=[16.5, 28, 16, 9.5, 20, 28, 18],
        roce=[np.nan, 35, 20, 11, 28, 35, 12],
        debt_equity=[np.nan, 0.1, 0.05, 0.45, 0.02, 0.01, 1.4],
        interest_cover=[np.nan, 50, 40, 8, 80, 100, 4.5],
        fcf_positive=[1, 1, 1, 1, 1, 1, 1],
        pe=[18, 24, 35, 25, 55, 28, 17],
        pb=[2.6, 7.5, 5.8, 2.2, 11, 7.5, 2.8],
        ev_ebitda=[np.nan, 16, 24, 12, 38, 18, 10],
        peer_pe=[20, 26, 38, 22, 58, 30, 18],
        promoter_pledge_pct=[0] * 7,
        avg_daily_liquidity_ok=[1] * 7,
        price_at_formation=[1650, 1550, 1700, 2950, 2500, 460, 320],
        iv_low=[1500, 1400, 1550, 2700, 2200, 420, 300],
        iv_high=[1900, 1750, 1950, 3400, 2700, 520, 360],
    )
    fund = pd.DataFrame(rows)
    g = fund[["rev_growth", "ebitda_growth", "eps_growth"]].mean(axis=1)
    fund["s_growth"] = score_1_5(g)
    p = fund[["roe", "roce", "net_margin"]].mean(axis=1)
    fund["s_profit"] = score_1_5(p)
    strength = []
    for i, row in fund.iterrows():
        if row["sector"] == "Financials":
            strength.append(4)
        else:
            a = score_1_5(fund["debt_equity"], higher_better=False).iloc[i]
            b = score_1_5(fund["interest_cover"]).iloc[i]
            strength.append(int(np.clip(round(0.5 * a + 0.5 * b), 1, 5)))
    fund["s_strength"] = strength
    fund["pe_discount"] = (fund["peer_pe"] - fund["pe"]) / fund["peer_pe"]
    fund["mos"] = (fund["iv_high"] + fund["iv_low"]) / 2 / fund["price_at_formation"] - 1
    fund["s_valuation"] = score_1_5(fund[["pe_discount", "mos"]].mean(axis=1))
    fund["s_governance"] = 5
    W = dict(growth=0.20, profit=0.25, strength=0.20, valuation=0.25, governance=0.10)
    fund["total_score"] = (
        fund["s_growth"] * W["growth"]
        + fund["s_profit"] * W["profit"]
        + fund["s_strength"] * W["strength"]
        + fund["s_valuation"] * W["valuation"]
        + fund["s_governance"] * W["governance"]
    ).round(2)
    fund["selected"] = fund["total_score"] >= 3.2
    fund["thesis"] = [
        "Franchise bank with durable deposit franchise; valuation near peer average with quality premium justified.",
        "Global IT services cash compounder; reasonable growth and high ROE; MOS via quality & FCF yield.",
        "Domestic pharma leader with specialty pipeline; margins resilient; entry on relative valuation vs history.",
        "Integrated energy & retail platform; mid-cycle valuation vs EV/EBITDA peers; diversification of earnings.",
        "FMCG quality compounder; rich multiples offset by pricing power and balance-sheet strength — size modest.",
        "Cash-rich staples/cigarettes + FMCG pivot; high ROE/FCF; valuation discount to pure FMCG peers.",
        "Regulated utility with visible cash flows; attractive yield/valuation; leverage acceptable for sector.",
    ]
    fund["catalyst"] = [
        "Credit cycle + CASA improvement",
        "Deal wins / margin recovery",
        "Specialty launches / US FDA clearance",
        "Jio/Retail EBITDA ramp",
        "Rural demand recovery",
        "Hotel/FMCG mix shift",
        "Capex cycle / regulated ROE",
    ]
    fund["downside_risk"] = [
        "NIM compression / asset quality",
        "Wage inflation / client cuts",
        "US pricing / regulatory",
        "Oil crack / refining margin",
        "Input cost / volume slowdown",
        "Regulatory / ESG stigma",
        "Interest-rate / regulatory",
    ]
    fund["invalidate_if"] = [
        "Sustained GNPA spike > guidance",
        "Structural margin < 18% for 4Q",
        "Major FDA ban / recall",
        "Retail/Jio ROCE collapses",
        "Volume decline > peers for 4Q",
        "Punitive tax / abrupt ban risk",
        "Regulatory ROE cut material",
    ]
    fund["source_note"] = (
        "Company annual reports / quarterly results / NSE disclosures / screening platforms; "
        "figures are approximations for assignment scoring — verify before submission."
    )
    fund["access_date"] = pd.Timestamp.today().date().isoformat()
    fund["data_period"] = "FY / TTM approx as of formation date 2026-07-31"
    fund.to_csv(FUND / "scorecard.csv", index=False)
    try:
        fund.to_excel(FUND / "scorecard.xlsx", index=False)
    except Exception:
        pass
    selected = fund[fund["selected"]].copy()
    selected.to_csv(PROC / "selected_stocks.csv", index=False)
    # weights sheet helper
    pd.DataFrame({"criterion": list(W), "weight": list(W.values())}).to_csv(
        FUND / "scorecard_weights.csv", index=False
    )
    return selected


def sma(x: pd.Series, n: int) -> pd.Series:
    return x.rolling(n).mean()


def rsi(x: pd.Series, n: int = 14) -> pd.Series:
    d = x.diff()
    up = d.clip(lower=0)
    down = -d.clip(upper=0)
    ma_up = up.ewm(alpha=1 / n, adjust=False).mean()
    ma_down = down.ewm(alpha=1 / n, adjust=False).mean()
    rs = ma_up / ma_down.replace(0, np.nan)
    return 100 - (100 / (1 + rs))


def technical(prices: pd.DataFrame, symbols: list[str]) -> pd.DataFrame:
    hist = prices.loc[:FORMATION]
    entry_date = prices.loc[PERF_START:].index.min()
    rows = []
    for sym in symbols:
        px = hist[sym]
        s50 = sma(px, 50)
        s200 = sma(px, 200)
        r = rsi(px, 14)
        ok = (px > s50) & ((s50 > s200) | (px > s200)) & (r >= 40) & (r <= 65)
        ok = ok.fillna(False)
        if ok.any():
            idx = ok[ok].index.max()
            passed = True
        else:
            soft = (px > s50).fillna(False)
            idx = soft[soft].index.max() if soft.any() else px.index.max()
            passed = False
        rows.append(
            dict(
                symbol=sym,
                signal_definition="Close>SMA50 & (SMA50>SMA200 or Close>SMA200) & RSI(14) in [40,65]",
                observation_date=idx.date().isoformat(),
                formation_date=FORMATION.date().isoformat(),
                intended_entry_date=entry_date.date().isoformat(),
                entry_price=float(prices.loc[entry_date, sym]),
                close_at_signal=float(px.loc[idx]),
                sma50_at_signal=float(s50.loc[idx]),
                sma200_at_signal=float(s200.loc[idx]) if not math.isnan(s200.loc[idx]) else np.nan,
                rsi_at_signal=float(r.loc[idx]),
                rule_passed=passed,
            )
        )
        # chart
        try:
            import matplotlib

            matplotlib.use("Agg")
            import matplotlib.pyplot as plt

            fig, axes = plt.subplots(2, 1, figsize=(10, 7), sharex=True)
            axes[0].plot(px.index, px.values, color="black", label="Close")
            axes[0].plot(s50.index, s50.values, label="SMA50")
            axes[0].plot(s200.index, s200.values, label="SMA200")
            axes[0].axvline(idx, color="green", ls="--", label="Signal")
            axes[0].set_title(f"{sym} Price / SMAs (pre-formation)")
            axes[0].legend(loc="best", fontsize=8)
            axes[1].plot(r.index, r.values, color="purple")
            axes[1].axhline(40, color="grey", ls=":")
            axes[1].axhline(65, color="grey", ls=":")
            axes[1].axvline(idx, color="green", ls="--")
            axes[1].set_title("RSI(14)")
            fig.tight_layout()
            fig.savefig(CHARTS / f"technical_{sym}.png", dpi=120)
            plt.close(fig)
        except Exception as exc:  # noqa: BLE001
            print("chart skip", sym, exc)
    sig = pd.DataFrame(rows)
    sig.to_csv(PROC / "technical_signals.csv", index=False)
    sig.to_csv(TABLES / "technical_signals.csv", index=False)
    return sig


def optimize(rets: pd.DataFrame, selected: pd.DataFrame) -> pd.DataFrame:
    symbols = list(selected["symbol"])
    est = rets.loc[LOOKBACK:FORMATION, symbols].dropna()
    mu = est.mean() * 252
    cov = est.cov() * 252
    n = len(symbols)
    w_eq = np.repeat(1 / n, n)
    sc = selected.set_index("symbol").loc[symbols, "total_score"].astype(float)
    w_score = (sc / sc.sum()).values
    rng = np.random.default_rng(42)
    raw = rng.exponential(size=(25000, n))
    raw = raw / raw.sum(axis=1, keepdims=True)
    for _ in range(25):
        raw = np.clip(raw, MIN_W, MAX_W)
        raw = raw / raw.sum(axis=1, keepdims=True)
    port_ret = raw @ mu.values
    port_vol = np.sqrt(np.einsum("ij,jk,ik->i", raw, cov.values, raw))
    sharpe = (port_ret - RF_ANNUAL) / port_vol
    w_opt = raw[np.nanargmax(sharpe)]
    port_var = np.einsum("ij,jk,ik->i", raw, cov.values, raw)
    w_min = raw[np.nanargmin(port_var)]
    weights = pd.DataFrame(
        {
            "symbol": symbols,
            "sector": [SECTOR[s][0] for s in symbols],
            "weight_equal": w_eq,
            "weight_score": w_score,
            "weight_max_sharpe": w_opt,
            "weight_min_var": w_min,
        }
    )
    weights["notional_equal_inr"] = (weights["weight_equal"] * CAPITAL).round(2)
    weights["notional_opt_inr"] = (weights["weight_max_sharpe"] * CAPITAL).round(2)
    weights.to_csv(PROC / "weights.csv", index=False)
    weights.to_csv(TABLES / "weights.csv", index=False)
    cors = est.corr()
    cors.to_csv(PROC / "correlation_matrix.csv")
    def eff_n(w):
        return 1 / np.sum(np.asarray(w) ** 2)

    div = pd.DataFrame(
        {
            "metric": [
                "n_holdings",
                "eff_n_equal",
                "eff_n_opt",
                "max_weight_equal",
                "max_weight_opt",
                "hhi_equal",
                "hhi_opt",
                "avg_pairwise_cor",
            ],
            "value": [
                n,
                eff_n(w_eq),
                eff_n(w_opt),
                float(w_eq.max()),
                float(w_opt.max()),
                float(np.sum(w_eq**2)),
                float(np.sum(w_opt**2)),
                float(cors.where(np.triu(np.ones(cors.shape), 1).astype(bool)).stack().mean()),
            ],
        }
    )
    div.to_csv(METRICS / "diversification.csv", index=False)
    eq_vol = math.sqrt(float(w_eq @ cov.values @ w_eq))
    opt_meta = pd.DataFrame(
        [
            {
                "objective": "Maximize Sharpe (mu-rf)/sigma using estimation-window moments",
                "estimation_start": str(est.index.min().date()),
                "estimation_end": str(est.index.max().date()),
                "rf_annual": RF_ANNUAL,
                "min_weight": MIN_W,
                "max_weight": MAX_W,
                "long_only": True,
                "transaction_costs": "Assumed 0 for simulation; discuss in report",
                "rebalancing": "Buy-and-hold over performance window (no intra-window rebalance)",
                "n_simulations": 25000,
                "opt_sharpe_est": float(np.nanmax(sharpe)),
                "equal_sharpe_est": float((w_eq @ mu.values - RF_ANNUAL) / eq_vol),
                "note": "Optimized weights are estimation-sensitive; not uniquely correct.",
            }
        ]
    )
    opt_meta.to_csv(METRICS / "optimization_meta.csv", index=False)
    sector_w = weights.groupby("sector", as_index=False)["weight_max_sharpe"].sum()
    sector_w.to_csv(TABLES / "sector_weights_opt.csv", index=False)
    return weights


def max_dd(r: np.ndarray) -> float:
    wealth = np.cumprod(1 + r)
    peak = np.maximum.accumulate(wealth)
    return float(np.min(wealth / peak - 1))


def metrics_bundle(r: np.ndarray, b: np.ndarray, label: str) -> dict:
    ann = 252
    excess = r - RF_DAILY
    vol = float(np.std(r, ddof=1) * np.sqrt(ann))
    beta = float(np.cov(r, b, ddof=1)[0, 1] / np.var(b, ddof=1))
    downside = np.minimum(r - RF_DAILY, 0)
    dd = float(np.sqrt(np.mean(downside**2)) * np.sqrt(ann))
    sharpe = float(np.mean(excess) / np.std(r, ddof=1) * np.sqrt(ann))
    sortino = float((np.mean(r) - RF_DAILY) / (np.sqrt(np.mean(downside**2)) + 1e-12) * np.sqrt(ann))
    treynor = float((np.mean(r) - RF_DAILY) * ann / beta) if beta else np.nan
    active = r - b
    te = float(np.std(active, ddof=1) * np.sqrt(ann))
    ir = float(np.mean(active) * ann / te) if te else np.nan
    m2 = RF_ANNUAL + sharpe * float(np.std(b, ddof=1) * np.sqrt(ann))
    # Jensen alpha via OLS
    y = r - RF_DAILY
    x = b - RF_DAILY
    x1 = np.column_stack([np.ones(len(x)), x])
    coef, *_ = np.linalg.lstsq(x1, y, rcond=None)
    alpha = float(coef[0] * ann)
    return dict(
        portfolio=label,
        cumulative_return=float(np.prod(1 + r) - 1),
        benchmark_cumulative=float(np.prod(1 + b) - 1),
        active_return=float((np.prod(1 + r) - 1) - (np.prod(1 + b) - 1)),
        ann_vol=vol,
        benchmark_ann_vol=float(np.std(b, ddof=1) * np.sqrt(ann)),
        beta=beta,
        max_drawdown=max_dd(r),
        downside_deviation=dd,
        sharpe=sharpe,
        sortino=sortino,
        treynor=treynor,
        information_ratio=ir,
        m2=m2,
        jensen_alpha=alpha,
        tracking_error=te,
    )


def performance(rets: pd.DataFrame, weights: pd.DataFrame) -> None:
    symbols = list(weights["symbol"])
    perf = rets.loc[PERF_START:PERF_END].dropna()
    est = rets.loc[:FORMATION].dropna()
    w_eq = weights.set_index("symbol").loc[symbols, "weight_equal"].values
    w_opt = weights.set_index("symbol").loc[symbols, "weight_max_sharpe"].values
    r_eq = perf[symbols].values @ w_eq
    r_opt = perf[symbols].values @ w_opt
    r_b = perf["NIFTY50"].values
    port = pd.DataFrame(
        {"date": perf.index, "equal": r_eq, "optimized": r_opt, "benchmark": r_b}
    )
    port.to_csv(PROC / "portfolio_daily_returns.csv", index=False)
    cum = pd.DataFrame(
        {
            "date": perf.index,
            "Equal": np.cumprod(1 + r_eq),
            "Optimized": np.cumprod(1 + r_opt),
            "Benchmark": np.cumprod(1 + r_b),
        }
    )
    cum.to_csv(PROC / "cumulative_growth.csv", index=False)
    # monthly
    tmp = port.set_index("date")
    monthly = (1 + tmp).resample("ME").prod() - 1
    monthly = monthly.reset_index()
    monthly.to_csv(TABLES / "monthly_returns.csv", index=False)
    metrics = pd.DataFrame(
        [
            metrics_bundle(r_eq, r_b, "Equal Weight"),
            metrics_bundle(r_opt, r_b, "Max Sharpe Optimized"),
        ]
    )
    metrics.to_csv(METRICS / "performance_metrics.csv", index=False)
    metrics.to_csv(PROC / "performance_metrics.csv", index=False)

    def hist_var(r, conf=0.95):
        return float(np.quantile(r, 1 - conf))

    def hist_es(r, conf=0.95):
        v = hist_var(r, conf)
        return float(np.mean(r[r <= v]))

    r_eq_e = est[symbols].values @ w_eq
    r_opt_e = est[symbols].values @ w_opt
    tail = pd.DataFrame(
        [
            {
                "portfolio": "Equal Weight",
                "window": "estimation (<= formation)",
                "method": "Historical",
                "confidence": 0.95,
                "horizon": "1-day",
                "var": hist_var(r_eq_e),
                "es": hist_es(r_eq_e),
                "var_perf_window": hist_var(r_eq),
                "es_perf_window": hist_es(r_eq),
                "note": "Prefer estimation-window VaR/ES; 3-month window is statistically weak.",
            },
            {
                "portfolio": "Max Sharpe Optimized",
                "window": "estimation (<= formation)",
                "method": "Historical",
                "confidence": 0.95,
                "horizon": "1-day",
                "var": hist_var(r_opt_e),
                "es": hist_es(r_opt_e),
                "var_perf_window": hist_var(r_opt),
                "es_perf_window": hist_es(r_opt),
                "note": "Prefer estimation-window VaR/ES; 3-month window is statistically weak.",
            },
        ]
    )
    tail.to_csv(METRICS / "tail_risk.csv", index=False)
    tail.to_csv(PROC / "tail_risk.csv", index=False)
    wealth = np.cumprod(1 + r_opt)
    dd = wealth / np.maximum.accumulate(wealth) - 1
    pd.DataFrame({"date": perf.index, "drawdown": dd, "wealth": wealth}).to_csv(
        PROC / "drawdown_optimized.csv", index=False
    )
    try:
        import matplotlib

        matplotlib.use("Agg")
        import matplotlib.pyplot as plt

        fig, ax = plt.subplots(figsize=(10, 6))
        ax.plot(cum["date"], cum["Equal"], label="Equal")
        ax.plot(cum["date"], cum["Optimized"], label="Optimized")
        ax.plot(cum["date"], cum["Benchmark"], label="Nifty 50")
        ax.legend()
        ax.set_title("Portfolio vs Nifty 50 (Aug–Oct 2026 Historical Simulation)")
        ax.set_ylabel("Growth of INR 1")
        fig.tight_layout()
        fig.savefig(CHARTS / "portfolio_vs_benchmark.png", dpi=120)
        plt.close(fig)
    except Exception as exc:  # noqa: BLE001
        print("growth chart skip", exc)


def attribution(rets: pd.DataFrame, weights: pd.DataFrame) -> None:
    symbols = list(weights["symbol"])
    perf = rets.loc[PERF_START:PERF_END].dropna()
    stock_ret = (1 + perf[symbols]).prod() - 1
    bmk_ret = float((1 + perf["NIFTY50"]).prod() - 1)
    w = weights.set_index("symbol")
    contrib = pd.DataFrame(
        {
            "symbol": symbols,
            "sector": [SECTOR[s][0] for s in symbols],
            "weight_equal": w.loc[symbols, "weight_equal"].values,
            "weight_opt": w.loc[symbols, "weight_max_sharpe"].values,
            "holding_return": stock_ret.values,
        }
    )
    contrib["contribution_equal"] = contrib["weight_equal"] * contrib["holding_return"]
    contrib["contribution_opt"] = contrib["weight_opt"] * contrib["holding_return"]
    contrib = contrib.sort_values("contribution_opt", ascending=False)
    contrib.to_csv(PROC / "stock_contribution.csv", index=False)
    contrib.to_csv(TABLES / "stock_contribution.csv", index=False)
    port_opt = float(contrib["contribution_opt"].sum())
    port_eq = float(contrib["contribution_equal"].sum())
    active = pd.DataFrame(
        {
            "metric": [
                "portfolio_return_equal",
                "portfolio_return_opt",
                "benchmark_return",
                "active_equal",
                "active_opt",
                "top_contributor_opt",
                "bottom_contributor_opt",
            ],
            "value": [
                port_eq,
                port_opt,
                bmk_ret,
                port_eq - bmk_ret,
                port_opt - bmk_ret,
                contrib.iloc[0]["symbol"],
                contrib.iloc[-1]["symbol"],
            ],
        }
    )
    active.to_csv(METRICS / "active_return_summary.csv", index=False)

    bmk_sector = pd.DataFrame(
        {
            "sector": [
                "Financials",
                "Information Technology",
                "Energy",
                "Consumer Staples",
                "Healthcare",
                "Utilities",
                "Other",
            ],
            "w_b": [0.35, 0.14, 0.12, 0.09, 0.05, 0.03, 0.22],
        }
    )
    port_sec = contrib.groupby("sector", as_index=False).agg(
        weight_opt=("weight_opt", "sum"), contribution_opt=("contribution_opt", "sum")
    )
    port_sec["r_p"] = port_sec["contribution_opt"] / port_sec["weight_opt"]
    merged = bmk_sector.merge(port_sec, on="sector", how="outer")
    merged["w_b"] = merged["w_b"].fillna(0)
    merged["w_p"] = merged["weight_opt"].fillna(0)
    merged["r_p"] = merged["r_p"].fillna(0)
    sec_map = dict(zip(port_sec["sector"], port_sec["r_p"]))
    merged["r_b"] = merged["sector"].map(lambda s: sec_map.get(s, bmk_ret))
    merged["w_p"] = merged["w_p"] / merged["w_p"].sum()
    merged["w_b"] = merged["w_b"] / merged["w_b"].sum()
    r_total_b = float((merged["w_b"] * merged["r_b"]).sum())
    merged["allocation"] = (merged["w_p"] - merged["w_b"]) * (merged["r_b"] - r_total_b)
    merged["selection"] = merged["w_b"] * (merged["r_p"] - merged["r_b"])
    merged["interaction"] = (merged["w_p"] - merged["w_b"]) * (merged["r_p"] - merged["r_b"])
    merged["total_effect"] = merged["allocation"] + merged["selection"] + merged["interaction"]
    brinson = merged[
        ["sector", "w_p", "w_b", "r_p", "r_b", "allocation", "selection", "interaction", "total_effect"]
    ]
    brinson.to_csv(PROC / "brinson_fachler.csv", index=False)
    brinson.to_csv(TABLES / "brinson_fachler.csv", index=False)
    brinson_sum = pd.DataFrame(
        [
            {
                "allocation": float(brinson["allocation"].sum()),
                "selection": float(brinson["selection"].sum()),
                "interaction": float(brinson["interaction"].sum()),
                "total_active_approx": float(brinson["total_effect"].sum()),
                "portfolio_vs_bmk_actual": port_opt - bmk_ret,
                "residual": (port_opt - bmk_ret) - float(brinson["total_effect"].sum()),
                "disclosure": (
                    "Brinson–Fachler uses approximate static Nifty 50 sector weights and "
                    "sector returns proxied from portfolio constituents where overlap exists. "
                    "Residual may remain; not official NSE constituent-weight attribution."
                ),
            }
        ]
    )
    brinson_sum.to_csv(METRICS / "brinson_summary.csv", index=False)
    try:
        import matplotlib

        matplotlib.use("Agg")
        import matplotlib.pyplot as plt

        fig, ax = plt.subplots(figsize=(9, 6))
        colors = ["#117A65" if v >= 0 else "#B03A2E" for v in contrib["contribution_opt"]]
        ax.bar(contrib["symbol"], contrib["contribution_opt"], color=colors)
        ax.set_title("Stock Contribution to Optimized Portfolio Return")
        ax.set_ylabel("Contribution (weight x return)")
        plt.xticks(rotation=45, ha="right")
        fig.tight_layout()
        fig.savefig(CHARTS / "stock_contribution.png", dpi=120)
        plt.close(fig)
    except Exception as exc:  # noqa: BLE001
        print("contrib chart skip", exc)


def main() -> None:
    prices = pd.read_csv(PROC / "adjusted_prices.csv", parse_dates=["date"]).set_index("date")
    rets = pd.read_csv(PROC / "daily_returns.csv", parse_dates=["date"]).set_index("date")
    selected = fundamentals()
    technical(prices, list(selected["symbol"]))
    weights = optimize(rets, selected)
    performance(rets, weights)
    attribution(rets, weights)
    print("Python analytics complete.")
    print(pd.read_csv(PROC / "performance_metrics.csv").to_string(index=False))


if __name__ == "__main__":
    main()
