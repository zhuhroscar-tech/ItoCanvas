import Foundation

public enum BlackScholes {
    private static let inverseSqrtTwo = 1.0 / sqrt(2.0)
    private static let inverseSqrtTwoPi = 1.0 / sqrt(2.0 * Double.pi)

    /// Standard normal probability density function.
    public static func normalPDF(_ value: Double) -> Double {
        guard value.isFinite else { return value.isNaN ? .nan : 0 }
        return inverseSqrtTwoPi * exp(-0.5 * value * value)
    }

    /// Standard normal cumulative distribution function.
    public static func normalCDF(_ value: Double) -> Double {
        guard value.isFinite else {
            if value == .infinity { return 1 }
            if value == -.infinity { return 0 }
            return .nan
        }
        return 0.5 * erfc(-value * inverseSqrtTwo)
    }

    public static func analyze(_ contract: OptionContract) throws -> OptionAnalysis {
        try validate(contract)

        if contract.timeToExpiry == 0 {
            return expirationAnalysis(contract)
        }
        if contract.volatility == 0 {
            return deterministicAnalysis(contract)
        }

        let time = contract.timeToExpiry
        let sqrtTime = sqrt(time)
        let sigmaSqrtTime = contract.volatility * sqrtTime
        let discountRate = exp(-contract.riskFreeRate * time)
        let discountDividend = exp(-contract.dividendYield * time)
        let d1 = (
            log(contract.spot / contract.strike)
                + (contract.riskFreeRate - contract.dividendYield
                    + 0.5 * contract.volatility * contract.volatility) * time
        ) / sigmaSqrtTime
        let d2 = d1 - sigmaSqrtTime
        let density = normalPDF(d1)

        let price: Double
        let delta: Double
        let theta: Double
        let rho: Double

        switch contract.type {
        case .call:
            price = contract.spot * discountDividend * normalCDF(d1)
                - contract.strike * discountRate * normalCDF(d2)
            delta = discountDividend * normalCDF(d1)
            theta = -contract.spot * discountDividend * density * contract.volatility / (2 * sqrtTime)
                + contract.dividendYield * contract.spot * discountDividend * normalCDF(d1)
                - contract.riskFreeRate * contract.strike * discountRate * normalCDF(d2)
            rho = contract.strike * time * discountRate * normalCDF(d2)
        case .put:
            price = contract.strike * discountRate * normalCDF(-d2)
                - contract.spot * discountDividend * normalCDF(-d1)
            delta = discountDividend * (normalCDF(d1) - 1)
            theta = -contract.spot * discountDividend * density * contract.volatility / (2 * sqrtTime)
                - contract.dividendYield * contract.spot * discountDividend * normalCDF(-d1)
                + contract.riskFreeRate * contract.strike * discountRate * normalCDF(-d2)
            rho = -contract.strike * time * discountRate * normalCDF(-d2)
        }

        let gamma = discountDividend * density / (contract.spot * sigmaSqrtTime)
        let vega = contract.spot * discountDividend * density * sqrtTime
        let result = OptionAnalysis(price: price, delta: delta, gamma: gamma, vega: vega, theta: theta, rho: rho)
        guard result.price.isFinite, result.delta.isFinite, result.gamma.isFinite,
              result.vega.isFinite, result.theta.isFinite, result.rho.isFinite else {
            throw ItoCanvasError.nonFiniteInput("calculated result")
        }
        return result
    }

    public static func impliedVolatility(marketPrice: Double, contract: OptionContract) throws -> Double {
        try validate(contract)
        guard marketPrice.isFinite, marketPrice >= 0 else {
            throw ItoCanvasError.invalidMarketPrice
        }
        guard contract.timeToExpiry > 0 else {
            throw ItoCanvasError.impliedVolatilityUndefinedAtExpiry
        }

        let time = contract.timeToExpiry
        let discountedSpot = contract.spot * exp(-contract.dividendYield * time)
        let discountedStrike = contract.strike * exp(-contract.riskFreeRate * time)
        let lower: Double
        let upper: Double
        switch contract.type {
        case .call:
            lower = max(discountedSpot - discountedStrike, 0)
            upper = discountedSpot
        case .put:
            lower = max(discountedStrike - discountedSpot, 0)
            upper = discountedStrike
        }

        let boundsTolerance = 1e-12 * max(1, upper)
        guard marketPrice >= lower - boundsTolerance, marketPrice <= upper + boundsTolerance else {
            throw ItoCanvasError.marketPriceOutsideArbitrageBounds(lower: lower, upper: upper)
        }
        if abs(marketPrice - lower) <= boundsTolerance { return 0 }
        // The upper bound is approached only as volatility tends to infinity.
        guard marketPrice < upper - boundsTolerance else {
            throw ItoCanvasError.impliedVolatilityDidNotConverge
        }

        let maximumVolatility = 10.0
        var low = 0.0
        var high = min(max(contract.volatility * 2, 1), maximumVolatility)
        var highContract = contract
        highContract.volatility = high
        while try analyze(highContract).price < marketPrice, high < maximumVolatility {
            high = min(high * 2, maximumVolatility)
            highContract.volatility = high
        }
        guard try analyze(highContract).price >= marketPrice else {
            throw ItoCanvasError.impliedVolatilityDidNotConverge
        }

        var volatility = min(max(contract.volatility, 0.2), high)
        let priceTolerance = 1e-12 * max(1, marketPrice)

        for _ in 0..<100 {
            var trial = contract
            trial.volatility = volatility
            let analysis = try analyze(trial)
            let difference = analysis.price - marketPrice
            if abs(difference) <= priceTolerance {
                return volatility
            }

            if difference > 0 {
                high = volatility
            } else {
                low = volatility
            }

            let newton = volatility - difference / analysis.vega
            if analysis.vega > 1e-14, newton.isFinite, newton > low, newton < high {
                volatility = newton
            } else {
                volatility = 0.5 * (low + high)
            }
        }

        throw ItoCanvasError.impliedVolatilityDidNotConverge
    }

    private static func validate(_ contract: OptionContract) throws {
        let values: [(String, Double)] = [
            ("spot", contract.spot),
            ("strike", contract.strike),
            ("timeToExpiry", contract.timeToExpiry),
            ("riskFreeRate", contract.riskFreeRate),
            ("volatility", contract.volatility),
            ("dividendYield", contract.dividendYield),
        ]
        if let invalid = values.first(where: { !$0.1.isFinite }) {
            throw ItoCanvasError.nonFiniteInput(invalid.0)
        }
        guard contract.spot > 0 else { throw ItoCanvasError.nonPositiveSpot }
        guard contract.strike > 0 else { throw ItoCanvasError.nonPositiveStrike }
        guard contract.timeToExpiry >= 0 else { throw ItoCanvasError.negativeTimeToExpiry }
        guard contract.volatility >= 0 else { throw ItoCanvasError.negativeVolatility }
    }

    private static func expirationAnalysis(_ contract: OptionContract) -> OptionAnalysis {
        let price: Double
        let delta: Double
        switch contract.type {
        case .call:
            price = max(contract.spot - contract.strike, 0)
            delta = contract.spot > contract.strike ? 1 : (contract.spot < contract.strike ? 0 : 0.5)
        case .put:
            price = max(contract.strike - contract.spot, 0)
            delta = contract.spot < contract.strike ? -1 : (contract.spot > contract.strike ? 0 : -0.5)
        }
        return OptionAnalysis(price: price, delta: delta, gamma: 0, vega: 0, theta: 0, rho: 0)
    }

    private static func deterministicAnalysis(_ contract: OptionContract) -> OptionAnalysis {
        let time = contract.timeToExpiry
        let discountedSpot = contract.spot * exp(-contract.dividendYield * time)
        let discountedStrike = contract.strike * exp(-contract.riskFreeRate * time)
        let callInTheMoney = discountedSpot > discountedStrike
        let putInTheMoney = discountedStrike > discountedSpot

        switch contract.type {
        case .call:
            let price = max(discountedSpot - discountedStrike, 0)
            let delta = callInTheMoney ? exp(-contract.dividendYield * time) : 0
            let theta = callInTheMoney
                ? contract.dividendYield * discountedSpot - contract.riskFreeRate * discountedStrike
                : 0
            let rho = callInTheMoney ? contract.strike * time * exp(-contract.riskFreeRate * time) : 0
            return OptionAnalysis(price: price, delta: delta, gamma: 0, vega: 0, theta: theta, rho: rho)
        case .put:
            let price = max(discountedStrike - discountedSpot, 0)
            let delta = putInTheMoney ? -exp(-contract.dividendYield * time) : 0
            let theta = putInTheMoney
                ? contract.riskFreeRate * discountedStrike - contract.dividendYield * discountedSpot
                : 0
            let rho = putInTheMoney ? -contract.strike * time * exp(-contract.riskFreeRate * time) : 0
            return OptionAnalysis(price: price, delta: delta, gamma: 0, vega: 0, theta: theta, rho: rho)
        }
    }
}
