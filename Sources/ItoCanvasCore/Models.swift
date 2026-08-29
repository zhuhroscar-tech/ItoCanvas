import Foundation

public enum OptionType: String, Codable, Sendable, CaseIterable {
    case call
    case put
}

public struct OptionContract: Codable, Sendable, Equatable {
    public var type: OptionType
    public var spot: Double
    public var strike: Double
    public var timeToExpiry: Double
    public var riskFreeRate: Double
    public var volatility: Double
    public var dividendYield: Double

    public init(
        type: OptionType,
        spot: Double,
        strike: Double,
        timeToExpiry: Double,
        riskFreeRate: Double,
        volatility: Double,
        dividendYield: Double
    ) {
        self.type = type
        self.spot = spot
        self.strike = strike
        self.timeToExpiry = timeToExpiry
        self.riskFreeRate = riskFreeRate
        self.volatility = volatility
        self.dividendYield = dividendYield
    }
}

public struct OptionAnalysis: Codable, Sendable, Equatable {
    public let price: Double
    public let delta: Double
    public let gamma: Double
    public let vega: Double
    public let theta: Double
    public let rho: Double

    public init(price: Double, delta: Double, gamma: Double, vega: Double, theta: Double, rho: Double) {
        self.price = price
        self.delta = delta
        self.gamma = gamma
        self.vega = vega
        self.theta = theta
        self.rho = rho
    }
}

public enum ItoCanvasError: Error, Sendable, Equatable {
    case nonFiniteInput(String)
    case nonPositiveSpot
    case nonPositiveStrike
    case negativeTimeToExpiry
    case negativeVolatility
    case invalidMarketPrice
    case marketPriceOutsideArbitrageBounds(lower: Double, upper: Double)
    case impliedVolatilityUndefinedAtExpiry
    case impliedVolatilityDidNotConverge
    case invalidScenario
}
