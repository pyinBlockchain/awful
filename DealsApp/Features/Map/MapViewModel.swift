import MapKit

struct MapPin: Identifiable, Equatable {
    let store: Store
    let coordinate: CLLocationCoordinate2D
    let percent: Int

    var id: Store.ID { store.id }

    static func == (lhs: MapPin, rhs: MapPin) -> Bool { lhs.store == rhs.store }
}

/// Which stores get a pin and which one is selected. The visible region lives in the view
/// as `@State`: binding MKMap regions through a published property triggers iOS 16's
/// "publishing changes from within view updates" loop.
@MainActor
final class MapViewModel: ObservableObject {
    @Published private(set) var selectedStoreID: Store.ID?

    /// Online-only stores have no location and never appear on the map (CLAUDE.md §2).
    func pins(from stores: [Store], filters: StoreFilters) -> [MapPin] {
        stores.compactMap { store in
            guard filters.matches(store), let coordinate = store.coordinate,
                  let percent = store.maxDiscount else { return nil }
            return MapPin(store: store, coordinate: coordinate, percent: percent)
        }
    }

    /// Tapping the selected pin again closes its card.
    func toggleSelection(_ id: Store.ID) {
        selectedStoreID = selectedStoreID == id ? nil : id
    }

    func clearSelection() {
        selectedStoreID = nil
    }

    func selectedPin(in pins: [MapPin]) -> MapPin? {
        pins.first { $0.id == selectedStoreID }
    }

    static func region(for city: City) -> MKCoordinateRegion {
        MKCoordinateRegion(center: city.center,
                           span: MKCoordinateSpan(latitudeDelta: 0.35, longitudeDelta: 0.35))
    }

    static func region(around location: CLLocation) -> MKCoordinateRegion {
        MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 8000, longitudinalMeters: 8000)
    }
}
