import Foundation

/// Category + discount filters, shared by Home and Map so a filter chosen on one tab
/// carries over to the other. Search and sort stay Home-only.
@MainActor
final class StoreFilters: ObservableObject {
    @Published private(set) var category: StoreCategory?
    @Published private(set) var discount: DiscountFilter = .all

    private let analytics: AnalyticsService

    init(analytics: AnalyticsService = AppDependencies.analytics) {
        self.analytics = analytics
    }

    var isActive: Bool { category != nil || discount != .all }

    func select(category newValue: StoreCategory?) {
        category = newValue
        analytics.log(.filterUsed(filter: "category", value: newValue?.rawValue ?? "all"))
    }

    func select(discount newValue: DiscountFilter) {
        discount = newValue
        analytics.log(.filterUsed(filter: "discount", value: String(newValue.threshold)))
    }

    func clear() {
        category = nil
        discount = .all
    }

    /// Discount filtering uses the store's max valid (displayed) discount.
    func matches(_ store: Store) -> Bool {
        (category == nil || store.category == category)
            && (store.maxDiscount ?? 0) >= discount.threshold
    }
}
