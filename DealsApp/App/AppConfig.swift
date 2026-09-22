import Foundation

/// App-wide constants kept in one place so switching data sources or cities needs no hunting.
enum AppConfig {
    static let defaultCity: City = .riyadh
    static let seedCatalogResource = "catalog"

    /// Where the live catalog JSON is hosted (same format as the seed file). Updating that file
    /// updates deals without an App Store release. `nil` = use the bundled seed data only.
    /// TODO: set once the JSON is hosted (must be https).
    static let remoteCatalogURL: URL? = {
        #if DEBUG
        // QA override, e.g. `-uiRemoteURL https://127.0.0.1:9/x.json` to exercise offline fallback.
        if let override = UserDefaults.standard.string(forKey: "uiRemoteURL") {
            return URL(string: override)
        }
        #endif
        return nil
    }()

    /// How long a fetched catalog counts as fresh before returning to the app refetches it.
    static let catalogMaxAge: TimeInterval = 60 * 60

    /// Offers are defined in Riyadh local days; all date math uses this zone,
    /// not the device zone, so a traveller sees the same validity as a local.
    static let dealsTimeZone = TimeZone(identifier: "Asia/Riyadh")!
}
