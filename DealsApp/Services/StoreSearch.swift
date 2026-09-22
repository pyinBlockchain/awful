import Foundation

/// Which store fields a search looks at (CLAUDE.md §3): store names, item names,
/// category names, and tags, in both languages so either language finds the store.
enum StoreSearch {
    static func matches(_ store: Store, query: String) -> Bool {
        ArabicSearchNormalizer.matches(query: query, in: searchableFields(of: store))
    }

    static func searchableFields(of store: Store) -> [String] {
        var fields = [store.name.ar, store.name.en]
        fields += store.items.flatMap { [$0.name.ar, $0.name.en] }
        fields += AppLanguage.supported.map {
            Localization.string(store.category.titleKey, language: $0)
        }
        fields += store.tags
        return fields
    }
}
