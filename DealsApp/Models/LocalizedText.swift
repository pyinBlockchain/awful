import Foundation

/// Bilingual text as it arrives in the catalog JSON. Arabic is primary.
struct LocalizedText: Decodable, Hashable {
    let ar: String
    let en: String

    /// Falls back to the other language when one side is empty, so a partially
    /// translated record still shows something rather than a blank label.
    func resolved(language: String = AppLanguage.current) -> String {
        let preferred = language == "ar" ? ar : en
        let fallback = language == "ar" ? en : ar
        return preferred.isEmpty ? fallback : preferred
    }
}
