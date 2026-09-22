import XCTest
@testable import DealsApp

final class AnalyticsEventTests: XCTestCase {
    func testEventNamesMatchSpec() {
        let events: [AnalyticsEvent] = [
            .storeViewed(storeID: "s"), .itemViewed(storeID: "s", itemID: "i"),
            .filterUsed(filter: "category", value: "cafes"),
            .searchPerformed(queryLength: 4, resultCount: 2),
            .callTapped(storeID: "s"), .whatsappTapped(storeID: "s"),
            .directionsTapped(storeID: "s"), .websiteTapped(storeID: "s"),
            .couponCopied(storeID: "s"), .storeFavorited(storeID: "s", isFavorite: true),
            .storeShared(storeID: "s"),
        ]
        XCTAssertEqual(events.map(\.name), [
            "store_viewed", "item_viewed", "filter_used", "search_performed", "call_tapped",
            "whatsapp_tapped", "directions_tapped", "website_tapped", "coupon_copied",
            "store_favorited", "store_shared",
        ])
    }

    func testSearchEventCarriesNoQueryText() {
        let params = AnalyticsEvent.searchPerformed(queryLength: 5, resultCount: 3).parameters
        XCTAssertEqual(params, ["query_length": "5", "result_count": "3"])
    }

    func testConsoleServiceConformsToProtocol() {
        let service: AnalyticsService = ConsoleAnalyticsService()
        service.log(.storeViewed(storeID: "st_001"))
    }
}
