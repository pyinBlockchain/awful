import SwiftUI

struct FavoritesView: View {
    /// Switches to the Home tab from the empty state.
    let onBrowse: () -> Void

    @EnvironmentObject private var catalog: CatalogService
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var location: LocationService
    @State private var path: [Store] = []
    private let viewModel = FavoritesViewModel()

    var body: some View {
        let stores = viewModel.stores(favoriteIDs: favorites.ids, from: catalog.stores)
        return NavigationStack(path: $path) {
            Group {
                if stores.isEmpty {
                    EmptyStateView(symbol: "heart", messageKey: "favorites.empty",
                                   actionKey: "favorites.goHome", action: onBrowse)
                        .frame(maxHeight: .infinity)
                        .accessibilityIdentifier("favorites.emptyState")
                } else {
                    list(stores)
                }
            }
            .background(Theme.background)
            .navigationTitle(Text("tab.favorites"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Store.self) { StoreDetailView(store: $0) }
        }
    }

    /// Not a `List`: on iOS 16, List rows with swipe actions render mirrored in RTL (Arabic text
    /// drawn backwards). Removal is a long-press menu plus a VoiceOver action instead.
    private func list(_ stores: [Store]) -> some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(stores) { store in
                    Button {
                        path = [store]
                    } label: {
                        StoreCardView(store: store, distance: store.distance(from: location.location))
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            viewModel.remove(store, from: favorites)
                        } label: {
                            Label("store.favorite.remove", systemImage: "heart.slash")
                        }
                    }
                    .accessibilityAction(named: Text("store.favorite.remove")) {
                        viewModel.remove(store, from: favorites)
                    }
                    .accessibilityIdentifier("favoriteCard.\(store.id)")
                }
            }
            .padding(16)
        }
    }
}
