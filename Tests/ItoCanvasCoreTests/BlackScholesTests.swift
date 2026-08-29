import XCTest
@testable import ItoCanvasCore

final class BlackScholesTests: XCTestCase {
    func testAtTheMoneyCallMatchesReferenceValue() throws {
        let contract = OptionContract(
            type: .call,
            spot: 100,
            strike: 100,
            timeToExpiry: 1,
            riskFreeRate: 0.05,
            volatility: 0.20,
            dividendYield: 0
        )

        let result = try BlackScholes.analyze(contract)

        XCTAssertEqual(result.price, 10.4506, accuracy: 0.0001)
        XCTAssertEqual(result.delta, 0.6368, accuracy: 0.0001)
        XCTAssertEqual(result.gamma, 0.01876, accuracy: 0.00001)
        XCTAssertEqual(result.vega, 37.5240, accuracy: 0.001)
    }

    func testPutCallParityHoldsWithDividendYield() throws {
        let call = OptionContract(type: .call, spot: 125, strike: 120, timeToExpiry: 0.75, riskFreeRate: 0.04, volatility: 0.28, dividendYield: 0.015)
        let put = OptionContract(type: .put, spot: 125, strike: 120, timeToExpiry: 0.75, riskFreeRate: 0.04, volatility: 0.28, dividendYield: 0.015)

        let callPrice = try BlackScholes.analyze(call).price
        let putPrice = try BlackScholes.analyze(put).price
        let parity = 125 * exp(-0.015 * 0.75) - 120 * exp(-0.04 * 0.75)

        XCTAssertEqual(callPrice - putPrice, parity, accuracy: 1e-8)
    }

    func testInvalidContractIsRejected() {
        let contract = OptionContract(type: .call, spot: -1, strike: 100, timeToExpiry: 1, riskFreeRate: 0.05, volatility: 0.2, dividendYield: 0)

        XCTAssertThrowsError(try BlackScholes.analyze(contract))
    }

    func testZeroTimeReturnsIntrinsicValueAndStableGreeks() throws {
        let contract = OptionContract(type: .put, spot: 90, strike: 100, timeToExpiry: 0, riskFreeRate: 0.05, volatility: 0.2, dividendYield: 0)

        let result = try BlackScholes.analyze(contract)

        XCTAssertEqual(result.price, 10, accuracy: 1e-12)
        XCTAssertEqual(result.delta, -1, accuracy: 1e-12)
        XCTAssertEqual(result.gamma, 0, accuracy: 1e-12)
        XCTAssertEqual(result.vega, 0, accuracy: 1e-12)
    }

    func testImpliedVolatilityRecoversKnownVolatility() throws {
        let contract = OptionContract(type: .call, spot: 102, strike: 100, timeToExpiry: 0.5, riskFreeRate: 0.03, volatility: 0.37, dividendYield: 0.01)
        let marketPrice = try BlackScholes.analyze(contract).price

        let recovered = try BlackScholes.impliedVolatility(marketPrice: marketPrice, contract: contract)

        XCTAssertEqual(recovered, 0.37, accuracy: 1e-7)
    }

    func testImpossibleMarketPriceIsRejected() {
        let contract = OptionContract(type: .call, spot: 100, strike: 100, timeToExpiry: 1, riskFreeRate: 0.05, volatility: 0.2, dividendYield: 0)

        XCTAssertThrowsError(try BlackScholes.impliedVolatility(marketPrice: 150, contract: contract))
    }
}
