import SwiftUI
import Charts
import AppKit
import UniformTypeIdentifiers
import ItoCanvasCore

private struct PayoffPoint: Identifiable {
    let spot: Double
    let profit: Double
    var id: Double { spot }
}

private struct StrategyRiskSummary {
    let breakevens: [Double]
    let maximumGain: String
    let maximumLoss: String
    let netPremium: Double
}

struct StrategyView: View {
    @EnvironmentObject private var model: AppModel
    @State private var exportMessage: String?

    private var payoffPoints: [PayoffPoint] {
        let strategy = model.workspace.strategy
        guard strategy.validationMessages.isEmpty else { return [] }
        return (0...200).map { index in
            let spot = strategy.chartLowerSpot
                + (strategy.chartUpperSpot - strategy.chartLowerSpot) * Double(index) / 200
            return PayoffPoint(spot: spot, profit: model.strategyProfit(at: spot))
        }
    }

    private var riskSummary: StrategyRiskSummary {
        let strategy = model.workspace.strategy
        let legs = strategy.legs
        let netPremium = legs.reduce(0.0) { partial, leg in
            let direction = leg.side == .long ? 1.0 : -1.0
            return partial + direction * leg.premium * Double(leg.quantity)
        }

        let step = max((strategy.chartUpperSpot - strategy.chartLowerSpot) / 1_000, 0.01)
        let breakevens = strategy.optionStrategy.breakevens(
            from: strategy.chartLowerSpot,
            through: strategy.chartUpperSpot,
            step: step
        )

        let knots = ([0.0] + legs.map(\.strike)).sorted()
        let knotProfits = knots.map { model.strategyProfit(at: $0) }
        let finiteMaximum = knotProfits.max() ?? 0
        let finiteMinimum = knotProfits.min() ?? 0
        let tailSlope = Double(strategy.underlyingQuantity) + legs.reduce(0.0) { partial, leg in
            guard leg.type == .call else { return partial }
            let direction = leg.side == .long ? 1.0 : -1.0
            return partial + direction * Double(leg.quantity)
        }

        return StrategyRiskSummary(
            breakevens: breakevens,
            maximumGain: tailSlope > 0.000_001 ? "Unlimited" : finiteMaximum.signedCurrencyText,
            maximumLoss: tailSlope < -0.000_001 ? "Unlimited" : abs(min(finiteMinimum, 0)).currencyText,
            netPremium: netPremium
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PageHeader(
                    eyebrow: "Expiration analysis",
                    title: "Strategy Studio",
                    subtitle: "Start from a market-standard structure, tune every leg, and understand the payoff before committing capital.",
                    trailing: AnyView(
                        Button {
                            exportCSV()
                        } label: {
                            Label("Export CSV", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.bordered)
                        .keyboardShortcut("e", modifiers: [.command, .shift])
                        .disabled(payoffPoints.isEmpty)
                        .help("Export payoff data as CSV (⇧⌘E)")
                        .accessibilityLabel("Export strategy payoff as CSV")
                    )
                )

                presetPanel
                legEditorPanel

                if !model.workspace.strategy.validationMessages.isEmpty {
                    ValidationBanner(title: "Strategy needs attention", messages: model.workspace.strategy.validationMessages)
                }

                if model.workspace.strategy.validationMessages.isEmpty {
                    summaryCards
                }
                payoffChartPanel

                if let exportMessage {
                    Label(exportMessage, systemImage: exportMessage.hasPrefix("Exported") ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(exportMessage.hasPrefix("Exported") ? Color.itoMint : Color.orange)
                        .accessibilityElement(children: .combine)
                }
            }
            .padding(28)
            .frame(maxWidth: 1340, alignment: .leading)
        }
    }

    private var presetPanel: some View {
        Panel(title: "Strategy presets", subtitle: "Premiums are initialized from the active pricer inputs") {
            FlowLayout(spacing: 8) {
                ForEach(StrategyPreset.allCases) { preset in
                    Button {
                        model.applyPreset(preset)
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: presetSymbol(preset))
                            Text(preset.title)
                        }
                        .padding(.horizontal, 3)
                    }
                    .buttonStyle(.bordered)
                    .tint(model.workspace.strategy.selectedPreset == preset ? .itoAccent : .secondary)
                    .controlSize(.large)
                    .help(preset.summary)
                    .accessibilityLabel("Apply \(preset.title) preset. \(preset.summary)")
                }
            }

            if let preset = model.workspace.strategy.selectedPreset {
                HStack(alignment: .top, spacing: 9) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(Color.itoAccent)
                    Text(preset.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var legEditorPanel: some View {
        Panel(title: "Position legs", subtitle: "Values are per share; quantities are contract-equivalent units") {
            HStack(spacing: 12) {
                TextField("Strategy name", text: $model.workspace.strategy.name)
                    .textFieldStyle(.roundedBorder)
                    .font(.headline)
                    .accessibilityLabel("Strategy name")
                    .help("Give this strategy a descriptive name")
                Spacer()
                Button {
                    model.addLeg()
                } label: {
                    Label("Add option leg", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .help("Add a long call at the current spot")
                .accessibilityLabel("Add option leg")
            }

            if model.workspace.strategy.legs.isEmpty {
                AppEmptyState(
                    symbol: "point.3.filled.connected.trianglepath.dotted",
                    title: "No option legs",
                    message: "Add a leg or choose a preset to build an expiration payoff.",
                    actionTitle: "Add first leg",
                    action: { model.addLeg() }
                )
            } else {
                ScrollView(.horizontal) {
                    VStack(spacing: 7) {
                        legHeader
                        ForEach($model.workspace.strategy.legs) { $leg in
                            strategyLegRow(leg: $leg)
                        }
                    }
                    .frame(minWidth: 790)
                }
            }

            Divider()
            HStack(spacing: 14) {
                Label("Underlying", systemImage: "building.columns.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 108, alignment: .leading)
                Stepper(
                    "Quantity: \(model.workspace.strategy.underlyingQuantity)",
                    value: $model.workspace.strategy.underlyingQuantity,
                    in: -100...100
                )
                .frame(width: 150)
                .help("Add long or short underlying exposure")
                .accessibilityLabel("Underlying quantity")
                LabeledNumberField(
                    title: "Entry price",
                    value: $model.workspace.strategy.underlyingEntryPrice,
                    suffix: "USD",
                    help: "Cost basis for underlying exposure",
                    validation: { $0 > 0 && $0.isFinite ? nil : "Enter a positive entry price." }
                )
                .frame(maxWidth: 190)
                Spacer()
            }

            HStack(spacing: 14) {
                LabeledNumberField(
                    title: "Chart from",
                    value: $model.workspace.strategy.chartLowerSpot,
                    suffix: "USD",
                    help: "Lowest displayed expiration spot",
                    validation: { $0 >= 0 && $0.isFinite ? nil : "Use zero or greater." }
                )
                LabeledNumberField(
                    title: "Chart through",
                    value: $model.workspace.strategy.chartUpperSpot,
                    suffix: "USD",
                    help: "Highest displayed expiration spot",
                    validation: { $0 > model.workspace.strategy.chartLowerSpot && $0.isFinite ? nil : "Must exceed the lower bound." }
                )
                Spacer()
            }
            .frame(maxWidth: 480)
        }
    }

    private var legHeader: some View {
        HStack(spacing: 8) {
            Text("Side").frame(width: 86, alignment: .leading)
            Text("Type").frame(width: 118, alignment: .leading)
            Text("Strike").frame(width: 150, alignment: .leading)
            Text("Premium").frame(width: 150, alignment: .leading)
            Text("Quantity").frame(width: 110, alignment: .leading)
            Text("Action").frame(width: 70, alignment: .trailing)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .accessibilityHidden(true)
    }

    private func strategyLegRow(leg: Binding<EditableOptionLeg>) -> some View {
        HStack(spacing: 8) {
            Picker("Side", selection: leg.side) {
                Text("Long").tag(PositionSide.long)
                Text("Short").tag(PositionSide.short)
            }
            .labelsHidden()
            .frame(width: 86)
            .help("Long pays premium; short receives premium")
            .accessibilityLabel("Position side")

            Picker("Type", selection: leg.type) {
                Text("Call").tag(OptionType.call)
                Text("Put").tag(OptionType.put)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 118)
            .accessibilityLabel("Option type")

            compactField("Strike", value: leg.strike, suffix: "$", width: 150)
            compactField("Premium", value: leg.premium, suffix: "$", width: 150)

            Stepper(value: leg.quantity, in: 1...1_000) {
                Text(leg.wrappedValue.quantity.formatted())
                    .monospacedDigit()
                    .frame(width: 38, alignment: .trailing)
            }
            .frame(width: 110)
            .help("Number of option units")
            .accessibilityLabel("Quantity for \(leg.wrappedValue.type.rawValue) leg")

            Button(role: .destructive) {
                model.removeLeg(id: leg.wrappedValue.id)
            } label: {
                Image(systemName: "trash")
                    .frame(width: 22)
            }
            .buttonStyle(.borderless)
            .frame(width: 70, alignment: .trailing)
            .help("Remove this option leg")
            .accessibilityLabel("Remove \(leg.wrappedValue.side.rawValue) \(leg.wrappedValue.type.rawValue) leg")
        }
        .padding(10)
        .background(.background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(leg.wrappedValue.isValid ? Color.primary.opacity(0.07) : Color.red.opacity(0.65), lineWidth: 1)
        }
    }

    private func compactField(_ title: String, value: Binding<Double>, suffix: String, width: CGFloat) -> some View {
        HStack(spacing: 5) {
            Text(suffix)
                .font(.caption)
                .foregroundStyle(.tertiary)
            TextField(title, value: value, format: .number.precision(.fractionLength(0...4)))
                .textFieldStyle(.plain)
                .monospacedDigit()
                .accessibilityLabel(title)
        }
        .padding(.horizontal, 8)
        .frame(width: width, height: 30)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 7))
        .overlay { RoundedRectangle(cornerRadius: 7).stroke(.primary.opacity(0.10)) }
    }

    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 185), spacing: 12)], spacing: 12) {
            MetricCard(
                title: "Breakeven" + (riskSummary.breakevens.count == 1 ? "" : "s"),
                value: riskSummary.breakevens.isEmpty ? "None in range" : riskSummary.breakevens.map(\.currencyText).joined(separator: "  ·  "),
                detail: "Expiration spot",
                symbol: "scope",
                tint: .itoAccent
            )
            MetricCard(title: "Maximum Gain", value: riskSummary.maximumGain, detail: "Per strategy unit", symbol: "arrow.up.right", tint: .itoMint)
            MetricCard(title: "Maximum Loss", value: riskSummary.maximumLoss, detail: "Per strategy unit", symbol: "arrow.down.right", tint: .itoRose)
            MetricCard(
                title: "Net Option Premium",
                value: riskSummary.netPremium.currencyText,
                detail: riskSummary.netPremium >= 0 ? "Debit paid" : "Credit received",
                symbol: "banknote.fill",
                tint: .itoAmber
            )
        }
    }

    private var payoffChartPanel: some View {
        Panel(title: "Expiration P&L", subtitle: "Profit and loss at expiry across the selected spot range") {
            if payoffPoints.isEmpty {
                AppEmptyState(
                    symbol: "chart.xyaxis.line",
                    title: "Payoff unavailable",
                    message: "Correct the strategy legs and chart bounds to render expiration P&L."
                )
            } else {
                Chart {
                    ForEach(payoffPoints) { point in
                        AreaMark(
                            x: .value("Expiration spot", point.spot),
                            yStart: .value("Break even", 0),
                            yEnd: .value("Profit", point.profit)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.itoAccent.opacity(0.18), Color.itoAccent.opacity(0.025)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        LineMark(
                            x: .value("Expiration spot", point.spot),
                            y: .value("Profit", point.profit)
                        )
                        .foregroundStyle(Color.itoAccent)
                        .lineStyle(StrokeStyle(lineWidth: 2.4, lineJoin: .round))
                    }

                    RuleMark(y: .value("Break even", 0))
                        .foregroundStyle(.secondary.opacity(0.65))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 4]))

                    ForEach(riskSummary.breakevens, id: \.self) { level in
                        RuleMark(x: .value("Breakeven", level))
                            .foregroundStyle(Color.itoMint.opacity(0.7))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                            .annotation(position: .top) {
                                Text("BE \(level.currencyText)")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(Color.itoMint)
                            }
                    }
                }
                .chartXAxisLabel("Underlying spot at expiration")
                .chartYAxisLabel("Profit / loss")
                .frame(minHeight: 330)
                .accessibilityLabel("Expiration profit and loss chart for \(model.workspace.strategy.name)")
            }
        }
    }


    private func presetSymbol(_ preset: StrategyPreset) -> String {
        switch preset {
        case .longCall: "arrow.up.right.circle"
        case .protectivePut: "shield.lefthalf.filled"
        case .bullCallSpread: "arrow.left.and.right.righttriangle.left.righttriangle.right"
        case .straddle: "arrow.up.left.and.arrow.up.right"
        case .ironCondor: "rectangle.compress.vertical"
        }
    }

    private func exportCSV() {
        guard !payoffPoints.isEmpty else { return }
        let panel = NSSavePanel()
        panel.title = "Export Expiration P&L"
        panel.nameFieldStringValue = sanitizedFilename(model.workspace.strategy.name) + "-payoff.csv"
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false

        guard panel.runModal() == .OK, let url = panel.url else { return }
        let csvFormat = FloatingPointFormatStyle<Double>.number
            .locale(Locale(identifier: "en_US_POSIX"))
            .grouping(.never)
            .precision(.fractionLength(6))
        var rows = ["expiration_spot,profit_loss"]
        rows.append(contentsOf: payoffPoints.map { point in
            "\(point.spot.formatted(csvFormat)),\(point.profit.formatted(csvFormat))"
        })
        do {
            try rows.joined(separator: "\n").appending("\n").write(to: url, atomically: true, encoding: .utf8)
            exportMessage = "Exported \(payoffPoints.count) payoff rows to \(url.lastPathComponent)."
        } catch {
            exportMessage = "Export failed: \(error.localizedDescription)"
        }
    }

    private func sanitizedFilename(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let mapped = value.replacingOccurrences(of: " ", with: "-")
            .unicodeScalars
            .map { allowed.contains($0) ? Character(String($0)) : "-" }
        let result = String(mapped)
        return result.isEmpty ? "strategy" : result
    }
}
