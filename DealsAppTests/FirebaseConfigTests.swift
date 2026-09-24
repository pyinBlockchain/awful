import XCTest
@testable import DealsApp

final class FirebaseConfigTests: XCTestCase {
    func testBundledPlistLoadsAndMatchesApp() throws {
        let config = try FirebaseConfig.load()
        XCTAssertEqual(config.projectID, "awful-db42a")
        XCTAssertEqual(config.bundleID, Bundle.main.bundleIdentifier)
        XCTAssertFalse(config.apiKey.isEmpty)
        XCTAssertEqual(config.databaseID, "(default)")
    }

    func testRESTEndpoints() throws {
        let config = FirebaseConfig(apiKey: "k", projectID: "demo-project", bundleID: "b")
        XCTAssertEqual(config.firestoreDocumentsURL.absoluteString,
                       "https://firestore.googleapis.com/v1/projects/demo-project/databases/(default)/documents")
        XCTAssertEqual(config.identityToolkitURL.absoluteString, "https://identitytoolkit.googleapis.com/v1")
    }

    func testMissingPlistIsReported() {
        XCTAssertThrowsError(try FirebaseConfig.load(resource: "Nope")) {
            XCTAssertEqual($0 as? FirebaseConfig.LoadError, .fileMissing)
        }
    }
}
