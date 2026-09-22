import Foundation

protocol CatalogCaching {
    func load() -> Data?
    func save(_ data: Data) throws
}

/// The last good remote catalog, as raw JSON on disk. Lives in Caches: if iOS purges it we
/// simply fall back to the bundled seed file, so nothing is lost that matters.
struct FileCatalogCache: CatalogCaching {
    let fileURL: URL

    static var standard: FileCatalogCache {
        let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return FileCatalogCache(fileURL: directory.appendingPathComponent("catalog-cache.json"))
    }

    func load() -> Data? {
        try? Data(contentsOf: fileURL)
    }

    func save(_ data: Data) throws {
        // Atomic so a crash mid-write can never leave a half-written cache behind.
        try data.write(to: fileURL, options: .atomic)
    }
}
