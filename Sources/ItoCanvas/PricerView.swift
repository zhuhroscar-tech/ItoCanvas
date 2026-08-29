import SwiftUI
import Charts
import ItoCanvasCore

private struct PriceCurvePoint: Identifiable {
    let spot: Double
    let price: Double
    var id: Double { spot }
}

struct PricerView: View {
    @EnvironmentObject private var model: AppModel
    @State private var impliedVolatility: Double?
    @State private var solverMessage: String?
    @State private var hoveredSpot: Double?

    private var analysis: OptionAnalysis? {
        try? model.analysis.get()
    }

    private var analysisError: String? {
        do {
            _ = try model.analysis.get()
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    private var curve: [PriceCurvePoint] {
        let inputs = model.workspace.pricer
        guard inputs.validationMessages.isEmpty else { return [] }
        let center = inputs.spot
        let lower = max(0.01, min(center, inputs.strike) * 0.50)
        let upper = max(center, inputs.strike) * 1.50
        return (0...80).compactMap { index in
            let spot = lower + (upper - lower) * Double(index) / 80
            var contract = inputs.contract
            contract.spot = spot
            guard let price = try? BlackScholes.analyze(contract).price else { return nil }
            return PriceCurvePoint(spot: spot, price: price)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PageHeader(
                    eyebrow: "Black–Scholes",
                    title: "Options Pricer",
                    subtitle: "Calibrate a European contract, inspect first- and second-order sensitivities, and reverse-solve market volatility.",
                    trailing: AnyView(StatusPill(text: "European", symbol: "globe.europe.africa.fill", color: .itoIndigo))
                )

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 16) {
                        inputPanel.frame(width: 340)
                        resultsPanel
                    }
                    VStack(spacing: 16) {
                        inputPanel
                        resultsPanel
                    }
                }

                priceCurvePanel
                impliedVolatilityPanel
            }
            .padding(28)
            .frame(maxWidth: 1280, alignment: .leading)
        }
        .onChange(of: model.workspace.pricer) { _, _ in
            impliedVolatility = nil
            solverMessage = nil
        }
    }

    private var inputPanel: some View {
        Panel(title: "Contract inputs", subtitle: "Rates, yield, and volatility are annualized") {
            Picker("Option type", selection: $model.workspace.pricer.type) {
                Text("Call").tag(OptionType.call)
                Text("Put").tag(OptionType.put)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .help("Choose a call or put option")
            .accessibilityLabel("Option type")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                LabeledNumberField(
                    title: "Spot",
                    value: $model.workspace.pricer.spot,
                    suffix: "USD",
                    help: "Current price of the underlying asset",
                    validation: { $0 > 0 && $0.isFinite ? nil : "Enter a value greater than zero." }
                )
                LabeledNumberField(
                    title: "Strike",
                    value: $model.workspace.pricer.strike,
                    suffix: "USD",
                    help: "Contract exercise price",
                    validation: { $0 > 0 && $0.isFinite ? nil : "Enter a value greater than zero." }
                )
                LabeledNumberField(
                    title: "Time",
                    value: $model.workspace.pricer.daysToExpiry,
                    suffix: "days",
                    help: "Calendar days until expiration",
                    validation: { $0 >= 0 && $0.isFinite ? nil : "Days cannot be negative." }
                )
                LabeledNumberField(
                    title: "Volatility",
                    value: $model.workspace.pricer.volatilityPercent,
                    suffix: "%",
                    help: "Annualized implied volatility",
                    validation: { $0 >= 0 && $0 <= 1_000 && $0.isFinite ? nil : "Use 0% to 1,000%." }
                )
                LabeledNumberField(
                    title: "Risk-free rate",
                    value: $model.workspace.pricer.riskFreeRatePercent,
                    suffix: "%",
                    help: "Continuously compounded annual risk-free rate",
                    validation: { abs($0) <= 100 && $0.isFinite ? nil : "Use −100% to 100%." }
                )
                LabeledNumberField(
                    title: "Dividend yield",
                    value: $model.workspace.pricer.dividendYieldPercent,
                    suffix: "%",
                    help: "Continuously compounded annual dividend yield",
                    validation: { abs($0) <= 100 && $0.isFinite ? nil : "Use −100% to 100%." }
                )
            }

            if !model.workspace.pricer.validationMessages.isEmpty {
                ValidationBanner(title: "Check contract inputs", messages: model.workspace.pricer.validationMessages)
            }
        }
    }

    private var resultsPanel: some View {
        Panel(title: "Valuation & Greeks", subtitle: "Per-share sensitivities from the current inputs") {
            if let analysis {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 10)], spacing: 10) {
                    MetricCard(title: "Fair Value", value: analysis.price.currencyText, detail: "Model premium", symbol: "dollarsign.circle.fill", tint: .itoAccent)
                    MetricCard(title: "Delta", value: analysis.delta.compactNumberText, detail: "Per $1 spot", symbol: "triangle.fill", tint: .itoIndigo)
                    MetricCard(title: "Gamma", value: analysis.gamma.compactNumberText, detail: "Delta curvature", symbol: "waveform.path", tint: .itoMint)
                    MetricCard(title: "Vega", value: (analysis.vega / 100).compactNumberText, detail: "Per +1 vol point", symbol: "wind", tint: .itoMint)
                    MetricCard(title: "Theta", value: (analysis.theta / 365).compactNumberText, detail: "Per calendar day", symbol: "clock.arrow.circlepath", tint: .itoRose)
                    MetricCard(title: "Rho", value: (analysis.rho / 100).compactNumberText, detail: "Per +1 rate point", symbol: "percent", tint: .itoAmber)
                }
            } else {
                AppEmptyState(
                    symbol: "exclamationmark.magnifyingglass",
                    title: "Valuation unavailable",
                    message: analysisError ?? "Review the contract inputs to calculate a value."
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var priceCurvePanel: some View {
        Panel(title: "Price curve", subtitle: "Drag across the chart to inspect theoretical value at another spot") {
            if curve.isEmpty {
                AppEmptyState(
                    symbol: "chart.xyaxis.line",
                    title: "No curve to display",
                    message: "Correct the contract inputs and the price curve will update automatically."
                )
            } else {
                Chart {
                    ForEach(curve) { point in
                        AreaMark(
                            x: .value("Spot", point.spot),
                            y: .value("Option value", point.price)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.itoAccent.opacity(0.20), Color.itoAccent.opacity(0.01)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Spot", point.spot),
                            y: .value("Option value", point.price)
                        )
                        .foregroundStyle(Color.itoAccent)
                        .lineStyle(StrokeStyle(lineWidth: 2.2))
                        .interpolationMethod(.catmullRom)
                    }

                    RuleMark(x: .value("Current spot", model.workspace.pricer.spot))
                        .foregroundStyle(.secondary.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .annotation(position: .top, alignment: .leading) {
                            Text("Current")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
                        }

                    if let selected = selectedCurvePoint {
                        RuleMark(x: .value("Selected spot", selected.spot))
                            .foregroundStyle(Color.itoIndigo.opacity(0.55))
                        PointMark(
                            x: .value("Selected spot", selected.spot),
                            y: .value("Selected value", selected.price)
                        )
                        .foregroundStyle(Color.itoIndigo)
                        .symbolSize(64)
                        .annotation(position: .top, spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(selected.spot.currencyText)
                                    .font(.caption.weight(.semibold))
                                Text(selected.price.currencyText + " value")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(7)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 7))
                        }
                    }
                }
                .chartXAxisLabel("Underlying spot")
                .chartYAxisLabel("Option value")
                .chartXSelection(value: $hoveredSpot)
                .frame(minHeight: 300)
                .accessibilityLabel("Interactive option price curve")
                .help("Click or drag over the curve to inspect a point")
            }
        }
    }

    private var selectedCurvePoint: PriceCurvePoint? {
        guard let hoveredSpot else { return nil }
        return curve.min { abs($0.spot - hoveredSpot) < abs($1.spot - hoveredSpot) }
    }

    private var impliedVolatilityPanel: some View {
        Panel(title: "Implied volatility", subtitle: "Reverse-solve volatility from an observed market premium") {
            HStack(alignment: .bottom, spacing: 14) {
                LabeledNumberField(
                    title: "Observed market price",
                    value: $model.workspace.pricer.marketPrice,
                    suffix: "USD",
                    help: "Current traded premium used by the implied-volatility solver",
                    validation: { $0 >= 0 && $0.isFinite ? nil : "Price cannot be negative." }
                )
                .frame(maxWidth: 260)

                Button {
                    solveImpliedVolatility()
                } label: {
                    Label("Solve IV", systemImage: "x.squareroot")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.return, modifiers: [.command, .shift])
                .disabled(!model.workspace.pricer.validationMessages.isEmpty || model.workspace.pricer.marketPrice < 0)
                .help("Solve implied volatility (⇧⌘↩)")
                .accessibilityLabel("Solve implied volatility")

                if let impliedVolatility {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Solved volatility")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text((impliedVolatility * 100).formatted(.number.precision(.fractionLength(2))) + "%")
                            .font(.title2.monospacedDigit().weight(.semibold))
                            .foregroundStyle(Color.itoMint)
                    }
                    Button("Use as input") {
                        model.workspace.pricer.volatilityPercent = impliedVolatility * 100
                    }
                    .buttonStyle(.bordered)
                    .help("Copy the solved volatility into contract inputs")
                }
                Spacer()
            }

            if let solverMessage {
                Label(solverMessage, systemImage: impliedVolatility == nil ? "xmark.octagon.fill" : "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(impliedVolatility == nil ? Color.red : Color.itoMint)
                    .accessibilityElement(children: .combine)
            }
        }
    }

    private func solveImpliedVolatility() {
        do {
            let solved = try BlackScholes.impliedVolatility(
                marketPrice: model.workspace.pricer.marketPrice,
                contract: model.workspace.pricer.contract
            )
            impliedVolatility = solved
            solverMessage = "Converged against no-arbitrage bounds."
        } catch {
            impliedVolatility = nil
            solverMessage = error.localizedDescription
        }
    }
}
