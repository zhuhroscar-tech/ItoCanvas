import XCTest
@testable import ItoCanvasCore

final class StrategyTests: XCTestCase {
    func testBullCallSpreadPayoffAtKeyPrices() {
        let strategy = OptionStrategy(
            name: "Bull Call Spread",
            legs: [
                OptionLeg(type: .call, strike: 100, premium: 7, quantity: 1, side: .long),
                OptionLeg(type: .call, strike: 110, premium: 3, quantity: 1, side: .short)
            ]
        )

        XCTAssertEqual(strategy.profit(atExpirationSpot: 90), -4, accuracy: 1e-12)
        XCTAssertEqual(strategy.profit(atExpirationSpot: 104), 0, accuracy: 1e-12)
        XCTAssertEqual(strategy.profit(atExpirationSpot: 120), 6, accuracy: 1e-12)
    }

    func testBreakevenDetectionFindsCrossing() {
        let strategy = OptionStrategy(
            name: "Long Call",
            legs: [OptionLeg(type: .call, strike: 100, premium: 5, quantity: 1, side: .long)]
        )

        let levels = strategy.breakevens(from: 50, through: 150, step: 0.25)

        XCTAssertEqual(levels.count, 1)
        XCTAssertEqual(levels[0], 105, accuracy: 0.25)
    }

    func testBreakevenDetectionFindsZeroTouchAtButterflyPeak() throws {
        let strategy = OptionStrategy(
            name: "Zero-Touch Butterfly",
            legs: [
                OptionLeg(type: .call, strike: 100, premium: 5, quantity: 1, side: .long),
                OptionLeg(type: .call, strike: 105, premium: 0, quantity: 2, side: .short),
                OptionLeg(type: .call, strike: 110, premium: 0, quantity: 1, side: .long)
            ]
        )

        let levels = strategy.breakevens(from: 60, through: 140, step: 0.08)

        XCTAssertEqual(levels.count, 1)
        XCTAssertEqual(try XCTUnwrap(levels.first), 105, accuracy: 1e-12)
    }

    func testBreakevensIncludeUnderlyingExposureAtOffGridTouch() throws {
        let strike = 105.03
        let strategy = OptionStrategy(
            name: "Underlying Zero-Touch",
            legs: [
                OptionLeg(type: .call, strike: strike, premium: 0, quantity: 2, side: .short)
            ],
            underlyingQuantity: 1,
            underlyingEntryPrice: strike
        )

        let levels = strategy.breakevens(from: 80, through: 140, step: 0.03)

        XCTAssertEqual(levels.count, 1)
        XCTAssertEqual(try XCTUnwrap(levels.first), strike, accuracy: 1e-12)
    }

    func testBreakevenDetectionReturnsBoundariesOfZeroProfitInterval() throws {
        let strategy = OptionStrategy(
            name: "Zero-Profit Plateau",
            legs: [
                OptionLeg(type: .call, strike: 100, premium: 10, quantity: 1, side: .long),
                OptionLeg(type: .call, strike: 110, premium: 0, quantity: 1, side: .short)
            ]
        )

        let levels = strategy.breakevens(from: 80, through: 140, step: 0.07)

        XCTAssertEqual(levels.count, 2)
        XCTAssertEqual(try XCTUnwrap(levels.first), 110, accuracy: 1e-12)
        XCTAssertEqual(try XCTUnwrap(levels.last), 140, accuracy: 1e-12)
    }

    func testScenarioGridHasDeterministicDimensionsAndFiniteValues() throws {
        let contract = OptionContract(type: .call, spot: 100, strike: 100, timeToExpiry: 0.5, riskFreeRate: 0.04, volatility: 0.25, dividendYield: 0)

        let grid = try ScenarioEngine.priceGrid(
            contract: contract,
            spotChanges: [-0.10, 0, 0.10],
            volatilityChanges: [-0.05, 0, 0.05]
        )

        XCTAssertEqual(grid.count, 3)
        XCTAssertTrue(grid.allSatisfy { $0.count == 3 })
        XCTAssertTrue(grid.flatMap { $0 }.allSatisfy(\.isFinite))
        XCTAssertGreaterThan(grid[2][1], grid[1][1])
    }
}
