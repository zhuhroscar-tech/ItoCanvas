import SwiftUI
import ItoCanvasCore

private struct ScenarioSelection: Equatable {
    let spotIndex: Int
    let volatilityIndex: Int
}

struct ScenarioView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selection: ScenarioSelection?

    private var spotChanges: [Double] {
        axisValues(range: model.workspace.scenarios.spotRangePercent / 100)
    }

    private var volatilityChanges: [Double] {
        axisValues(range: model.workspace.scenarios.volatilityRangePoints / 100)
    }

    private var baseAnalysis: OptionAnalysis? {
        try? model.analysis.get()
    }

    private var gridResult: Result<[[Double]], Error> {
        guard model.workspace.pricer.validationMessages.isEmpty else {
            return .failure(WorkspaceValidationError(messages: model.workspace.pricer.validationMessages))
        }
        return Result {
            try ScenarioEngine.priceGrid(
                contract: model.workspace.pricer.contract,
                spotChanges: spotChanges,
                volatilityChanges: volatilityChanges
            )
        }
    }

    private var grid: [[Double]]? { try? gridResult.get() }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PageHeader(
                    eyebrow: "Two-factor stress",
                    title: "Scenario Lab",
                    subtitle: "Map theoretical value across simultaneous spot and implied-volatility shocks. Select any cell for its scenario details.",
                    trailing: AnyView(StatusPill(text: "\(model.workspace.scenarios.steps) × \(model.workspace.scenarios.steps)", symbol: "square.grid.3x3.fill", color: .itoMint))
                )

                controlsPanel

                if let grid, let baseAnalysis {
                    heatmapPanel(grid: grid, basePrice: baseAnalysis.price)
                    if let selection {
                        selectionPanel(selection, grid: grid, basePrice: baseAnalysis.price)
                    }
                } else {
                    AppEmptyState(
                        symbol: "exclamationmark.magnifyingglass",
                        title: "Scenario matrix unavailable",
                        message: gridErrorMessage
                    )
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding(28)
            .frame(maxWidth: 1320, alignment: .leading)
        }
        .onChange(of: model.workspace.scenarios) { _, _ in selection = nil }
        .onChange(of: model.workspace.pricer) { _, _ in selection = nil }
    }

    private var controlsPanel: some View {
        Panel(title: "Shock parameters", subtitle: "Shocks are symmetric around the current contract inputs") {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 28) {
                    scenarioSlider(
                        title: "Spot range",
                        detail: "±\(model.workspace.scenarios.spotRangePercent.formatted(.number.precision(.fractionLength(0))))%",
                        value: $model.workspace.scenarios.spotRangePercent,
                        range: 5...50,
                        step: 5,
                        accessibility: "Spot shock range"
                    )
                    scenarioSlider(
                        title: "Volatility range",
                        detail: "±\(model.workspace.scenarios.volatilityRangePoints.formatted(.number.precision(.fractionLength(0)))) pts",
                        value: $model.workspace.scenarios.volatilityRangePoints,
                        range: 5...50,
                        step: 5,
                        accessibility: "Volatility shock range"
                    )
                    stepControl
                }
                VStack(alignment: .leading, spacing: 18) {
                    scenarioSlider(
                        title: "Spot range",
                        detail: "±\(model.workspace.scenarios.spotRangePercent.formatted(.number.precision(.fractionLength(0))))%",
                        value: $model.workspace.scenarios.spotRangePercent,
                        range: 5...50,
                        step: 5,
                        accessibility: "Spot shock range"
                    )
                    scenarioSlider(
                        title: "Volatility range",
                        detail: "±\(model.workspace.scenarios.volatilityRangePoints.formatted(.number.precision(.fractionLength(0)))) pts",
                        value: $model.workspace.scenarios.volatilityRangePoints,
                        range: 5...50,
                        step: 5,
                        accessibility: "Volatility shock range"
                    )
                    stepControl
                }
            }
        }
    }

    private func scenarioSlider(
        title: String,
        detail: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        accessibility: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.subheadline.weight(.medium))
                Spacer()
                Text(detail)
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(Color.itoAccent)
            }
            Slider(value: value, in: range, step: step)
                .tint(.itoAccent)
                .accessibilityLabel(accessibility)
                .accessibilityValue(detail)
                .help("Adjust \(title.lowercased())")
        }
        .frame(maxWidth: 300)
    }

    private var stepControl: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Grid resolution")
                .font(.subheadline.weight(.medium))
            Stepper(
                "\(model.workspace.scenarios.steps) levels per axis",
                value: $model.workspace.scenarios.steps,
                in: 5...15,
                step: 2
            )
            .monospacedDigit()
            .accessibilityLabel("Grid resolution")
            .accessibilityValue("\(model.workspace.scenarios.steps) levels per axis")
            .help("Use an odd grid size so the base case remains centered")
        }
        .frame(minWidth: 170, maxWidth: 220)
    }

    private func heatmapPanel(grid: [[Double]], basePrice: Double) -> some View {
        Panel(title: "Theoretical value heatmap", subtitle: "Rows shock spot; columns shock annualized volatility") {
            HStack(spacing: 18) {
                Label("Value increase", systemImage: "square.fill")
                    .foregroundStyle(Color.itoMint)
                Label("Value decrease", systemImage: "square.fill")
                    .foregroundStyle(Color.itoRose)
                Label("Near base", systemImage: "square.fill")
                    .foregroundStyle(Color.secondary.opacity(0.5))
            }
            .font(.caption)
            .accessibilityElement(children: .combine)

            ScrollView(.horizontal) {
                Grid(horizontalSpacing: 5, verticalSpacing: 5) {
                    GridRow {
                        Text("SPOT / IV")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 72, height: 38)
                        ForEach(Array(volatilityChanges.enumerated()), id: \.offset) { _, change in
                            Text((change * 100).formatted(.number.precision(.fractionLength(0...1)).sign(strategy: .always())) + " pts")
                                .font(.caption2.weight(.semibold))
                                .monospacedDigit()
                                .frame(width: 76)
                                .accessibilityLabel("Volatility change \(change.formatted(.percent))")
                        }
                    }

                    ForEach(Array(spotChanges.enumerated()), id: \.offset) { spotIndex, spotChange in
                        GridRow {
                            Text(spotChange.formatted(.percent.precision(.fractionLength(0...1)).sign(strategy: .always())))
                                .font(.caption.weight(.semibold))
                                .monospacedDigit()
                                .foregroundStyle(spotChange == 0 ? Color.itoAccent : .secondary)
                                .frame(width: 72)
                                .accessibilityLabel("Spot change \(spotChange.formatted(.percent))")

                            ForEach(Array(volatilityChanges.enumerated()), id: \.offset) { volatilityIndex, volatilityChange in
                                let price = grid[spotIndex][volatilityIndex]
                                heatmapCell(
                                    price: price,
                                    basePrice: basePrice,
                                    spotChange: spotChange,
                                    volatilityChange: volatilityChange,
                                    isSelected: selection == ScenarioSelection(spotIndex: spotIndex, volatilityIndex: volatilityIndex)
                                ) {
                                    selection = ScenarioSelection(spotIndex: spotIndex, volatilityIndex: volatilityIndex)
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 4)
            }
        }
    }

    private func heatmapCell(
        price: Double,
        basePrice: Double,
        spotChange: Double,
        volatilityChange: Double,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        let difference = price - basePrice
        let normalized = min(abs(difference) / max(basePrice, 1), 1)
        let tint: Color = difference > 0.005 ? .itoMint : (difference < -0.005 ? .itoRose : .secondary)

        return Button(action: action) {
            VStack(spacing: 3) {
                Text(price.currencyText)
                    .font(.caption.monospacedDigit().weight(.semibold))
                Text(difference.signedCurrencyText)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .frame(width: 76, height: 48)
            .background(tint.opacity(0.08 + normalized * 0.25), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(isSelected ? Color.itoAccent : tint.opacity(0.20), lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
        .help("Spot \(spotChange.formatted(.percent)), volatility \((volatilityChange * 100).formatted(.number.sign(strategy: .always()))) points: \(price.currencyText)")
        .accessibilityLabel("Spot change \(spotChange.formatted(.percent)), volatility change \((volatilityChange * 100).formatted()) percentage points, option value \(price.currencyText), change \(difference.signedCurrencyText)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func selectionPanel(_ selection: ScenarioSelection, grid: [[Double]], basePrice: Double) -> some View {
        let spotChange = spotChanges[selection.spotIndex]
        let volatilityChange = volatilityChanges[selection.volatilityIndex]
        let shockedSpot = model.workspace.pricer.spot * (1 + spotChange)
        let shockedVolatility = model.workspace.pricer.volatilityPercent + volatilityChange * 100
        let price = grid[selection.spotIndex][selection.volatilityIndex]

        return Panel(title: "Selected scenario", subtitle: "Compared with the current contract value") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 12)], spacing: 12) {
                MetricCard(title: "Shocked Spot", value: shockedSpot.currencyText, detail: spotChange.formatted(.percent.precision(.fractionLength(1)).sign(strategy: .always())), symbol: "arrow.up.and.down", tint: .itoAccent)
                MetricCard(title: "Shocked Volatility", value: shockedVolatility.formatted(.number.precision(.fractionLength(1))) + "%", detail: (volatilityChange * 100).formatted(.number.precision(.fractionLength(1)).sign(strategy: .always())) + " vol pts", symbol: "waveform.path.ecg", tint: .itoIndigo)
                MetricCard(title: "Option Value", value: price.currencyText, detail: "Scenario premium", symbol: "dollarsign.circle.fill", tint: .itoMint)
                MetricCard(title: "Value Change", value: (price - basePrice).signedCurrencyText, detail: ((price - basePrice) / max(basePrice, 0.0001)).formatted(.percent.precision(.fractionLength(1)).sign(strategy: .always())), symbol: "chart.line.uptrend.xyaxis", tint: price >= basePrice ? .itoMint : .itoRose)
            }
        }
    }

    private func axisValues(range: Double) -> [Double] {
        let count = max(model.workspace.scenarios.steps, 3)
        return (0..<count).map { index in
            -range + 2 * range * Double(index) / Double(count - 1)
        }
    }

    private var gridErrorMessage: String {
        do {
            _ = try gridResult.get()
            return "The scenario grid could not be generated."
        } catch {
            return error.localizedDescription
        }
    }
}
