import Foundation
@testable import DealsApp

final class SpyAnalytics: AnalyticsService {
    private(set) var events: [AnalyticsEvent] = []
    func log(_ event: AnalyticsEvent) { events.append(event) }
}

struct StubCatalogRepository: CatalogRepository {
    var stores: [Store]
    var error: Error?

    func fetchCatalog(city: String) async throws -> Catalog {
        if let error = error { throw error }
        return Catalog(version: 1, updatedAt: Date(timeIntervalSince1970: 0),
                       stores: stores.filter { $0.city == city })
    }
}
