import Foundation

/// Phase 1 data source: the seed catalog shipped inside the app.
/// Returns raw stores for the city; run `CatalogValidator` before showing them.
struct BundledJSONCatalogRepository: CatalogRepository {
    var bundle: Bundle = .main
    var resourceName: String = AppConfig.seedCatalogResource

    func fetchCatalog(city: String) async throws -> Catalog {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw CatalogRepositoryError.resourceNotFound(resourceName)
        }
        let data = try Data(contentsOf: url)
        return try Catalog.makeDecoder().decode(Catalog.self, from: data).filtered(city: city)
    }
}
