import XCTest
@testable import DealsApp

final class RemoteCatalogRepositoryTests: XCTestCase {
    private let url = URL(string: "https://example.com/catalog.json")!

    private static func json(version: Int = 1, updatedAt: String = "2026-10-01T00:00:00Z",
                             storeID: String = "remote_store", city: String = "riyadh") -> Data {
        Data("""
        {"version":\(version),"updatedAt":"\(updatedAt)","stores":[
          {"id":"\(storeID)","name":{"ar":"متجر","en":"Store"},"category":"cafes","type":"physical",
           "city":"\(city)","latitude":24.7,"longitude":46.7,"items":[]}
        ]}
        """.utf8)
    }

    private func repository(cache: InMemoryCatalogCache) -> RemoteJSONCatalogRepository {
        RemoteJSONCatalogRepository(url: url, session: StubURLProtocol.makeSession(), cache: cache)
    }

    override func setUp() {
        StubURLProtocol.requestCount = 0
    }

    func testRemoteSuccessIsReturnedAndCached() async throws {
        StubURLProtocol.reply = .response(status: 200, body: Self.json())
        let cache = InMemoryCatalogCache()
        let catalog = try await repository(cache: cache).fetchCatalog(city: "riyadh")

        XCTAssertEqual(catalog.source, .remote)
        XCTAssertEqual(catalog.stores.map(\.id), ["remote_store"])
        XCTAssertEqual(cache.data, Self.json())
    }

    func testOfflineUsesCache() async throws {
        StubURLProtocol.reply = .failure(.notConnectedToInternet)
        let cache = InMemoryCatalogCache(Self.json(storeID: "cached_store"))
        let catalog = try await repository(cache: cache).fetchCatalog(city: "riyadh")

        XCTAssertEqual(catalog.source, .cache)
        XCTAssertEqual(catalog.stores.map(\.id), ["cached_store"])
    }

    func testServerErrorUsesCache() async throws {
        StubURLProtocol.reply = .response(status: 500, body: Data())
        let cache = InMemoryCatalogCache(Self.json(storeID: "cached_store"))
        let catalog = try await repository(cache: cache).fetchCatalog(city: "riyadh")
        XCTAssertEqual(catalog.source, .cache)
    }

    func testOfflineWithoutCacheUsesBundledSeed() async throws {
        StubURLProtocol.reply = .failure(.timedOut)
        let catalog = try await repository(cache: InMemoryCatalogCache()).fetchCatalog(city: "riyadh")
        XCTAssertEqual(catalog.source, .bundled)
        XCTAssertEqual(catalog.stores.count, 21)
    }

    func testMalformedRemoteIsNotCached() async throws {
        StubURLProtocol.reply = .response(status: 200, body: Data("<html>oops</html>".utf8))
        let good = Self.json(storeID: "cached_store")
        let cache = InMemoryCatalogCache(good)
        let catalog = try await repository(cache: cache).fetchCatalog(city: "riyadh")

        XCTAssertEqual(catalog.source, .cache)
        XCTAssertEqual(cache.data, good, "bad upload must not overwrite the last good copy")
    }

    func testUnsupportedVersionIsIgnored() async throws {
        StubURLProtocol.reply = .response(status: 200, body: Self.json(version: 2))
        let cache = InMemoryCatalogCache()
        let catalog = try await repository(cache: cache).fetchCatalog(city: "riyadh")

        XCTAssertEqual(catalog.source, .bundled)
        XCTAssertNil(cache.data)
    }

    func testEmptyRemoteCatalogIsRejected() {
        let empty = Data(#"{"version":1,"updatedAt":"2026-10-01T00:00:00Z","stores":[]}"#.utf8)
        XCTAssertThrowsError(try RemoteJSONCatalogRepository.decodeAcceptable(empty)) {
            XCTAssertEqual($0 as? CatalogRepositoryError, .emptyCatalog)
        }
    }

    func testStaleCacheLosesToNewerBundledSeed() async throws {
        StubURLProtocol.reply = .failure(.notConnectedToInternet)
        // Seed file is dated 2026-09-23; this cache is older.
        let cache = InMemoryCatalogCache(Self.json(updatedAt: "2026-01-01T00:00:00Z"))
        let catalog = try await repository(cache: cache).fetchCatalog(city: "riyadh")
        XCTAssertEqual(catalog.source, .bundled)
    }

    func testFiltersByCity() async throws {
        StubURLProtocol.reply = .response(status: 200, body: Self.json(city: "jeddah"))
        let catalog = try await repository(cache: InMemoryCatalogCache()).fetchCatalog(city: "riyadh")
        XCTAssertTrue(catalog.stores.isEmpty)
    }

    func testFileCacheRoundTrip() throws {
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString).appendingPathExtension("json")
        let cache = FileCatalogCache(fileURL: file)
        XCTAssertNil(cache.load())
        try cache.save(Self.json())
        XCTAssertEqual(cache.load(), Self.json())
        try? FileManager.default.removeItem(at: file)
    }
}
