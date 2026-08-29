# Changelog

All notable changes to ItoCanvas are documented here.

## [1.0.1] - 2026-08-29

### Fixed

- Normalize corrupted or legacy scenario-grid resolution before use, preventing an unbounded allocation during workspace restoration
- Add app-level persistence regression coverage alongside the quantitative core tests

## [1.0.0] - 2026-08-29

### Added

- Native macOS quantitative options workspace
- Black–Scholes–Merton pricing and Greeks
- Implied-volatility solver with no-arbitrage validation
- Interactive price and expiration P&L charts
- Multi-leg strategy studio with presets
- Spot × volatility scenario heatmap
- Local workspace persistence and CSV export
- Accessible light/dark SwiftUI interface
- Automated tests, macOS CI, app-bundle packaging, and DMG creation
- Offline-first privacy and security documentation
