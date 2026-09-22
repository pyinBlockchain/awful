import Foundation

/// Phase 4 data source: downloads the catalog JSON, caches the last good copy, and falls back
/// to the cache (or the bundled seed file) when offline. Never throws while any copy exists.
struct RemoteJSONCatalogRepository: CatalogRepository {
    /// Bump together with the app when the JSON format changes incompatibly; older apps will
    /// then ignore the new file and keep showing their last good copy.
    static let supportedVersion = 1

    let url: URL
    var session: URLSession = .shared
    var cache: CatalogCaching = FileCatalogCache.standard
    var fallback: CatalogRepository = BundledJSONCatalogRepository()
    var timeout: TimeInterval = 15

    func fetchCatalog(city: String) async throws -> Catalog {
        do {
            return try await fetchRemote().filtered(city: city)
        } catch {
            DataWarningLog.warn("Remote catalog unavailable, using fallback: \(error)")
        }

        guard let cached = cachedCatalog()?.filtered(city: city) else {
            return try await fallback.fetchCatalog(city: city)
        }
        // An app update can ship a seed file newer than an old cache; show whichever is newer.
        guard let bundled = try? await fallback.fetchCatalog(city: city) else { return cached }
        return cached.updatedAt >= bundled.updatedAt ? cached : bundled
    }

    private func fetchRemote() async throws -> Catalog {
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData,
                                 timeoutInterval: timeout)
        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else { throw CatalogRepositoryError.badResponse(statusCode: status) }

        var catalog = try Self.decodeAcceptable(data)
        // Only cache what decoded cleanly, so a bad upload can't poison the offline copy.
        do {
            try cache.save(data)
        } catch {
            DataWarningLog.warn("Could not cache catalog: \(error)")
        }
        catalog.source = .remote
        return catalog
    }

    private func cachedCatalog() -> Catalog? {
        guard let data = cache.load(), var catalog = try? Self.decodeAcceptable(data) else { return nil }
        catalog.source = .cache
        return catalog
    }

    static func decodeAcceptable(_ data: Data) throws -> Catalog {
        let catalog = try Catalog.makeDecoder().decode(Catalog.self, from: data)
        guard catalog.version == supportedVersion else {
            throw CatalogRepositoryError.unsupportedVersion(catalog.version)
        }
        guard !catalog.stores.isEmpty else { throw CatalogRepositoryError.emptyCatalog }
        return catalog
    }
}
