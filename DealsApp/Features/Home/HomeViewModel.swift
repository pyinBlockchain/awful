import Foundation

/// Filter/search/sort state for Home. Filtering is a pure function over already-validated
/// stores from `CatalogService`, so it's easy to test and can't resurrect invalid data.
@MainActor
final class HomeViewModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var category: StoreCategory?
    @Published private(set) var discountFilter: DiscountFilter = .all
    @Published private(set) var sort: SortOption = .highestDiscount

    private let analytics: AnalyticsService

    init(analytics: AnalyticsService = AppDependencies.analytics) {
        self.analytics = analytics
    }

    var hasActiveFilters: Bool {
        category != nil || discountFilter != .all || !query.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func select(category newValue: StoreCategory?) {
        category = newValue
        analytics.log(.filterUsed(filter: "category", value: newValue?.rawValue ?? "all"))
    }

    func select(discount newValue: DiscountFilter) {
        discountFilter = newValue
        analytics.log(.filterUsed(filter: "discount", value: String(newValue.threshold)))
    }

    func select(sort newValue: SortOption) {
        sort = newValue
        analytics.log(.filterUsed(filter: "sort", value: newValue.rawValue))
    }

    func clearFilters() {
        query = ""
        category = nil
        discountFilter = .all
    }

    func searchSubmitted(resultCount: Int) {
        let length = query.trimmingCharacters(in: .whitespaces).count
        guard length > 0 else { return }
        analytics.log(.searchPerformed(queryLength: length, resultCount: resultCount))
    }

    func apply(to stores: [Store]) -> [Store] {
        let filtered = stores.filter { store in
            (category == nil || store.category == category)
                && (store.maxDiscount ?? 0) >= discountFilter.threshold
                && StoreSearch.matches(store, query: query)
        }
        return filtered.sorted(by: comparator)
    }

    private var comparator: (Store, Store) -> Bool {
        switch sort {
        case .highestDiscount, .nearest:
            // Nearest falls back to highest discount until location lands in Phase 3.
            return Self.byDiscountThenNewest
        case .newest:
            return Self.byNewestThenDiscount
        }
    }

    nonisolated private static func byDiscountThenNewest(_ a: Store, _ b: Store) -> Bool {
        let da = a.maxDiscount ?? 0, db = b.maxDiscount ?? 0
        if da != db { return da > db }
        if a.newestOfferStart != b.newestOfferStart { return isNewer(a, b) }
        return a.id < b.id
    }

    nonisolated private static func byNewestThenDiscount(_ a: Store, _ b: Store) -> Bool {
        if a.newestOfferStart != b.newestOfferStart { return isNewer(a, b) }
        let da = a.maxDiscount ?? 0, db = b.maxDiscount ?? 0
        if da != db { return da > db }
        return a.id < b.id
    }

    nonisolated private static func isNewer(_ a: Store, _ b: Store) -> Bool {
        switch (a.newestOfferStart, b.newestOfferStart) {
        case let (x?, y?): return x > y
        case (.some, .none): return true
        default: return false
        }
    }
}
