[![English](https://img.shields.io/badge/English-555555?style=flat)](README.md) [![简体中文](https://img.shields.io/badge/简体中文-555555?style=flat)](README.zh-CN.md)

# ItoCanvas

A native, offline macOS app for exploring option pricing and building intuition about risk. ItoCanvas brings European-option pricing, Greeks, implied volatility, multi-leg strategies, and spot/volatility scenarios into one SwiftUI workspace. It is designed for learning and analysis, not trade execution.

![Options workspace](Assets/README/overview.png)

## What you can do

- Price European calls and puts with Black–Scholes–Merton and continuous dividend yield.
- Inspect delta, gamma, vega, theta, and rho; solve implied volatility with no-arbitrage validation.
- Explore a spot × volatility heatmap in the Scenario Lab.
- Build expiration payoff charts using strategy presets or custom legs.
- Save the workspace locally and export CSV data.

[Scenario Lab screenshot](Assets/README/scenarios.png) · [Demo video](Docs/demo.mp4)

## Install

Requires **macOS 14 Sonoma or later**. Download a DMG from [GitHub Releases](https://github.com/zhuhroscar-tech/ItoCanvas/releases/latest), open it, and drag **ItoCanvas** into **Applications**. For maintenance history, see the [changelog](CHANGELOG.md).

The development packaging uses an ad-hoc signature, not Developer ID signing and notarization. macOS may warn or block launch; review the source and release provenance before deciding whether to run it. Do not disable system-wide security protections just to open the app.

## Build and test

Use Xcode 26 or another toolchain providing **Swift 6.2+**:

```bash
git clone https://github.com/zhuhroscar-tech/ItoCanvas.git
cd ItoCanvas
python3 -m unittest discover -s Tests -p 'test_*.py' -v
swift test
./Scripts/build_app.sh
./Scripts/create_dmg.sh
```

The Python contract tests validate repository documentation and CI wiring before the Swift toolchain work starts. The scripts write the application and DMG to `dist/`. Quantitative code lives in `Sources/ItoCanvasCore`; the SwiftUI interface, persistence, and export code live in `Sources/ItoCanvas`.

## Model conventions and limits

Rates and volatility are entered as annualized percentages. Risk-free and dividend rates are continuously compounded; vega and rho are displayed per one percentage-point move, and theta per calendar day.

The model assumes European exercise and lognormal Black–Scholes–Merton dynamics with constant volatility and rates. It does not model early exercise, discrete dividends, volatility smiles or skew, jumps, or stochastic rates. Strategy charts use entered premiums to show expiration payoff, not pre-expiry mark-to-market P&L. Outputs are analytical estimates, not executable market quotes or investment advice.

See [Model notes](Docs/MODEL_NOTES.md) for formulas and solver details and [Product documentation](Docs/PRODUCT.md) for the workspace design.

## Privacy and license

No account or network connection is required; user data stays on the device. See [Privacy](PRIVACY.md), [Security](SECURITY.md), and the [MIT license](LICENSE).
