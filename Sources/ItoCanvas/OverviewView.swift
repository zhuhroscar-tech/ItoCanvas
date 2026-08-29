import SwiftUI
import ItoCanvasCore

struct OverviewView: View {
    @EnvironmentObject private var model: AppModel

    private var currentAnalysis: OptionAnalysis? {
        try? model.analysis.get()
    }

    private var strategySpotProfit: Double? {
        let profit = model.strategyProfit(at: model.workspace.pricer.spot)
        return profit.isFinite ? profit : nil
    }

    private var strategyProfitTint: Color {
        guard let strategySpotProfit else { return .secondary }
        return strategySpotProfit >= 0 ? .itoMint : .itoRose
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PageHeader(
                    eyebrow: "Live workspace",
                    title: "Options intelligence, without the clutter",
                    subtitle: "Price contracts, shape multi-leg payoffs, and pressure-test assumptions in one private workspace.",
                    trailing: AnyView(StatusPill(text: "Local-only", symbol: "lock.fill"))
                )

                if let analysis = currentAnalysis {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 12)], spacing: 12) {
                        MetricCard(
                            title: "Theoretical Value",
                            value: analysis.price.currencyText,
                            detail: "Per share",
                            symbol: "dollarsign.circle.fill",
                            tint: .itoAccent
                        )
                        MetricCard(
                            title: "Delta",
                            value: analysis.delta.compactNumberText,
                            detail: "Spot sensitivity",
                            symbol: "triangle.fill",
                            tint: .itoIndigo
                        )
                        MetricCard(
                            title: "Volatility",
                            value: model.workspace.pricer.volatilityPercent.formatted(.number.precision(.fractionLength(1))) + "%",
                            detail: "Annualized input",
                            symbol: "waveform.path.ecg",
                            tint: .itoMint
                        )
                        MetricCard(
                            title: "Strategy P&L at Spot",
                            value: strategySpotProfit?.signedCurrencyText ?? "Unavailable",
                            detail: model.workspace.strategy.name,
                            symbol: "chart.xyaxis.line",
                            tint: strategyProfitTint
                        )
                    }
                } else {
                    ValidationBanner(title: "Pricing inputs need attention", messages: model.workspace.pricer.validationMessages)
                }

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 16) {
                        workspaceSnapshot
                        quickActions
                    }
                    VStack(spacing: 16) {
                        workspaceSnapshot
                        quickActions
                    }
                }

                Panel(title: "Workflow", subtitle: "A disciplined path from single contract to portfolio intuition") {
                    HStack(alignment: .top, spacing: 0) {
                        workflowStep(number: "01", title: "Calibrate", detail: "Validate contract inputs and solve implied volatility.", color: .itoAccent)
                        workflowConnector
                        workflowStep(number: "02", title: "Structure", detail: "Combine editable legs and inspect expiration payoff.", color: .itoIndigo)
                        workflowConnector
                        workflowStep(number: "03", title: "Stress", detail: "Explore joint spot and volatility shocks.", color: .itoMint)
                    }
                }
            }
            .padding(28)
            .frame(maxWidth: 1280, alignment: .leading)
        }
        .background {
            LinearGradient(
                colors: [Color.itoAccent.opacity(0.045), .clear],
                startPoint: .topLeading,
                endPoint: .center
            )
        }
    }

    private var workspaceSnapshot: some View {
        Panel(title: "Current contract", subtitle: "Persisted automatically on this Mac") {
            VStack(spacing: 0) {
                snapshotRow("Option", value: model.workspace.pricer.type == .call ? "Call" : "Put")
                Divider().padding(.vertical, 9)
                snapshotRow("Spot / Strike", value: "\(model.workspace.pricer.spot.currencyText) / \(model.workspace.pricer.strike.currencyText)")
                Divider().padding(.vertical, 9)
                snapshotRow("Time to expiry", value: model.workspace.pricer.daysToExpiry.formatted(.number.precision(.fractionLength(0))) + " days")
                Divider().padding(.vertical, 9)
                snapshotRow("Rate / Dividend", value: "\(model.workspace.pricer.riskFreeRatePercent.formatted(.number.precision(.fractionLength(2))))% / \(model.workspace.pricer.dividendYieldPercent.formatted(.number.precision(.fractionLength(2))))%")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var quickActions: some View {
        Panel(title: "Jump back in", subtitle: "Keyboard shortcuts are shown in the app menus") {
            VStack(spacing: 9) {
                quickAction("Price a contract", detail: "Greeks, IV, and curve", symbol: "function", section: .pricer)
                quickAction("Shape a strategy", detail: model.workspace.strategy.name, symbol: "point.3.connected.trianglepath.dotted", section: .strategy)
                quickAction("Run scenarios", detail: "Spot × volatility matrix", symbol: "square.grid.3x3.square", section: .scenarios)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func quickAction(_ title: String, detail: String, symbol: String, section: AppSection) -> some View {
        Button {
            model.navigate(to: section)
        } label: {
            HStack(spacing: 11) {
                Image(systemName: symbol)
                    .foregroundStyle(Color.itoAccent)
                    .frame(width: 30, height: 30)
                    .background(Color.itoAccent.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.weight(.medium))
                    Text(detail).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Open \(title)")
        .accessibilityLabel("\(title), \(detail)")
    }

    private func snapshotRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }

    private func workflowStep(number: String, title: String, detail: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(number)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
            Text(title)
                .font(.headline)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var workflowConnector: some View {
        Image(systemName: "arrow.right")
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 18)
            .padding(.top, 28)
            .accessibilityHidden(true)
    }
}
