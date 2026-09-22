import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var catalog: CatalogService
    @EnvironmentObject private var filters: StoreFilters
    @EnvironmentObject private var location: LocationService
    @StateObject private var viewModel = HomeViewModel()
    @State private var path: [Store] = []

    var body: some View {
        NavigationStack(path: $path) {
            content
                .background(Theme.background)
                .navigationTitle(Text("home.title"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) { CityMenu() }
                    ToolbarItem(placement: .navigationBarTrailing) { sortMenu }
                }
                .searchable(text: $viewModel.query,
                            placement: .navigationBarDrawer(displayMode: .always),
                            prompt: Text("home.search.prompt"))
                .onSubmit(of: .search) {
                    viewModel.searchSubmitted(resultCount: visibleStores.count)
                }
                .navigationDestination(for: Store.self) { store in
                    StoreDetailView(store: store)
                }
        }
        .onChange(of: catalog.state) { _ in applyDebugLaunchOptions() }
        .onAppear(perform: applyDebugLaunchOptions)
    }

    @ViewBuilder
    private var content: some View {
        switch catalog.state {
        case .idle, .loading:
            ProgressView { Text("state.loading") }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed:
            EmptyStateView(symbol: "wifi.exclamationmark", messageKey: "state.error",
                           actionKey: "state.retry") {
                Task { await catalog.load() }
            }
            .frame(maxHeight: .infinity)
        case .loaded:
            storeList
        }
    }

    private var visibleStores: [Store] {
        viewModel.apply(to: catalog.stores, filters: filters, userLocation: location.location)
    }

    private var storeList: some View {
        let stores = visibleStores
        return ScrollView {
            if catalog.isShowingOfflineData {
                OfflineBanner().padding(.top, 8)
            }
            FilterBarView(filters: filters)
            if stores.isEmpty {
                EmptyStateView(symbol: "magnifyingglass", messageKey: "home.empty.message",
                               actionKey: "home.empty.clear") {
                    viewModel.query = ""
                    filters.clear()
                }
                .accessibilityIdentifier("home.emptyState")
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(stores) { store in
                        NavigationLink(value: store) {
                            StoreCardView(store: store, distance: store.distance(from: location.location))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("storeCard.\(store.id)")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .refreshable { await catalog.load() }
    }

    private var sortMenu: some View {
        Menu {
            ForEach(SortOption.available(hasLocation: location.location != nil)) { option in
                Button {
                    viewModel.select(sort: option)
                } label: {
                    if viewModel.sort == option {
                        Label(LocalizedStringKey(option.titleKey), systemImage: "checkmark")
                    } else {
                        Text(LocalizedStringKey(option.titleKey))
                    }
                }
            }
            // "Nearest" needs location; offer to turn it on instead of silently hiding it.
            if location.canRequestPermission {
                Divider()
                Button {
                    location.requestPermission()
                } label: {
                    Label("location.enableForNearest", systemImage: "location")
                }
            }
        } label: {
            Label("sort.title", systemImage: "arrow.up.arrow.down")
                .frame(minWidth: Theme.minTapTarget, minHeight: Theme.minTapTarget)
        }
    }

    private func applyDebugLaunchOptions() {
        #if DEBUG
        guard catalog.state == .loaded else { return }
        DebugLaunchOptions.applyOnce(to: viewModel, filters: filters, path: &path, catalog: catalog)
        #endif
    }
}

private struct CityMenu: View {
    @EnvironmentObject private var catalog: CatalogService

    var body: some View {
        Menu {
            ForEach(City.available) { city in
                Button {
                    Task { await catalog.select(city: city) }
                } label: {
                    if catalog.city == city {
                        Label(LocalizedStringKey(city.titleKey), systemImage: "checkmark")
                    } else {
                        Text(LocalizedStringKey(city.titleKey))
                    }
                }
            }
        } label: {
            Label(LocalizedStringKey(catalog.city.titleKey), systemImage: "mappin.and.ellipse")
                .labelStyle(.titleAndIcon)
                .frame(minHeight: Theme.minTapTarget)
        }
        .accessibilityLabel(Text("city.picker"))
        .accessibilityValue(Text(LocalizedStringKey(catalog.city.titleKey)))
    }
}
