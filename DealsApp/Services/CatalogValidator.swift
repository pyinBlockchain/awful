import Foundation

enum DataWarning: Equatable, CustomStringConvertible {
    case itemRejected(storeID: String, itemID: String, reason: ItemRejection)
    case storeHidden(storeID: String)
    case storeDataMismatch(storeID: String, detail: String)

    var description: String {
        switch self {
        case let .itemRejected(storeID, itemID, reason):
            return "Item \(itemID) in store \(storeID) hidden: \(reason)"
        case let .storeHidden(storeID):
            return "Store \(storeID) hidden: no valid items"
        case let .storeDataMismatch(storeID, detail):
            return "Store \(storeID) data mismatch: \(detail)"
        }
    }
}

/// Turns raw catalog stores into what the UI may show: only valid items (sorted by highest
/// discount), and only stores that still have at least one. Everything dropped is reported.
struct CatalogValidator {
    var calculator = DiscountCalculator()

    struct Result {
        let stores: [Store]
        let warnings: [DataWarning]
    }

    func validate(_ stores: [Store], at now: Date) -> Result {
        var visible: [Store] = []
        var warnings: [DataWarning] = []

        for store in stores {
            warnings += consistencyWarnings(for: store)
            var validItems: [Item] = []
            for item in store.items {
                if let reason = calculator.rejection(for: item, at: now) {
                    warnings.append(.itemRejected(storeID: store.id, itemID: item.id, reason: reason))
                } else {
                    validItems.append(item)
                }
            }
            guard !validItems.isEmpty else {
                warnings.append(.storeHidden(storeID: store.id))
                continue
            }
            var cleaned = store
            cleaned.items = validItems.sorted(by: Self.highestDiscountFirst)
            visible.append(cleaned)
        }

        warnings.forEach { DataWarningLog.warn($0.description) }
        return Result(stores: visible, warnings: warnings)
    }

    /// Ties break on id so the order is stable between launches.
    private static func highestDiscountFirst(_ a: Item, _ b: Item) -> Bool {
        let pa = a.discountPercent ?? 0
        let pb = b.discountPercent ?? 0
        return pa != pb ? pa > pb : a.id < b.id
    }

    /// `type` and `category` are independent fields (decision log §11.7); disagreement is
    /// likely a data-entry mistake, so we flag it but still show the store.
    private func consistencyWarnings(for store: Store) -> [DataWarning] {
        var details: [String] = []
        if (store.type == .online) != (store.category == .online) {
            details.append("type \(store.type.rawValue) with category \(store.category.rawValue)")
        }
        if store.type == .hotel && store.category != .hotels {
            details.append("hotel type with category \(store.category.rawValue)")
        }
        if store.type == .online && store.website == nil {
            details.append("online store without website")
        }
        if store.type != .online && !store.hasLocation {
            details.append("physical store without coordinates (hidden from map)")
        }
        return details.map { .storeDataMismatch(storeID: store.id, detail: $0) }
    }
}
