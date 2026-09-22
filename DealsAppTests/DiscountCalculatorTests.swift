import XCTest
@testable import DealsApp

final class DiscountCalculatorTests: XCTestCase {
    private let calculator = DiscountCalculator()

    private func display(_ o: Double, _ d: Double) -> Int? {
        DiscountCalculator.displayPercent(original: o, discounted: d)
    }

    private func inRange(_ o: Double, _ d: Double) -> Bool {
        DiscountCalculator.isInAllowedRange(original: o, discounted: d)
    }

    // MARK: Percent calculation (floored for display)

    func testWholePercent() {
        XCTAssertEqual(display(200, 140), 30)
        XCTAssertEqual(display(100, 50), 50)
        XCTAssertEqual(display(100, 80), 20)
    }

    func testDisplayRoundsDownNeverUp() {
        XCTAssertEqual(display(250, 199), 20, "20.4% shows as 20%")
        XCTAssertEqual(display(1000, 501), 49, "49.9% shows as 49%")
        XCTAssertEqual(display(45, 33), 26, "26.67% shows as 26%, not 27%")
        XCTAssertEqual(display(1000, 499), 50, "50.1% floors to 50% (but is rejected)")
    }

    func testFractionalPricesAvoidFloatingPointDrift() {
        // 29.99 → 20.99 is exactly 30.01% in halalas; Double math would give 30.010003...
        XCTAssertEqual(display(29.99, 20.99), 30)
        // 0.1-style values that are inexact in binary floating point.
        XCTAssertEqual(display(0.3, 0.2), 33)
        XCTAssertTrue(inRange(0.5, 0.4), "exactly 20% with fractional prices")
    }

    func testExactPercent() throws {
        let exact = try XCTUnwrap(DiscountCalculator.exactPercent(original: 200, discounted: 161))
        XCTAssertEqual(exact, 19.5, accuracy: 0.0001)
    }

    func testNonsensePricesHaveNoPercent() {
        XCTAssertNil(display(0, 0))
        XCTAssertNil(display(100, 100))
        XCTAssertNil(display(100, 120))
        XCTAssertNil(display(100, -1))
    }

    // MARK: 20–50 boundaries (validated on the EXACT percent)

    func testBoundaries() {
        XCTAssertFalse(inRange(100, 81), "19% rejected")
        XCTAssertTrue(inRange(100, 80), "20% accepted")
        XCTAssertTrue(inRange(100, 50), "50% accepted")
        XCTAssertFalse(inRange(100, 49), "51% rejected")
    }

    func testFractionalBoundaries() {
        XCTAssertFalse(inRange(200, 161), "19.5% rejected, even though it would round to 20")
        XCTAssertFalse(inRange(10000, 8001), "19.99% rejected")
        XCTAssertTrue(inRange(250, 199), "20.4% accepted")
        XCTAssertTrue(inRange(1000, 501), "49.9% accepted")
        XCTAssertFalse(inRange(1000, 499), "50.1% rejected, even though it floors to 50")
    }

    // MARK: Item rejection reasons

    func testValidItem() {
        XCTAssertNil(calculator.rejection(for: Fixtures.item(), at: Fixtures.now))
        XCTAssertTrue(Fixtures.item().isValid(at: Fixtures.now))
    }

    func testRejectionReasons() {
        let now = Fixtures.now
        XCTAssertEqual(calculator.rejection(for: Fixtures.item(original: 0, discounted: 0), at: now),
                       .invalidOriginalPrice)
        XCTAssertEqual(calculator.rejection(for: Fixtures.item(discounted: -5), at: now),
                       .invalidDiscountedPrice)
        XCTAssertEqual(calculator.rejection(for: Fixtures.item(discounted: 100), at: now),
                       .notDiscounted)
        XCTAssertEqual(calculator.rejection(for: Fixtures.item(discounted: 120), at: now),
                       .notDiscounted)
        XCTAssertEqual(calculator.rejection(for: Fixtures.item(discounted: 90), at: now),
                       .discountOutOfRange(exactPercent: 10))
        XCTAssertEqual(calculator.rejection(for: Fixtures.item(discounted: 40), at: now),
                       .discountOutOfRange(exactPercent: 60))
    }

    // MARK: Expiry (end of validUntil day, Riyadh time)

    func testValidThroughEndOfLastDayInRiyadh() {
        let item = Fixtures.item(until: "2026-09-23")
        XCTAssertNil(calculator.rejection(for: item, at: Fixtures.riyadhDate(2026, 9, 23, 23, 59, 59)))
        XCTAssertEqual(calculator.rejection(for: item, at: Fixtures.riyadhDate(2026, 9, 24, 0, 0, 0)),
                       .expired)
    }

    func testExpiryIgnoresDeviceTimeZone() {
        // 23:30 in Riyadh is already the next day in Tokyo; the offer must still be live.
        let item = Fixtures.item(until: "2026-09-23")
        let lateEveningRiyadh = Fixtures.riyadhDate(2026, 9, 23, 23, 30)
        XCTAssertNil(calculator.rejection(for: item, at: lateEveningRiyadh))
    }

    func testExpiredLastYear() {
        let item = Fixtures.item(from: "2025-03-01", until: "2025-03-30")
        XCTAssertEqual(calculator.rejection(for: item, at: Fixtures.now), .expired)
    }

    func testNotStartedUntilStartOfFirstDay() {
        let item = Fixtures.item(from: "2026-09-24")
        XCTAssertEqual(calculator.rejection(for: item, at: Fixtures.riyadhDate(2026, 9, 23, 23, 59, 59)),
                       .notStarted)
        XCTAssertNil(calculator.rejection(for: item, at: Fixtures.riyadhDate(2026, 9, 24, 0, 0, 0)))
    }

    // MARK: DealDay parsing

    func testDealDayParsing() {
        XCTAssertEqual(DealDay(string: "2026-10-31")?.description, "2026-10-31")
        XCTAssertNil(DealDay(string: "2026-02-30"), "impossible date")
        XCTAssertNil(DealDay(string: "2026-9-1"), "must be zero-padded")
        XCTAssertNil(DealDay(string: "2026-10-31T00:00:00Z"))
        XCTAssertLessThan(Fixtures.day("2026-09-30"), Fixtures.day("2026-10-01"))
    }
}
