#if DEBUG
import Foundation

/// DEBUG-only launch arguments that put Home into a known state, used for screenshots and
/// manual QA. Example: `-uiMinDiscount 40 -uiOpenStore st_016 -uiQuery xyz`.
/// Values arrive through the UserDefaults argument domain; nothing is persisted.
@MainActor
enum DebugLaunchOptions {
    private static var applied = false

    static func applyOnce(to viewModel: HomeViewModel, path: inout [Store], catalog: CatalogService) {
        guard !applied else { return }
        applied = true
        let defaults = UserDefaults.standard
        if let query = defaults.string(forKey: "uiQuery") {
            viewModel.query = query
        }
        if let filter = DiscountFilter(rawValue: defaults.integer(forKey: "uiMinDiscount")) {
            viewModel.select(discount: filter)
        }
        if let id = defaults.string(forKey: "uiOpenStore"), let store = catalog.store(id: id) {
            path = [store]
        }
    }
}
#endif
