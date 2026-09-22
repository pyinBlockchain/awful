import Foundation

/// App-wide constants kept in one place so switching data sources or cities needs no hunting.
enum AppConfig {
    static let defaultCity = "riyadh"
    static let seedCatalogResource = "catalog"

    /// Offers are defined in Riyadh local days; all date math uses this zone,
    /// not the device zone, so a traveller sees the same validity as a local.
    static let dealsTimeZone = TimeZone(identifier: "Asia/Riyadh")!
}
