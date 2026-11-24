#!/usr/bin/env python3
"""Download NSE/Yahoo adjusted prices for InvestIQ when R quantmod is unavailable."""
from __future__ import annotations

import os
from pathlib import Path

import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "raw"
PROC = ROOT / "data" / "processed"
RAW.mkdir(parents=True, exist_ok=True)
PROC.mkdir(parents=True, exist_ok=True)

TICKERS = [
    "HDFCBANK.NS",
    "INFY.NS",
    "SUNPHARMA.NS",
    "RELIANCE.NS",
    "HINDUNILVR.NS",
    "ITC.NS",
    "POWERGRID.NS",
]
BENCHMARK = "^NSEI"
START = "2024-08-01"
END = "2026-10-31"


def download() -> pd.DataFrame:
    import yfinance as yf

    symbols = TICKERS + [BENCHMARK]
    data = yf.download(
        symbols,
        start=START,
        end="2026-11-01",
        auto_adjust=True,
        progress=False,
        group_by="ticker",
        threads=True,
    )
    closes = {}
    for sym in symbols:
        try:
            if isinstance(data.columns, pd.MultiIndex):
                s = data[sym]["Close"].dropna()
            else:
                s = data["Close"].dropna()
            name = "NIFTY50" if sym == BENCHMARK else sym.replace(".NS", "")
            closes[name] = s
            # raw dump
            if isinstance(data.columns, pd.MultiIndex):
                raw = data[sym].dropna(how="all").copy()
            else:
                raw = data.dropna(how="all").copy()
            raw = raw.reset_index()
            safe = "".join(ch if ch.isalnum() else "_" for ch in sym)
            raw.to_csv(RAW / f"{safe}.csv", index=False)
        except Exception as exc:  # noqa: BLE001
            print(f"Skip {sym}: {exc}")
    prices = pd.DataFrame(closes).sort_index().ffill().dropna(how="any")
    prices.index.name = "date"
    return prices


def synthesize() -> pd.DataFrame:
    """Fallback synthetic geometric Brownian paths if Yahoo is unreachable."""
    rng = np.random.default_rng(42)
    dates = pd.bdate_range(START, END)
    names = [t.replace(".NS", "") for t in TICKERS] + ["NIFTY50"]
    # Rough level anchors near mid-2025
    levels = {
        "HDFCBANK": 1650,
        "INFY": 1550,
        "SUNPHARMA": 1700,
        "RELIANCE": 2950,
        "HINDUNILVR": 2500,
        "ITC": 460,
        "POWERGRID": 320,
        "NIFTY50": 24500,
    }
    vols = {
        "HDFCBANK": 0.22,
        "INFY": 0.24,
        "SUNPHARMA": 0.26,
        "RELIANCE": 0.23,
        "HINDUNILVR": 0.18,
        "ITC": 0.20,
        "POWERGRID": 0.16,
        "NIFTY50": 0.14,
    }
    # Correlated shocks via one market factor
    market = rng.normal(0.0002, 0.009, size=len(dates))
    out = {}
    for name in names:
        idiosyncratic = rng.normal(0.00015, vols[name] / np.sqrt(252), size=len(dates))
        beta = 0.9 if name != "NIFTY50" else 1.0
        rets = beta * market + (0 if name == "NIFTY50" else idiosyncratic * 0.7)
        if name == "NIFTY50":
            rets = market
        px = levels[name] * np.cumprod(1 + rets)
        out[name] = px
    prices = pd.DataFrame(out, index=dates)
    prices.index.name = "date"
    print("WARNING: using SYNTHETIC prices (Yahoo unavailable). Label as demo data.")
    return prices


def main() -> None:
    try:
        prices = download()
        if prices.empty or prices.shape[1] < 5:
            raise RuntimeError("Insufficient Yahoo data")
        source = "Yahoo Finance (yfinance)"
    except Exception as exc:  # noqa: BLE001
        print(f"Download failed ({exc}); synthesizing.")
        prices = synthesize()
        source = "SYNTHETIC demo paths"

    prices_out = prices.reset_index()
    prices_out.to_csv(PROC / "adjusted_prices.csv", index=False)
    rets = prices.pct_change().dropna()
    rets_out = rets.reset_index()
    rets_out.to_csv(PROC / "daily_returns.csv", index=False)

    meta = pd.DataFrame(
        [
            {
                "lookback_start": START,
                "formation_date": "2026-07-31",
                "perf_start": "2026-08-01",
                "perf_end": "2026-10-30",
                "first_obs": str(prices.index.min().date()),
                "last_obs": str(prices.index.max().date()),
                "n_obs": len(prices),
                "source": source,
                "adjustment": "Adjusted close (dividends/splits)",
                "disclaimer": (
                    "HISTORICAL SIMULATION / BACKTEST: Portfolio formation uses only "
                    "information available on or before 31 Jul 2026. Performance window: "
                    "01 Aug 2026 to 30 Oct 2026. Not investment advice."
                ),
            }
        ]
    )
    meta.to_csv(PROC / "data_meta.csv", index=False)
    print(f"Wrote {PROC / 'adjusted_prices.csv'} shape={prices.shape} source={source}")


if __name__ == "__main__":
    main()
