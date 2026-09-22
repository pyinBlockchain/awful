import Foundation

/// Favorite store IDs, kept on the device only (no accounts in v1).
/// Stores IDs, not stores, so a favorite always resolves through `CatalogService`
/// and therefore shows current, validated deals.
@MainActor
final class FavoritesStore: ObservableObject {
    @Published private(set) var ids: Set<String>

    private let defaults: UserDefaults
    private let key = "favorites.storeIDs"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        ids = Set(defaults.stringArray(forKey: key) ?? [])
    }

    func isFavorite(_ id: String) -> Bool {
        ids.contains(id)
    }

    /// Returns the new state.
    @discardableResult
    func toggle(_ id: String) -> Bool {
        if ids.contains(id) {
            ids.remove(id)
        } else {
            ids.insert(id)
        }
        defaults.set(ids.sorted(), forKey: key)
        return ids.contains(id)
    }
}
