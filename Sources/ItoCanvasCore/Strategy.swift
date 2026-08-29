import Foundation

public enum PositionSide: String, Codable, Sendable, CaseIterable {
    case long
    case short
}

public struct OptionLeg: Codable, Sendable, Equatable {
    public var type: OptionType
    public var strike: Double
    public var premium: Double
    public var quantity: Int
    public var side: PositionSide

    public init(type: OptionType, strike: Double, premium: Double, quantity: Int, side: PositionSide) {
        self.type = type
        self.strike = strike
        self.premium = premium
        self.quantity = quantity
        self.side = side
    }

    public func profit(atExpirationSpot spot: Double) -> Double {
        guard spot.isFinite, strike.isFinite, premium.isFinite, strike >= 0, quantity >= 0 else {
            return .nan
        }
        let intrinsic: Double
        switch type {
        case .call: intrinsic = max(spot - strike, 0)
        case .put: intrinsic = max(strike - spot, 0)
        }
        let longProfit = intrinsic - premium
        let direction = side == .long ? 1.0 : -1.0
        return direction * Double(quantity) * longProfit
    }
}

public struct OptionStrategy: Codable, Sendable, Equatable {
    public var name: String
    public var legs: [OptionLeg]
    public var underlyingQuantity: Double
    public var underlyingEntryPrice: Double

    public init(
        name: String,
        legs: [OptionLeg],
        underlyingQuantity: Double = 0,
        underlyingEntryPrice: Double = 0
    ) {
        self.name = name
        self.legs = legs
        self.underlyingQuantity = underlyingQuantity
        self.underlyingEntryPrice = underlyingEntryPrice
    }

    public func profit(atExpirationSpot spot: Double) -> Double {
        guard spot.isFinite, underlyingQuantity.isFinite, underlyingEntryPrice.isFinite else { return .nan }
        let underlyingProfit = underlyingQuantity * (spot - underlyingEntryPrice)
        return legs.reduce(underlyingProfit) { $0 + $1.profit(atExpirationSpot: spot) }
    }

    public func breakevens(from lowerBound: Double, through upperBound: Double, step: Double) -> [Double] {
        guard lowerBound.isFinite, upperBound.isFinite, step.isFinite,
              step > 0, lowerBound <= upperBound else { return [] }

        let zeroTolerance = 1e-10
        let deduplicationTolerance = max(step * 1e-7, 1e-10)
        var points = [lowerBound, upperBound]
        points.append(contentsOf: legs.map(\.strike).filter { $0 > lowerBound && $0 < upperBound })
        points.sort()

        var uniquePoints: [Double] = []
        for point in points where point.isFinite {
            if let previous = uniquePoints.last, abs(previous - point) <= deduplicationTolerance { continue }
            uniquePoints.append(point)
        }

        let profits = uniquePoints.map(profit(atExpirationSpot:))
        guard profits.allSatisfy(\.isFinite) else { return [] }

        var roots: [Double] = []
        func appendRoot(_ value: Double) {
            guard value.isFinite else { return }
            if let previous = roots.last, abs(previous - value) <= deduplicationTolerance { return }
            roots.append(value)
        }

        for index in uniquePoints.indices {
            let point = uniquePoints[index]
            let pointProfit = profits[index]
            if abs(pointProfit) <= zeroTolerance { appendRoot(point) }

            guard index + 1 < uniquePoints.count else { continue }
            let nextPoint = uniquePoints[index + 1]
            let nextProfit = profits[index + 1]
            if pointProfit * nextProfit < 0 {
                let root = point - pointProfit * (nextPoint - point) / (nextProfit - pointProfit)
                appendRoot(root)
            }
        }
        return roots
    }
}

public enum ScenarioEngine {
    public static func priceGrid(
        contract: OptionContract,
        spotChanges: [Double],
        volatilityChanges: [Double]
    ) throws -> [[Double]] {
        guard spotChanges.allSatisfy(\.isFinite), volatilityChanges.allSatisfy(\.isFinite) else {
            throw ItoCanvasError.invalidScenario
        }

        return try spotChanges.map { spotChange in
            try volatilityChanges.map { volatilityChange in
                var scenario = contract
                scenario.spot = contract.spot * (1 + spotChange)
                scenario.volatility = contract.volatility + volatilityChange
                guard scenario.spot > 0, scenario.spot.isFinite,
                      scenario.volatility >= 0, scenario.volatility.isFinite else {
                    throw ItoCanvasError.invalidScenario
                }
                return try BlackScholes.analyze(scenario).price
            }
        }
    }
}
