import MapKit
import SwiftUI

struct MapScreen: View {
    @EnvironmentObject private var catalog: CatalogService
    @EnvironmentObject private var filters: StoreFilters
    @EnvironmentObject private var location: LocationService
    @StateObject private var viewModel = MapViewModel()
    @State private var region = MapViewModel.region(for: AppConfig.defaultCity)
    @State private var path: [Store] = []
    @State private var showLocationDeniedAlert = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        let pins = viewModel.pins(from: catalog.stores, filters: filters)
        return NavigationStack(path: $path) {
            VStack(spacing: 0) {
                FilterBarView(filters: filters)
                ZStack(alignment: .bottom) {
                    map(pins: pins)
                    overlay(pins: pins)
                }
            }
            .background(Theme.background)
            .navigationTitle(Text("tab.map"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { locateButton }
            }
            .navigationDestination(for: Store.self) { StoreDetailView(store: $0) }
        }
        .onAppear {
            #if DEBUG
            if let id = DebugLaunchOptions.mapSelection, viewModel.selectedStoreID == nil {
                viewModel.toggleSelection(id)
            }
            #endif
        }
        .onChange(of: catalog.city) { city in
            viewModel.clearSelection()
            region = MapViewModel.region(for: city)
        }
        .alert(Text("location.denied.title"), isPresented: $showLocationDeniedAlert) {
            Button("location.openSettings") {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }
            Button("common.cancel", role: .cancel) {}
        } message: {
            Text("location.denied.message")
        }
    }

    private func map(pins: [MapPin]) -> some View {
        Map(coordinateRegion: $region, showsUserLocation: location.isAuthorized,
            annotationItems: pins) { pin in
            MapAnnotation(coordinate: pin.coordinate, anchorPoint: CGPoint(x: 0.5, y: 1)) {
                DiscountPin(pin: pin, isSelected: pin.id == viewModel.selectedStoreID)
                    .onTapGesture { viewModel.toggleSelection(pin.id) }
                    .accessibilityIdentifier("mapPin.\(pin.id)")
            }
        }
        .accessibilityIdentifier("map")
    }

    @ViewBuilder
    private func overlay(pins: [MapPin]) -> some View {
        if let selected = viewModel.selectedPin(in: pins) {
            Button {
                path = [selected.store]
            } label: {
                StoreCardView(store: selected.store,
                              distance: selected.store.distance(from: location.location))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            // Clear the Apple Maps logo and "Legal" link, which must stay visible.
            .padding(.bottom, 40)
            .accessibilityIdentifier("mapCard.\(selected.id)")
        } else if pins.isEmpty && catalog.state == .loaded {
            EmptyStateView(symbol: "mappin.slash", messageKey: "map.empty",
                           actionKey: "home.empty.clear") { filters.clear() }
                .background(RoundedRectangle(cornerRadius: Theme.cornerRadius).fill(Theme.background))
                .padding(16)
        }
    }

    private var locateButton: some View {
        Button {
            if location.canRequestPermission {
                location.requestPermission()
            } else if location.isDenied {
                showLocationDeniedAlert = true
            } else if let current = location.location {
                region = MapViewModel.region(around: current)
            }
        } label: {
            Label("map.myLocation", systemImage: location.isAuthorized ? "location.fill" : "location")
                .frame(minWidth: Theme.minTapTarget, minHeight: Theme.minTapTarget)
        }
    }
}
