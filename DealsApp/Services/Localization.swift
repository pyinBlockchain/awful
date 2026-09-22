import Foundation

enum AppLanguage {
    static let supported = ["ar", "en"]
    static let fallback = "ar"

    /// The language the UI is actually running in. Uses the bundle's resolved localization
    /// rather than `Locale.current` so the per-app language setting in iOS is respected.
    static var current: String {
        let resolved = Bundle.main.preferredLocalizations.first ?? fallback
        return supported.contains(resolved) ? resolved : fallback
    }
}

enum Localization {
    /// Looks a key up in a specific language, regardless of the running UI language.
    /// Needed for search (match both languages) and for deterministic tests.
    static func string(_ key: String, language: String, bundle: Bundle = .main) -> String {
        guard let path = bundle.path(forResource: language, ofType: "lproj"),
              let languageBundle = Bundle(path: path) else {
            return bundle.localizedString(forKey: key, value: nil, table: nil)
        }
        return languageBundle.localizedString(forKey: key, value: nil, table: nil)
    }
}
