import SwiftUI

enum AppTab: String {
    case home, map, favorites
}

struct RootTabView: View {
    @State private var selection: AppTab = RootTabView.initialTab

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem { Label("tab.home", systemImage: "house.fill") }
                .tag(AppTab.home)
            MapScreen()
                .tabItem { Label("tab.map", systemImage: "map.fill") }
                .tag(AppTab.map)
            FavoritesView(onBrowse: { selection = .home })
                .tabItem { Label("tab.favorites", systemImage: "heart.fill") }
                .tag(AppTab.favorites)
        }
    }

    private static var initialTab: AppTab {
        #if DEBUG
        return DebugLaunchOptions.initialTab ?? .home
        #else
        return .home
        #endif
    }
}

struct RootTabView_Previews: PreviewProvider {
    static var previews: some View {
        RootTabView()
            .environmentObject(CatalogService(repository: BundledJSONCatalogRepository()))
            .environmentObject(FavoritesStore())
            .environmentObject(StoreFilters())
            .environmentObject(LocationService())
    }
}
