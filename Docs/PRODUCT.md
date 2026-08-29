# ItoCanvas Product Brief

## Positioning

**ItoCanvas** is a private, offline-first quantitative options laboratory for macOS. It turns classroom formulas into an interactive decision surface: price an option, inspect Greeks, solve implied volatility, construct multi-leg strategies, and stress the result without sending financial data to a server.

## Audience

- Mathematics and financial engineering students
- Quantitative finance interview candidates
- Options learners who want transparent models instead of brokerage clutter
- Analysts who need fast, reproducible scenario checks

## Version 1 workflows

1. **Price** a European call or put with Black–Scholes–Merton and inspect price, delta, gamma, vega, theta, and rho.
2. **Reverse solve** implied volatility from a market price with no-arbitrage validation.
3. **Stress** spot and volatility on a two-dimensional scenario surface.
4. **Design** multi-leg strategies from useful presets or custom option legs.
5. **Inspect payoff** across expiration prices, including maximum gain/loss and breakevens.
6. **Save and export** work locally for assignments, interview preparation, and analysis notes.

## Product principles

- Native Mac interaction and keyboard support
- Offline by default; no accounts, analytics, or data collection
- Explicit units and assumptions
- Numerically defensive calculations
- Useful defaults, reversible actions, and immediate visual feedback
- Educational explanation without pretending to provide investment advice

## Commercial quality bar

- Cohesive brand and app icon
- Responsive layout at practical Mac window sizes
- Light and dark mode support
- VoiceOver labels and keyboard navigation
- Empty/error states with actionable guidance
- Deterministic unit tests for quantitative logic
- Signed application bundle (ad-hoc for local distribution) and polished DMG
- Privacy statement and financial-risk disclaimer

## Roadmap beyond v1

- Local volatility surface import from CSV
- Binomial tree and American exercise modeling
- Portfolio-level Greeks and P&L attribution
- Historical volatility estimators
- Native document format and shareable lab reports
- Optional paid market-data connectors
