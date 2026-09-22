import Foundation

/// Raw values match the `city` field in catalog JSON.
enum City: String, CaseIterable, Identifiable {
    case riyadh
    case jeddah
    case dammamKhobar = "dammam_khobar"

    var id: String { rawValue }
    var titleKey: String { "city.\(rawValue)" }

    /// Cities with seed data today. Add Jeddah / Dammam-Khobar here once their data exists.
    static let available: [City] = [.riyadh]
}
