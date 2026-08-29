import SwiftUI

struct GuideView: View {
    @EnvironmentObject private var model: AppModel
    @State private var confirmsReset = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PageHeader(
                    eyebrow: "Trust center",
                    title: "Model, Privacy & Terms",
                    subtitle: "Know exactly what ItoCanvas calculates, which assumptions matter, and where your workspace data lives.",
                    trailing: AnyView(StatusPill(text: "No tracking", symbol: "hand.raised.fill", color: .itoMint))
                )

                modelPanel

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 16)], spacing: 16) {
                    privacyPanel
                    limitationsPanel
                    greekConventionsPanel
                    keyboardPanel
                }

                disclaimerPanel
                workspacePanel
            }
            .padding(28)
            .frame(maxWidth: 1180, alignment: .leading)
        }
        .alert("Reset the local workspace?", isPresented: $confirmsReset) {
            Button("Cancel", role: .cancel) {}
            Button("Reset Workspace", role: .destructive) {
                model.resetWorkspace()
            }
        } message: {
            Text("This restores pricing, strategy, scenario, and appearance settings to their defaults. The action cannot be undone.")
        }
    }

    private var modelPanel: some View {
        Panel(title: "Black–Scholes model assumptions", subtitle: "The analytical engine prices European options with continuous compounding") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                assumption("European exercise", "Exercise is modeled only at expiration; American early-exercise value is excluded.", symbol: "calendar.badge.clock")
                assumption("Lognormal returns", "Underlying prices follow geometric Brownian motion with continuous paths.", symbol: "chart.line.uptrend.xyaxis")
                assumption("Constant inputs", "Volatility, rates, and dividend yield remain constant through expiration.", symbol: "slider.horizontal.3")
                assumption("Frictionless market", "No transaction costs, taxes, bid–ask spread, liquidity limits, or discrete hedging.", symbol: "arrow.left.arrow.right")
                assumption("Continuous yield", "Dividends are represented as a continuously compounded annual yield.", symbol: "percent")
                assumption("No counterparty risk", "Funding, settlement, assignment, and default risks are outside the model.", symbol: "building.columns")
            }
        }
    }

    private var privacyPanel: some View {
        infoPanel(
            title: "Privacy by architecture",
            symbol: "lock.shield.fill",
            tint: .itoMint,
            rows: [
                ("Local persistence", "Workspace inputs and appearance settings are saved in macOS UserDefaults on this Mac."),
                ("No accounts", "ItoCanvas has no sign-in, identity profile, cloud database, or synchronization service."),
                ("No telemetry", "The app includes no analytics SDK, tracking pixel, advertising identifier, or crash uploader."),
                ("No network pricing", "Every result is calculated on-device from values you enter; no market-data API is contacted.")
            ]
        )
    }

    private var limitationsPanel: some View {
        infoPanel(
            title: "Interpretation limits",
            symbol: "exclamationmark.triangle.fill",
            tint: .itoAmber,
            rows: [
                ("Model risk", "Real markets exhibit volatility smiles, jumps, skew, changing rates, and discrete dividends."),
                ("Scenario scope", "The heatmap reprices a single European contract. It is not a portfolio VaR or probability forecast."),
                ("Expiration P&L", "Strategy charts show intrinsic value at expiry and entered premiums, not mark-to-market value before expiry."),
                ("Contract multiplier", "Values are presented per share or strategy unit. Apply the contract multiplier required by the instrument.")
            ]
        )
    }

    private var greekConventionsPanel: some View {
        infoPanel(
            title: "Greek conventions",
            symbol: "function",
            tint: .itoIndigo,
            rows: [
                ("Delta", "Change in option value for a one-unit increase in underlying spot."),
                ("Gamma", "Change in delta for a one-unit increase in underlying spot."),
                ("Vega", "Displayed change in value for a one-percentage-point increase in annualized volatility."),
                ("Theta & Rho", "Theta is displayed per calendar day. Rho is displayed per one-percentage-point increase in the annualized rate.")
            ]
        )
    }

    private var keyboardPanel: some View {
        Panel(title: "Keyboard shortcuts", subtitle: "Navigate and act without leaving the keyboard") {
            VStack(spacing: 0) {
                shortcut("Overview", keys: "⌘1")
                Divider().padding(.vertical, 8)
                shortcut("Options Pricer", keys: "⌘2")
                Divider().padding(.vertical, 8)
                shortcut("Strategy Studio", keys: "⌘3")
                Divider().padding(.vertical, 8)
                shortcut("Scenario Lab", keys: "⌘4")
                Divider().padding(.vertical, 8)
                shortcut("Model & Privacy", keys: "⌘5")
                Divider().padding(.vertical, 8)
                shortcut("Solve implied volatility", keys: "⇧⌘↩")
                Divider().padding(.vertical, 8)
                shortcut("Export strategy CSV", keys: "⇧⌘E")
            }
        }
    }

    private var disclaimerPanel: some View {
        Panel(title: "Financial disclaimer", subtitle: nil) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundStyle(Color.itoAccent)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 8) {
                    Text("ItoCanvas is an analytical and educational tool, not investment advice, a recommendation, an offer, or a solicitation to buy or sell any security or derivative.")
                        .font(.subheadline.weight(.semibold))
                    Text("Outputs are estimates from user-supplied assumptions and may differ materially from executable market prices. Verify contract specifications, market data, tax treatment, and risk independently. Options can lose their entire value, and short positions may create substantial or unlimited losses.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("You are solely responsible for decisions made using these calculations.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var workspacePanel: some View {
        Panel(title: "Local workspace", subtitle: "Manage data stored by ItoCanvas on this Mac") {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Restore defaults")
                        .font(.subheadline.weight(.semibold))
                    Text("Clear saved contract, strategy, scenario, and appearance values.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Reset Workspace", role: .destructive) {
                    confirmsReset = true
                }
                .buttonStyle(.bordered)
                .help("Erase the saved local workspace and restore defaults")
                .accessibilityLabel("Reset all local workspace data")
            }
        }
    }

    private func assumption(_ title: String, _ detail: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: symbol)
                .foregroundStyle(Color.itoAccent)
                .frame(width: 30, height: 30)
                .background(Color.itoAccent.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
    }

    private func infoPanel(title: String, symbol: String, tint: Color, rows: [(String, String)]) -> some View {
        Panel(title: title, subtitle: nil) {
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: index == 0 ? symbol : "checkmark.circle")
                            .foregroundStyle(tint)
                            .frame(width: 20)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(row.0).font(.subheadline.weight(.medium))
                            Text(row.1)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .accessibilityElement(children: .combine)
                    if index < rows.count - 1 { Divider().padding(.vertical, 9) }
                }
            }
        }
    }

    private func shortcut(_ action: String, keys: String) -> some View {
        HStack {
            Text(action)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(keys)
                .font(.caption.monospaced().weight(.semibold))
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(action), shortcut \(keys)")
    }
}
