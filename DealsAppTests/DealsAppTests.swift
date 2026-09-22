import XCTest
@testable import DealsApp

final class SmokeTests: XCTestCase {
    func testDealsTimeZoneIsRiyadh() {
        XCTAssertEqual(AppConfig.dealsTimeZone.identifier, "Asia/Riyadh")
    }
}
