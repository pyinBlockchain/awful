import CoreLocation
import XCTest
@testable import DealsApp

final class DistanceFormatterTests: XCTestCase {
    private let ar = DistanceFormatter(language: "ar", digitStyle: .western)
    private let en = DistanceFormatter(language: "en", digitStyle: .western)

    func testMetersRoundedToTen() {
        XCTAssertEqual(ar.string(meters: 853), "850 م")
        XCTAssertEqual(en.string(meters: 853), "850 m")
        XCTAssertEqual(en.string(meters: 2), "10 m", "never shows 0 m")
    }

    func testKilometers() {
        XCTAssertEqual(ar.string(meters: 2_430), "2.4 كم")
        XCTAssertEqual(en.string(meters: 12_600), "13 km")
    }

    func testArabicIndicOption() {
        XCTAssertEqual(DistanceFormatter(language: "ar", digitStyle: .arabicIndic).string(meters: 2_430),
                       "٢٫٤ كم")
    }

    func testStoreDistance() throws {
        let store = Fixtures.store(latitude: 24.7, longitude: 46.7, items: [])
        let meters = try XCTUnwrap(store.distance(from: CLLocation(latitude: 24.71, longitude: 46.7)))
        XCTAssertEqual(meters, 1_110, accuracy: 10)
        XCTAssertNil(Fixtures.store(latitude: nil, longitude: nil, items: [])
            .distance(from: CLLocation(latitude: 24.7, longitude: 46.7)))
    }
}
