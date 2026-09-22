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
    /// True when a remote catalog is configured but we're showing the cache or seed file.
    @Published private(set) var isShowingOfflineData = false

    private let repository: CatalogRepository
    private let validator: CatalogValidator
    private let analytics: AnalyticsService
    private let now: () -> Date
    private let expectsRemote: Bool
    private var rawStores: [Store] = []
    private var lastFetch: Date?

    init(repository: CatalogRepository,
         validator: CatalogValidator = CatalogValidator(),
         analytics: AnalyticsService = AppDependencies.analytics,
         now: @escaping () -> Date = Date.init) {
        self.repository = repository
        self.validator = validator
        self.analytics = analytics
        self.now = now
        expectsRemote = repository is RemoteJSONCatalogRepository
    }

    func loadIfNeeded() async {
        guard state == .idle else { return }
        await load()
    }

    /// Shows the full-screen spinner only when there's nothing on screen yet; a refresh
    /// (pull-to-refresh, foreground) keeps the current list visible, and keeps it if the
    /// refresh fails.
    func load() async {
        if stores.isEmpty { state = .loading }
        do {
            let catalog = try await repository.fetchCatalog(city: city.rawValue)
            rawStores = catalog.stores
            isShowingOfflineData = expectsRemote && catalog.source != .remote
            lastFetch = now()
            revalidate()
            state = .loaded
        } catch {
            DataWarningLog.warn("Catalog load failed: \(error)")
            if stores.isEmpty { state = .failed }
        }
    }

    func refreshIfStale(maxAge: TimeInterval = AppConfig.catalogMaxAge) async {
        guard state == .loaded || state == .failed else { return }
        if let lastFetch = lastFetch, now().timeIntervalSince(lastFetch) < maxAge { return }
        await load()
    }

    func select(city newCity: City) async {
        guard newCity != city else { return }
        city = newCity
        analytics.log(.filterUsed(filter: "city", value: newCity.rawValue))
        stores = []
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
