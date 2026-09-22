import XCTest
@testable import DealsApp

@MainActor
final class FavoritesStoreTests: XCTestCase {
    func testTogglePersistsAcrossInstances() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let first = FavoritesStore(defaults: defaults)
        XCTAssertTrue(first.toggle("st_001"))
        XCTAssertTrue(FavoritesStore(defaults: defaults).isFavorite("st_001"))

        XCTAssertFalse(first.toggle("st_001"))
        XCTAssertFalse(FavoritesStore(defaults: defaults).isFavorite("st_001"))
    }
}
