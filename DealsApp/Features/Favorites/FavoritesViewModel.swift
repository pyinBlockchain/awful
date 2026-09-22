import CoreLocation

/// Resolves saved favorite IDs through the validated catalog. A favorite whose store has no
/// valid deals right now isn't shown, but stays saved and reappears when deals return.
@MainActor
struct FavoritesViewModel {
    private let analytics: AnalyticsService

    init(analytics: AnalyticsService = AppDependencies.analytics) {
        self.analytics = analytics
    }

    func stores(favoriteIDs: Set<String>, from validatedStores: [Store]) -> [Store] {
        let favorites = validatedStores.filter { favoriteIDs.contains($0.id) }
        return StoreSorting.sorted(favorites, by: .highestDiscount, from: nil)
    }

    func remove(_ store: Store, from favorites: FavoritesStore) {
        guard favorites.isFavorite(store.id) else { return }
        favorites.toggle(store.id)
        analytics.log(.storeFavorited(storeID: store.id, isFavorite: false))
    }
}
