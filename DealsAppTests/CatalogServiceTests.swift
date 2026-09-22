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

@MainActor
final class CatalogServiceRefreshTests: XCTestCase {
    func testOfflineFlagOnlyWhenRemoteExpectedButNotServed() async {
        StubURLProtocol.reply = .failure(.notConnectedToInternet)
        let remote = RemoteJSONCatalogRepository(url: URL(string: "https://example.com/c.json")!,
                                                 session: StubURLProtocol.makeSession(),
                                                 cache: InMemoryCatalogCache())
        let offline = CatalogService(repository: remote, now: { Fixtures.now })
        await offline.load()
        XCTAssertTrue(offline.isShowingOfflineData)
        XCTAssertEqual(offline.stores.count, 20, "falls back to the validated seed data")

        let bundledOnly = CatalogService(repository: BundledJSONCatalogRepository(), now: { Fixtures.now })
        await bundledOnly.load()
        XCTAssertFalse(bundledOnly.isShowingOfflineData, "no remote configured → not 'offline'")
    }

    func testFailedRefreshKeepsCurrentStores() async {
        final class FlakyRepository: CatalogRepository {
            var fail = false
            func fetchCatalog(city: String) async throws -> Catalog {
                struct Down: Error {}
                if fail { throw Down() }
                return Catalog(version: 1, updatedAt: Date(), stores: [
                    Fixtures.store(items: [Fixtures.item()]),
                ])
            }
        }
        let repo = FlakyRepository()
        let service = CatalogService(repository: repo, now: { Fixtures.now })
        await service.load()
        repo.fail = true
        await service.load()

        XCTAssertEqual(service.state, .loaded)
        XCTAssertEqual(service.stores.count, 1)
    }

    func testRefreshIfStaleRespectsMaxAge() async {
        StubURLProtocol.reply = .response(status: 200, body: Data())
        var clock = Fixtures.now
        let counting = CountingRepository()
        let service = CatalogService(repository: counting, now: { clock })
        await service.load()

        await service.refreshIfStale(maxAge: 3600)
        XCTAssertEqual(counting.calls, 1, "fresh: no refetch")

        clock = clock.addingTimeInterval(3601)
        await service.refreshIfStale(maxAge: 3600)
        XCTAssertEqual(counting.calls, 2, "stale: refetched")
    }

    func testCityChangeIsLogged() async {
        let analytics = SpyAnalytics()
        let service = CatalogService(repository: CountingRepository(), analytics: analytics)
        await service.select(city: .jeddah)
        XCTAssertEqual(analytics.events, [.filterUsed(filter: "city", value: "jeddah")])
    }
}

final class CountingRepository: CatalogRepository {
    private(set) var calls = 0
    func fetchCatalog(city: String) async throws -> Catalog {
        calls += 1
        return Catalog(version: 1, updatedAt: Date(), stores: [])
    }
}
