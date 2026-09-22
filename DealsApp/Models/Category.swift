import Foundation

/// Named `StoreCategory` because `Category` collides with the Objective-C runtime typedef.
enum StoreCategory: String, Decodable, CaseIterable, Identifiable {
    case restaurants, cafes, hotels, beauty, retail, online, entertainment

    var id: String { rawValue }

    /// Key into Localizable.strings for the category title.
    var titleKey: String { "category.\(rawValue)" }

    /// Used for the image placeholder when a store has no logo.
    var symbolName: String {
        switch self {
        case .restaurants: return "fork.knife"
        case .cafes: return "cup.and.saucer.fill"
        case .hotels: return "bed.double.fill"
        case .beauty: return "scissors"
        case .retail: return "bag.fill"
        case .online: return "globe"
        case .entertainment: return "ticket.fill"
        }
    }
}

enum StoreType: String, Decodable {
    case physical, online, hotel
}
