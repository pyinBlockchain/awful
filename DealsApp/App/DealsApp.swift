import SwiftUI

@main
struct DealsApp: App {
    @StateObject private var catalog = CatalogService(repository: AppDependencies.makeCatalogRepository())
    @StateObject private var favorites = FavoritesStore()
    @StateObject private var filters = StoreFilters()
    @StateObject private var location = LocationService()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        #if DEBUG
        // UI tests pass `-uiTestingReset YES` so each test starts with no saved favorites.
        // Runs before the @StateObjects are created, so FavoritesStore reads the cleared value.
        if UserDefaults.standard.bool(forKey: "uiTestingReset") {
            // An explicit empty list (not removeObject) also shadows values that exist in
            // other preference domains, e.g. ones written with `simctl … defaults write`.
            UserDefaults.standard.set([String](), forKey: FavoritesStore.storageKey)
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(catalog)
                .environmentObject(favorites)
                .environmentObject(filters)
                .environmentObject(location)
                .tint(Theme.primary)
                .task { await catalog.loadIfNeeded() }
        }
        .onChange(of: scenePhase) { phase in
            // Offers can expire while the app sits in the background, and the remote
            // catalog may have changed.
            guard phase == .active else { return }
            catalog.revalidate()
            Task { await catalog.refreshIfStale() }
        }
    }
}
