import Foundation

/// The seam that lets us move from bundled JSON → remote JSON → a real backend
/// without touching view models.
protocol CatalogRepository {
    func fetchCatalog(city: String) async throws -> Catalog
}

enum CatalogRepositoryError: Error, Equatable {
    case resourceNotFound(String)
}
