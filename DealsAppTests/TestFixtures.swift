import Foundation
@testable import DealsApp

/// Builders with sensible defaults so each test states only what it cares about.
enum Fixtures {
    static let riyadh = AppConfig.dealsTimeZone

    /// A Riyadh wall-clock instant, independent of the simulator's time zone.
    static func riyadhDate(_ year: Int, _ month: Int, _ day: Int,
                           _ hour: Int = 12, _ minute: Int = 0, _ second: Int = 0) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = riyadh
        let components = DateComponents(year: year, month: month, day: day,
                                        hour: hour, minute: minute, second: second)
        return calendar.date(from: components)!
    }

    /// Fixed "now" for every test: never the real clock (decision log §11.6).
    static let now = riyadhDate(2026, 9, 23)

    static func day(_ string: String) -> DealDay { DealDay(string: string)! }

    static func item(id: String = "it_test",
                     original: Double = 100,
                     discounted: Double = 70,
                     from: String = "2026-09-01",
                     until: String = "2027-12-31",
                     nameAr: String = "عنصر",
                     nameEn: String = "Item") -> Item {
        Item(id: id, name: LocalizedText(ar: nameAr, en: nameEn), description: nil,
             originalPrice: original, discountedPrice: discounted,
             validFrom: day(from), validUntil: day(until), terms: nil, imageURL: nil)
    }

    static func store(id: String = "st_test",
                      category: StoreCategory = .restaurants,
                      type: StoreType = .physical,
                      nameAr: String = "متجر",
                      nameEn: String = "Store",
                      tags: [String] = [],
                      website: URL? = nil,
                      latitude: Double? = 24.7,
                      longitude: Double? = 46.7,
                      items: [Item]) -> Store {
        Store(id: id, name: LocalizedText(ar: nameAr, en: nameEn), category: category, type: type,
              city: "riyadh", district: nil, latitude: latitude, longitude: longitude,
              phone: nil, whatsapp: nil, website: website, couponCode: nil, logoURL: nil,
              coverURL: nil, discountPermitNumber: nil, tags: tags, items: items)
    }
}
