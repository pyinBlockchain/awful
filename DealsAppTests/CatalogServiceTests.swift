import XCTest
@testable import DealsApp

@MainActor
final class CatalogServiceTests: XCTestCase {
    func testPublishesOnlyValidatedStoresAndItems() async {
        let repo = StubCatalogRepository(stores: [
            Fixtures.store(id: "good", items: [
                Fixtures.item(id: "ok"),
                Fixtures.item(id: "tooLow", discounted: 95),
                Fixtures.item(id: "expired", from: "2025-01-01", until: "2025-06-30"),
            ]),
            Fixtures.store(id: "allBad", items: [Fixtures.item(id: "x", discounted: 30)]),
        ])
        let service = CatalogService(repository: repo, now: { Fixtures.now })
        await service.load()

        XCTAssertEqual(service.state, .loaded)
        XCTAssertEqual(service.stores.map(\.id), ["good"])
        XCTAssertEqual(service.stores[0].items.map(\.id), ["ok"])
        XCTAssertNil(service.store(id: "allBad"))
    }

    func testRevalidateDropsItemsThatExpireWhileRunning() async {
        var clock = Fixtures.riyadhDate(2026, 9, 30, 23, 0)
        let repo = StubCatalogRepository(stores: [
            Fixtures.store(items: [Fixtures.item(id: "short", until: "2026-09-30"),
                                   Fixtures.item(id: "long")]),
        ])
        let service = CatalogService(repository: repo, now: { clock })
        await service.load()
        XCTAssertEqual(service.stores[0].items.count, 2)

        clock = Fixtures.riyadhDate(2026, 10, 1, 0, 30)
        service.revalidate()
        XCTAssertEqual(service.stores[0].items.map(\.id), ["long"])
    }

    func testFailureState() async {
        struct Boom: Error {}
        let service = CatalogService(repository: StubCatalogRepository(stores: [], error: Boom()))
        await service.load()
        XCTAssertEqual(service.state, .failed)
        XCTAssertTrue(service.stores.isEmpty)
    }

    func testSeedCatalogThroughServiceHasTwentyStores() async {
        let service = CatalogService(repository: BundledJSONCatalogRepository(), now: { Fixtures.now })
        await service.load()
        XCTAssertEqual(service.stores.count, 20)
    }
}
