import Foundation

struct Store: Identifiable, Hashable {
    let id: String
    let name: LocalizedText
    let category: StoreCategory
    let type: StoreType
    let city: String
    let district: LocalizedText?
    let latitude: Double?
    let longitude: Double?
    let phone: String?
    let whatsapp: String?
    let website: URL?
    let couponCode: String?
    let logoURL: URL?
    let coverURL: URL?
    let discountPermitNumber: String?
    let tags: [String]
    /// Raw from JSON. After `CatalogValidator` runs, holds only valid items,
    /// sorted by highest discount first.
    var items: [Item]
}

extension Store {
    /// Headline badge value ("خصم حتى 50%"). Only meaningful on validated stores.
    var maxDiscount: Int? { items.compactMap(\.discountPercent).max() }

    /// Online-only stores have no physical location and never appear on the map.
    var hasLocation: Bool { latitude != nil && longitude != nil }

    /// Used by the "newest" sort (decision log §11.4).
    var newestOfferStart: DealDay? { items.map(\.validFrom).max() }
}

// Decoding lives in an extension so the memberwise initializer stays available for tests.
extension Store: Decodable {
    private enum CodingKeys: String, CodingKey {
        case id, name, category, type, city, district, latitude, longitude, phone, whatsapp,
             website, couponCode, logoURL, coverURL, discountPermitNumber, tags, items
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(LocalizedText.self, forKey: .name)
        category = try c.decode(StoreCategory.self, forKey: .category)
        type = try c.decode(StoreType.self, forKey: .type)
        city = try c.decode(String.self, forKey: .city)
        district = try c.decodeIfPresent(LocalizedText.self, forKey: .district)
        latitude = try c.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try c.decodeIfPresent(Double.self, forKey: .longitude)
        phone = try c.decodeIfPresent(String.self, forKey: .phone)
        whatsapp = try c.decodeIfPresent(String.self, forKey: .whatsapp)
        website = try c.decodeIfPresent(URL.self, forKey: .website)
        couponCode = try c.decodeIfPresent(String.self, forKey: .couponCode)
        logoURL = try c.decodeIfPresent(URL.self, forKey: .logoURL)
        coverURL = try c.decodeIfPresent(URL.self, forKey: .coverURL)
        discountPermitNumber = try c.decodeIfPresent(String.self, forKey: .discountPermitNumber)
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
        // One malformed item must not take the whole store down with it.
        let lossyItems = try c.decodeIfPresent(LossyArray<Item>.self, forKey: .items)
        items = lossyItems?.elements ?? []
        lossyItems?.logFailures(context: "store \(id) items")
    }
}
