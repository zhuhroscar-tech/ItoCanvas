import Foundation
import SwiftUI
import ItoCanvasCore

enum AppSection: String, CaseIterable, Identifiable {
    case overview
    case pricer
    case strategy
    case scenarios
    case guide

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: "Overview"
        case .pricer: "Options Pricer"
        case .strategy: "Strategy Studio"
        case .scenarios: "Scenario Lab"
        case .guide: "Model & Privacy"
        }
    }

    var subtitle: String {
        switch self {
        case .overview: "Workspace pulse"
        case .pricer: "Price and Greeks"
        case .strategy: "Expiration payoff"
        case .scenarios: "Spot × volatility"
        case .guide: "Assumptions and terms"
        }
    }

    var symbol: String {
        switch self {
        case .overview: "square.grid.2x2"
        case .pricer: "function"
        case .strategy: "point.3.connected.trianglepath.dotted"
        case .scenarios: "square.grid.3x3.square"
        case .guide: "shield.checkered"
        }
    }
}

enum AppearancePreference: String, Codable, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum StrategyPreset: String, Codable, CaseIterable, Identifiable {
    case longCall
    case protectivePut
    case bullCallSpread
    case straddle
    case ironCondor

    var id: String { rawValue }

    var title: String {
        switch self {
        case .longCall: "Long Call"
        case .protectivePut: "Protective Put"
        case .bullCallSpread: "Bull Call Spread"
        case .straddle: "Long Straddle"
        case .ironCondor: "Iron Condor"
        }
    }

    var summary: String {
        switch self {
        case .longCall: "Defined downside with uncapped upside participation."
        case .protectivePut: "Long underlying with a put floor beneath the position."
        case .bullCallSpread: "Defined-risk bullish exposure financed by a short call."
        case .straddle: "Long volatility exposure in either direction."
        case .ironCondor: "Defined-risk premium collection inside a price range."
        }
    }
}

struct PricerWorkspace: Codable, Equatable {
    var type: OptionType = .call
    var spot: Double = 100
    var strike: Double = 100
    var daysToExpiry: Double = 180
    var riskFreeRatePercent: Double = 4.25
    var volatilityPercent: Double = 25
    var dividendYieldPercent: Double = 0
    var marketPrice: Double = 9.75

    var contract: OptionContract {
        OptionContract(
            type: type,
            spot: spot,
            strike: strike,
            timeToExpiry: daysToExpiry / 365,
            riskFreeRate: riskFreeRatePercent / 100,
            volatility: volatilityPercent / 100,
            dividendYield: dividendYieldPercent / 100
        )
    }

    var validationMessages: [String] {
        var messages: [String] = []
        if !spot.isFinite || spot <= 0 { messages.append("Spot must be greater than zero.") }
        if !strike.isFinite || strike <= 0 { messages.append("Strike must be greater than zero.") }
        if !daysToExpiry.isFinite || daysToExpiry < 0 { messages.append("Days to expiry cannot be negative.") }
        if !riskFreeRatePercent.isFinite || abs(riskFreeRatePercent) > 100 { messages.append("Rate must be between −100% and 100%.") }
        if !volatilityPercent.isFinite || volatilityPercent < 0 || volatilityPercent > 1_000 { messages.append("Volatility must be between 0% and 1,000%.") }
        if !dividendYieldPercent.isFinite || abs(dividendYieldPercent) > 100 { messages.append("Dividend yield must be between −100% and 100%.") }
        return messages
    }
}

struct EditableOptionLeg: Codable, Identifiable, Equatable {
    var id = UUID()
    var side: PositionSide
    var type: OptionType
    var strike: Double
    var premium: Double
    var quantity: Int

    var coreLeg: OptionLeg {
        OptionLeg(type: type, strike: strike, premium: premium, quantity: max(quantity, 0), side: side)
    }

    var isValid: Bool {
        strike.isFinite && strike > 0 && premium.isFinite && premium >= 0 && quantity > 0
    }
}

struct StrategyWorkspace: Codable, Equatable {
    var name = StrategyPreset.bullCallSpread.title
    var selectedPreset: StrategyPreset? = .bullCallSpread
    var legs: [EditableOptionLeg] = []
    var underlyingQuantity = 0
    var underlyingEntryPrice: Double = 100
    var chartLowerSpot: Double = 60
    var chartUpperSpot: Double = 140

    var optionStrategy: OptionStrategy {
        OptionStrategy(
            name: name,
            legs: legs.map(\.coreLeg),
            underlyingQuantity: Double(underlyingQuantity),
            underlyingEntryPrice: underlyingEntryPrice
        )
    }

    var validationMessages: [String] {
        var messages: [String] = []
        if legs.isEmpty && underlyingQuantity == 0 { messages.append("Add at least one option leg or an underlying position.") }
        if legs.contains(where: { !$0.isValid }) { messages.append("Each leg needs a positive strike, non-negative premium, and quantity of at least one.") }
        if !underlyingEntryPrice.isFinite || underlyingEntryPrice <= 0 { messages.append("Underlying entry price must be greater than zero.") }
        if !chartLowerSpot.isFinite || !chartUpperSpot.isFinite || chartLowerSpot < 0 || chartUpperSpot <= chartLowerSpot {
            messages.append("Chart bounds must be valid and ordered.")
        }
        return messages
    }
}

struct ScenarioWorkspace: Codable, Equatable {
    var spotRangePercent: Double = 20
    var volatilityRangePoints: Double = 10
    var steps: Int = 9
}

struct WorkspaceState: Codable, Equatable {
    var pricer = PricerWorkspace()
    var strategy = StrategyWorkspace()
    var scenarios = ScenarioWorkspace()
    var appearance: AppearancePreference = .system
    var lastSavedAt = Date()
}

@MainActor
final class AppModel: ObservableObject {
    @Published var selectedSection: AppSection = .overview
    @Published var workspace: WorkspaceState {
        didSet { persistWorkspace() }
    }

    private let defaults: UserDefaults
    private static let persistenceKey = "ItoCanvas.workspace.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.persistenceKey),
           let decoded = try? JSONDecoder().decode(WorkspaceState.self, from: data) {
            workspace = decoded
        } else {
            workspace = WorkspaceState()
            applyPreset(.bullCallSpread, persist: false)
        }
    }

    var analysis: Result<OptionAnalysis, Error> {
        guard workspace.pricer.validationMessages.isEmpty else {
            return .failure(WorkspaceValidationError(messages: workspace.pricer.validationMessages))
        }
        return Result { try BlackScholes.analyze(workspace.pricer.contract) }
    }

    func navigate(to section: AppSection) {
        selectedSection = section
    }

    func applyPreset(_ preset: StrategyPreset, persist: Bool = true) {
        let inputs = workspace.pricer
        let spot = max(inputs.spot, 1)
        let lower = roundedStrike(spot * 0.9)
        let upper = roundedStrike(spot * 1.1)
        let outerLower = roundedStrike(spot * 0.8)
        let outerUpper = roundedStrike(spot * 1.2)
        let atTheMoney = roundedStrike(spot)

        func leg(_ side: PositionSide, _ type: OptionType, _ strike: Double) -> EditableOptionLeg {
            EditableOptionLeg(
                side: side,
                type: type,
                strike: strike,
                premium: theoreticalPremium(type: type, strike: strike),
                quantity: 1
            )
        }

        workspace.strategy.name = preset.title
        workspace.strategy.selectedPreset = preset
        workspace.strategy.underlyingEntryPrice = spot
        workspace.strategy.chartLowerSpot = max(0, spot * 0.55)
        workspace.strategy.chartUpperSpot = spot * 1.45

        switch preset {
        case .longCall:
            workspace.strategy.underlyingQuantity = 0
            workspace.strategy.legs = [leg(.long, .call, atTheMoney)]
        case .protectivePut:
            workspace.strategy.underlyingQuantity = 1
            workspace.strategy.legs = [leg(.long, .put, lower)]
        case .bullCallSpread:
            workspace.strategy.underlyingQuantity = 0
            workspace.strategy.legs = [leg(.long, .call, lower), leg(.short, .call, upper)]
        case .straddle:
            workspace.strategy.underlyingQuantity = 0
            workspace.strategy.legs = [leg(.long, .call, atTheMoney), leg(.long, .put, atTheMoney)]
        case .ironCondor:
            workspace.strategy.underlyingQuantity = 0
            workspace.strategy.legs = [
                leg(.long, .put, outerLower),
                leg(.short, .put, lower),
                leg(.short, .call, upper),
                leg(.long, .call, outerUpper)
            ]
        }

        if persist { persistWorkspace() }
    }

    func addLeg() {
        let strike = roundedStrike(max(workspace.pricer.spot, 1))
        workspace.strategy.selectedPreset = nil
        workspace.strategy.name = "Custom Strategy"
        workspace.strategy.legs.append(
            EditableOptionLeg(side: .long, type: .call, strike: strike, premium: theoreticalPremium(type: .call, strike: strike), quantity: 1)
        )
    }

    func removeLeg(id: UUID) {
        workspace.strategy.selectedPreset = nil
        workspace.strategy.name = "Custom Strategy"
        workspace.strategy.legs.removeAll { $0.id == id }
    }

    func strategyProfit(at spot: Double) -> Double {
        guard workspace.strategy.validationMessages.isEmpty else { return .nan }
        return workspace.strategy.optionStrategy.profit(atExpirationSpot: spot)
    }

    func resetWorkspace() {
        workspace = WorkspaceState()
        applyPreset(.bullCallSpread)
        selectedSection = .overview
    }

    private func theoreticalPremium(type: OptionType, strike: Double) -> Double {
        var contract = workspace.pricer.contract
        contract.type = type
        contract.strike = strike
        return (try? BlackScholes.analyze(contract).price) ?? 0
    }

    private func roundedStrike(_ value: Double) -> Double {
        max((value / 5).rounded() * 5, 1)
    }

    private func persistWorkspace() {
        var copy = workspace
        copy.lastSavedAt = Date()
        guard let encoded = try? JSONEncoder().encode(copy) else { return }
        defaults.set(encoded, forKey: Self.persistenceKey)
    }
}

struct WorkspaceValidationError: LocalizedError {
    let messages: [String]
    var errorDescription: String? { messages.joined(separator: " ") }
}

extension ItoCanvasError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .nonFiniteInput(let field): "\(field.capitalized) must be a finite number."
        case .nonPositiveSpot: "Spot must be greater than zero."
        case .nonPositiveStrike: "Strike must be greater than zero."
        case .negativeTimeToExpiry: "Time to expiry cannot be negative."
        case .negativeVolatility: "Volatility cannot be negative."
        case .invalidMarketPrice: "Market price must be a non-negative number."
        case .marketPriceOutsideArbitrageBounds(let lower, let upper):
            "Market price must be between \(lower.formatted(.number.precision(.fractionLength(2)))) and \(upper.formatted(.number.precision(.fractionLength(2))))."
        case .impliedVolatilityUndefinedAtExpiry: "Implied volatility is undefined at expiry."
        case .impliedVolatilityDidNotConverge: "The solver did not converge for this market price."
        case .invalidScenario: "The selected scenario produces an invalid spot or volatility."
        }
    }
}
