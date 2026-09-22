import Foundation

/// The ONLY source of stores for the UI. Raw repository data never leaves this class;
/// what's published has always passed `CatalogValidator`, so no screen can show an
/// expired, out-of-range, or empty-store deal by accident.
@MainActor
final class CatalogService: ObservableObject {
    enum LoadState: Equatable {
        case idle, loading, loaded, failed
    }

    @Published private(set) var stores: [Store] = []
    @Published private(set) var state: LoadState = .idle
    @Published private(set) var city: City = AppConfig.defaultCity

    private let repository: CatalogRepository
    private let validator: CatalogValidator
    private let now: () -> Date
    private var rawStores: [Store] = []

    init(repository: CatalogRepository,
         validator: CatalogValidator = CatalogValidator(),
         now: @escaping () -> Date = Date.init) {
        self.repository = repository
        self.validator = validator
        self.now = now
    }

    func loadIfNeeded() async {
        guard state == .idle else { return }
        await load()
    }

    func load() async {
        state = .loading
        do {
            let catalog = try await repository.fetchCatalog(city: city.rawValue)
            rawStores = catalog.stores
            revalidate()
            state = .loaded
        } catch {
            DataWarningLog.warn("Catalog load failed: \(error)")
            state = .failed
        }
    }

    func select(city newCity: City) async {
        guard newCity != city else { return }
        city = newCity
        await load()
    }

    /// Re-run validation against the current time. Called when the app returns to the
    /// foreground so an offer that expired overnight disappears without a relaunch.
    func revalidate() {
        stores = validator.validate(rawStores, at: now()).stores
    }

    func store(id: Store.ID) -> Store? {
        stores.first { $0.id == id }
    }
}
