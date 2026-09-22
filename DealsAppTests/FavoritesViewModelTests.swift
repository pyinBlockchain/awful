import XCTest
@testable import DealsApp

@MainActor
final class FavoritesViewModelTests: XCTestCase {
    private func freshFavorites(_ name: String) -> FavoritesStore {
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return FavoritesStore(defaults: defaults)
    }

    func testFavoritesResolveOnlyThroughValidatedStores() async {
        let repo = StubCatalogRepository(stores: [
            Fixtures.store(id: "live", items: [Fixtures.item(discounted: 70)]),
            Fixtures.store(id: "better", items: [Fixtures.item(discounted: 55)]),
            Fixtures.store(id: "expired", items: [Fixtures.item(until: "2025-12-31")]),
        ])
        let catalog = CatalogService(repository: repo, now: { Fixtures.now })
        await catalog.load()

        let stores = FavoritesViewModel().stores(favoriteIDs: ["live", "better", "expired", "gone"],
                                                 from: catalog.stores)
        XCTAssertEqual(stores.map(\.id), ["better", "live"], "highest discount first; invalid hidden")
    }

    func testRemoveUnfavoritesAndLogs() {
        let favorites = freshFavorites(#function)
        favorites.toggle("st_test")
        let analytics = SpyAnalytics()
        FavoritesViewModel(analytics: analytics).remove(Fixtures.store(items: []), from: favorites)

        XCTAssertFalse(favorites.isFavorite("st_test"))
        XCTAssertEqual(analytics.events, [.storeFavorited(storeID: "st_test", isFavorite: false)])
    }

    func testHiddenFavoriteStaysSaved() {
        let favorites = freshFavorites(#function)
        favorites.toggle("expired")
        _ = FavoritesViewModel().stores(favoriteIDs: favorites.ids, from: [])
        XCTAssertTrue(favorites.isFavorite("expired"), "reappears when the store has deals again")
    }
}
