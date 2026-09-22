import CoreLocation

/// Search + sort state for Home. Filtering is a pure function over already-validated
/// stores from `CatalogService`, so it's easy to test and can't resurrect invalid data.
@MainActor
final class HomeViewModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var sort: SortOption = .highestDiscount

    private let analytics: AnalyticsService

    init(analytics: AnalyticsService = AppDependencies.analytics) {
        self.analytics = analytics
    }

    var hasQuery: Bool {
        !query.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func select(sort newValue: SortOption) {
        sort = newValue
        analytics.log(.filterUsed(filter: "sort", value: newValue.rawValue))
    }

    func searchSubmitted(resultCount: Int) {
        let length = query.trimmingCharacters(in: .whitespaces).count
        guard length > 0 else { return }
        analytics.log(.searchPerformed(queryLength: length, resultCount: resultCount))
    }

    func apply(to stores: [Store], filters: StoreFilters, userLocation: CLLocation?) -> [Store] {
        let filtered = stores.filter { filters.matches($0) && StoreSearch.matches($0, query: query) }
        return StoreSorting.sorted(filtered, by: sort, from: userLocation)
    }
}

/// Sort orders for store lists (Home and Favorites). Ties always end on `id` for stability.
enum StoreSorting {
    static func sorted(_ stores: [Store], by sort: SortOption, from location: CLLocation?) -> [Store] {
        switch sort {
        case .highestDiscount:
            return stores.sorted(by: byDiscountThenNewest)
        case .newest:
            return stores.sorted(by: byNewestThenDiscount)
        case .nearest:
            guard let location = location else { return stores.sorted(by: byDiscountThenNewest) }
            return stores.sorted { a, b in
                // Online stores have no distance; they go last, ordered by discount.
                switch (a.distance(from: location), b.distance(from: location)) {
                case let (da?, db?): return da != db ? da < db : byDiscountThenNewest(a, b)
                case (.some, .none): return true
                case (.none, .some): return false
                case (.none, .none): return byDiscountThenNewest(a, b)
                }
            }
        }
    }

    static func byDiscountThenNewest(_ a: Store, _ b: Store) -> Bool {
        let da = a.maxDiscount ?? 0, db = b.maxDiscount ?? 0
        if da != db { return da > db }
        if a.newestOfferStart != b.newestOfferStart { return isNewer(a, b) }
        return a.id < b.id
    }

    static func byNewestThenDiscount(_ a: Store, _ b: Store) -> Bool {
        if a.newestOfferStart != b.newestOfferStart { return isNewer(a, b) }
        let da = a.maxDiscount ?? 0, db = b.maxDiscount ?? 0
        if da != db { return da > db }
        return a.id < b.id
    }

    private static func isNewer(_ a: Store, _ b: Store) -> Bool {
        switch (a.newestOfferStart, b.newestOfferStart) {
        case let (x?, y?): return x > y
        case (.some, .none): return true
        default: return false
        }
    }
}
