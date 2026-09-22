import CoreLocation

/// Raw values match the `city` field in catalog JSON.
enum City: String, CaseIterable, Identifiable {
    case riyadh
    case jeddah
    case dammamKhobar = "dammam_khobar"

    var id: String { rawValue }
    var titleKey: String { "city.\(rawValue)" }

    /// Where the map opens for this city (roughly the city center).
    var center: CLLocationCoordinate2D {
        switch self {
        case .riyadh: return CLLocationCoordinate2D(latitude: 24.7136, longitude: 46.6753)
        case .jeddah: return CLLocationCoordinate2D(latitude: 21.5433, longitude: 39.1728)
        case .dammamKhobar: return CLLocationCoordinate2D(latitude: 26.3927, longitude: 50.1150)
        }
    }

    /// Cities with seed data today. Add Jeddah / Dammam-Khobar here once their data exists.
    static let available: [City] = [.riyadh]
}
