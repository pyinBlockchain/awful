import Foundation

struct Catalog {
    let version: Int
    let updatedAt: Date
    var stores: [Store]
}

extension Catalog: Decodable {
    private enum CodingKeys: String, CodingKey { case version, updatedAt, stores }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = try c.decode(Int.self, forKey: .version)
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
        // Remote JSON (Phase 4) is edited by hand; a typo in one store must not blank the app.
        let lossyStores = try c.decode(LossyArray<Store>.self, forKey: .stores)
        stores = lossyStores.elements
        lossyStores.logFailures(context: "catalog stores")
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
