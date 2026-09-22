import Foundation

/// Shared services that view models take as default arguments, so tests can inject fakes
/// without a DI framework.
enum AppDependencies {
    static let analytics: AnalyticsService = ConsoleAnalyticsService()

    static func makeCatalogRepository() -> CatalogRepository {
        guard let url = AppConfig.remoteCatalogURL else { return BundledJSONCatalogRepository() }
        return RemoteJSONCatalogRepository(url: url)
    }
}
