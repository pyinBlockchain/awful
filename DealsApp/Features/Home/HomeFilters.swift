import Foundation

/// Discount chips. Filtering compares against the store's max valid (displayed) discount.
enum DiscountFilter: Int, CaseIterable, Identifiable {
    case all = 0
    case atLeast20 = 20
    case atLeast30 = 30
    case atLeast40 = 40
    case fifty = 50

    var id: Int { rawValue }
    var threshold: Int { rawValue }

    func title(formatter: PriceFormatter = PriceFormatter()) -> String {
        switch self {
        case .all:
            return L10n.tr("filter.all")
        case .fifty:
            // 50 is the ceiling, so "50% or more" would read oddly; the chip just says "50%".
            return formatter.percent(threshold)
        default:
            return L10n.tr("filter.discount.atLeast", formatter.percent(threshold))
        }
    }
}

enum SortOption: String, CaseIterable, Identifiable {
    case highestDiscount
    case nearest
    case newest

    var id: String { rawValue }
    var titleKey: String { "sort.\(rawValue)" }

    /// "Nearest" only makes sense with a location (Phase 3).
    static func available(hasLocation: Bool) -> [SortOption] {
        hasLocation ? allCases : [.highestDiscount, .newest]
    }
}
