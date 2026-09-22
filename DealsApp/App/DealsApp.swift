import SwiftUI

@main
struct DealsApp: App {
    @StateObject private var catalog = CatalogService(repository: BundledJSONCatalogRepository())
    @StateObject private var favorites = FavoritesStore()
    @StateObject private var filters = StoreFilters()
    @StateObject private var location = LocationService()
    @Environment(\.scenePhase) private var scenePhase

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
            // Offers can expire while the app sits in the background.
            if phase == .active { catalog.revalidate() }
        }
    }
}
