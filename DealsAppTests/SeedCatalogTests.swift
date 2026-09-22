import XCTest
@testable import DealsApp

/// Guards the seed file against the rules in CLAUDE.md §6.
final class SeedCatalogTests: XCTestCase {
    private var raw: Catalog!
    private var visible: [Store]!

    override func setUp() async throws {
        raw = try await BundledJSONCatalogRepository().fetchCatalog(city: "riyadh")
        visible = CatalogValidator().validate(raw.stores, at: Fixtures.now).stores
    }

    func testDecodesAllStores() {
        XCTAssertEqual(raw.version, 1)
        XCTAssertEqual(raw.stores.count, 21)
    }

    func testTwentyVisibleStoresAndAllInvalidStoreHidden() {
        XCTAssertEqual(visible.count, 20)
        XCTAssertFalse(visible.contains { $0.id == "st_021" })
    }

    func testInvalidFixtureItemsAreHidden() {
        let visibleItemIDs = Set(visible.flatMap(\.items).map(\.id))
        for hidden in ["it_008", "it_020", "it_016", "it_024"] {
            XCTAssertFalse(visibleItemIDs.contains(hidden), "\(hidden) should be hidden")
        }
    }

    func testEveryVisibleItemIsWithinRules() {
        for store in visible {
            XCTAssertTrue((3...6).contains(raw.stores.first { $0.id == store.id }!.items.count))
            for item in store.items {
                let percent = item.discountPercent ?? 0
                XCTAssertTrue((20...50).contains(percent), "\(item.id): \(percent)%")
                XCTAssertGreaterThanOrEqual(item.validUntil, Fixtures.day("2027-12-31"))
            }
        }
    }

    func testCoverageOfCategoriesOnlineAndHotels() {
        XCTAssertEqual(Set(visible.map(\.category)), Set(StoreCategory.allCases))
        let online = visible.filter { $0.type == .online }
        XCTAssertGreaterThanOrEqual(online.count, 2)
        XCTAssertTrue(online.allSatisfy { $0.couponCode != nil && !$0.hasLocation })
        XCTAssertGreaterThanOrEqual(visible.filter { $0.type == .hotel }.count, 2)
    }

    func testSeedHasNoDataMismatches() {
        let warnings = CatalogValidator().validate(raw.stores, at: Fixtures.now).warnings
        let mismatches = warnings.filter {
            if case .storeDataMismatch = $0 { return true } else { return false }
        }
        XCTAssertEqual(mismatches, [])
    }

    func testUnknownCityReturnsNoStores() async throws {
        let catalog = try await BundledJSONCatalogRepository().fetchCatalog(city: "jeddah")
        XCTAssertTrue(catalog.stores.isEmpty)
    }

    func testMissingResourceThrows() async {
        do {
            _ = try await BundledJSONCatalogRepository(resourceName: "nope").fetchCatalog(city: "riyadh")
            XCTFail("expected an error")
        } catch {
            XCTAssertEqual(error as? CatalogRepositoryError, .resourceNotFound("nope"))
        }
    }

    func testMalformedStoreIsSkippedNotFatal() throws {
        let json = """
        {"version":1,"updatedAt":"2026-09-23T00:00:00Z","stores":[
          {"id":"bad","category":"not-a-category"},
          {"id":"good","name":{"ar":"أ","en":"A"},"category":"cafes","type":"physical",
           "city":"riyadh","items":[]}
        ]}
        """
        let catalog = try Catalog.makeDecoder().decode(Catalog.self, from: Data(json.utf8))
        XCTAssertEqual(catalog.stores.map(\.id), ["good"])
    }
}
