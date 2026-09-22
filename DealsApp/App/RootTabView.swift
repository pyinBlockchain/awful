import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("tab.home", systemImage: "house.fill") }
            // Map and Favorites screens arrive in Phase 3.
            ComingSoonView()
                .tabItem { Label("tab.map", systemImage: "map.fill") }
            ComingSoonView()
                .tabItem { Label("tab.favorites", systemImage: "heart.fill") }
        }
    }
}

private struct ComingSoonView: View {
    var body: some View {
        EmptyStateView(symbol: "hourglass", messageKey: "state.comingSoon")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.background)
    }
}

struct RootTabView_Previews: PreviewProvider {
    static var previews: some View {
        RootTabView()
            .environmentObject(CatalogService(repository: BundledJSONCatalogRepository()))
            .environmentObject(FavoritesStore())
    }
}
