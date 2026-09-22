import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var catalog: CatalogService
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
                    viewModel.searchSubmitted(resultCount: viewModel.apply(to: catalog.stores).count)
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

    private var storeList: some View {
        let stores = viewModel.apply(to: catalog.stores)
        return ScrollView {
            FilterBarView(viewModel: viewModel)
            if stores.isEmpty {
                EmptyStateView(symbol: "magnifyingglass", messageKey: "home.empty.message",
                               actionKey: "home.empty.clear") {
                    viewModel.clearFilters()
                }
                .accessibilityIdentifier("home.emptyState")
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(stores) { store in
                        NavigationLink(value: store) {
                            StoreCardView(store: store)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("storeCard.\(store.id)")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }

    private var sortMenu: some View {
        Menu {
            ForEach(SortOption.available(hasLocation: false)) { option in
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
        } label: {
            Label("sort.title", systemImage: "arrow.up.arrow.down")
                .frame(minWidth: Theme.minTapTarget, minHeight: Theme.minTapTarget)
        }
    }

    private func applyDebugLaunchOptions() {
        #if DEBUG
        guard catalog.state == .loaded else { return }
        DebugLaunchOptions.applyOnce(to: viewModel, path: &path, catalog: catalog)
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
