import XCTest
@testable import DealsApp

final class CatalogValidatorTests: XCTestCase {
    private let validator = CatalogValidator()

    func testInvalidItemsAreRemovedAndReported() {
        let store = Fixtures.store(items: [
            Fixtures.item(id: "ok", discounted: 70),
            Fixtures.item(id: "low", discounted: 90),
            Fixtures.item(id: "old", from: "2025-01-01", until: "2025-02-01"),
        ])
        let result = validator.validate([store], at: Fixtures.now)

        XCTAssertEqual(result.stores.first?.items.map(\.id), ["ok"])
        XCTAssertTrue(result.warnings.contains(
            .itemRejected(storeID: "st_test", itemID: "low", reason: .discountOutOfRange(exactPercent: 10))))
        XCTAssertTrue(result.warnings.contains(
            .itemRejected(storeID: "st_test", itemID: "old", reason: .expired)))
    }

    func testStoreWithNoValidItemsIsHidden() {
        let store = Fixtures.store(id: "empty", items: [
            Fixtures.item(id: "a", discounted: 95),
            Fixtures.item(id: "b", until: "2025-12-31"),
        ])
        let result = validator.validate([store], at: Fixtures.now)

        XCTAssertTrue(result.stores.isEmpty)
        XCTAssertTrue(result.warnings.contains(.storeHidden(storeID: "empty")))
    }

    func testItemsSortedByHighestDiscountAndMaxDiscount() {
        let store = Fixtures.store(items: [
            Fixtures.item(id: "a", discounted: 75),
            Fixtures.item(id: "b", discounted: 55),
            Fixtures.item(id: "c", discounted: 80),
            Fixtures.item(id: "d", discounted: 10),   // 90%: invalid, must not drive the badge
        ])
        let cleaned = validator.validate([store], at: Fixtures.now).stores[0]

        XCTAssertEqual(cleaned.items.map(\.id), ["b", "a", "c"])
        XCTAssertEqual(cleaned.maxDiscount, 45)
    }

    func testTypeCategoryMismatchIsWarnedButStoreStillShown() {
        let store = Fixtures.store(category: .retail, type: .online,
                                   latitude: nil, longitude: nil, items: [Fixtures.item()])
        let result = validator.validate([store], at: Fixtures.now)

        XCTAssertEqual(result.stores.count, 1)
        let mismatches = result.warnings.filter {
            if case .storeDataMismatch = $0 { return true } else { return false }
        }
        XCTAssertEqual(mismatches.count, 2, "category mismatch + missing website")
    }
}
