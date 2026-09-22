#if DEBUG
import Foundation

/// DEBUG-only launch arguments that put the app into a known state, used for screenshots and
/// manual QA. Example: `-uiTab map -uiMapSelect st_001 -uiMinDiscount 40 -uiSort nearest -uiOpenStore st_016`.
/// Values arrive through the UserDefaults argument domain; nothing is persisted.
@MainActor
enum DebugLaunchOptions {
    private static var applied = false

    // Reads only launch arguments, so it's safe from any context (RootTabView's initializer).
    nonisolated static var initialTab: AppTab? {
        UserDefaults.standard.string(forKey: "uiTab").flatMap(AppTab.init(rawValue:))
    }

    static var mapSelection: Store.ID? {
        UserDefaults.standard.string(forKey: "uiMapSelect")
    }

    static func applyOnce(to viewModel: HomeViewModel, filters: StoreFilters,
                          path: inout [Store], catalog: CatalogService) {
        guard !applied else { return }
        applied = true
        let defaults = UserDefaults.standard
        if let query = defaults.string(forKey: "uiQuery") {
            viewModel.query = query
        }
        if let filter = DiscountFilter(rawValue: defaults.integer(forKey: "uiMinDiscount")) {
            filters.select(discount: filter)
        }
        if let sort = defaults.string(forKey: "uiSort").flatMap(SortOption.init(rawValue:)) {
            viewModel.select(sort: sort)
        }
        if let id = defaults.string(forKey: "uiOpenStore"), let store = catalog.store(id: id) {
            path = [store]
        }
    }
}
#endif
