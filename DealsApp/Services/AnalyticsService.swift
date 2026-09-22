import Foundation

/// Events that show merchants the value we send them (CLAUDE.md §4).
/// Parameters carry store/item IDs and filter values only — never personal data.
enum AnalyticsEvent: Equatable {
    case storeViewed(storeID: String)
    case itemViewed(storeID: String, itemID: String)
    case filterUsed(filter: String, value: String)
    // Raw query text is deliberately not logged: people sometimes type names or numbers.
    case searchPerformed(queryLength: Int, resultCount: Int)
    case callTapped(storeID: String)
    case whatsappTapped(storeID: String)
    case directionsTapped(storeID: String)
    case websiteTapped(storeID: String)
    case couponCopied(storeID: String)
    case storeFavorited(storeID: String, isFavorite: Bool)
    case storeShared(storeID: String)

    var name: String {
        switch self {
        case .storeViewed: return "store_viewed"
        case .itemViewed: return "item_viewed"
        case .filterUsed: return "filter_used"
        case .searchPerformed: return "search_performed"
        case .callTapped: return "call_tapped"
        case .whatsappTapped: return "whatsapp_tapped"
        case .directionsTapped: return "directions_tapped"
        case .websiteTapped: return "website_tapped"
        case .couponCopied: return "coupon_copied"
        case .storeFavorited: return "store_favorited"
        case .storeShared: return "store_shared"
        }
    }

    var parameters: [String: String] {
        switch self {
        case let .storeViewed(id), let .callTapped(id), let .whatsappTapped(id),
             let .directionsTapped(id), let .websiteTapped(id), let .couponCopied(id),
             let .storeShared(id):
            return ["store_id": id]
        case let .itemViewed(storeID, itemID):
            return ["store_id": storeID, "item_id": itemID]
        case let .filterUsed(filter, value):
            return ["filter": filter, "value": value]
        case let .searchPerformed(queryLength, resultCount):
            return ["query_length": String(queryLength), "result_count": String(resultCount)]
        case let .storeFavorited(storeID, isFavorite):
            return ["store_id": storeID, "is_favorite": String(isFavorite)]
        }
    }
}

protocol AnalyticsService {
    func log(_ event: AnalyticsEvent)
}

/// v1 implementation: prints in DEBUG, does nothing in release. Swap for a real
/// provider later without touching call sites.
struct ConsoleAnalyticsService: AnalyticsService {
    func log(_ event: AnalyticsEvent) {
        #if DEBUG
        let params = event.parameters.sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")
        print("[analytics] \(event.name) \(params)")
        #endif
    }
}
