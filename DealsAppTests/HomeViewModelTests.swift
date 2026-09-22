import CoreLocation
import XCTest
@testable import DealsApp

@MainActor
final class HomeViewModelTests: XCTestCase {
    private var analytics: SpyAnalytics!
    private var viewModel: HomeViewModel!
    private var filters: StoreFilters!

    // Max discounts: cafe 25%, grill 40%, hotel 50%.
    private let stores = [
        Fixtures.store(id: "cafe", category: .cafes, nameAr: "مقهى الرمال", nameEn: "Rimal Café",
                       latitude: 24.80, longitude: 46.60,
                       items: [Fixtures.item(id: "c1", discounted: 75, from: "2026-09-20")]),
        Fixtures.store(id: "grill", category: .restaurants, nameAr: "مطعم النخلة", nameEn: "Nakhla",
                       tags: ["مشويات"], latitude: 24.70, longitude: 46.70,
                       items: [Fixtures.item(id: "g1", discounted: 60, from: "2026-09-01")]),
        Fixtures.store(id: "hotel", category: .hotels, type: .hotel, nameAr: "فندق الواحة", nameEn: "Oasis",
                       latitude: 24.75, longitude: 46.65,
                       items: [Fixtures.item(id: "h1", discounted: 50, from: "2026-09-10")]),
    ]

    override func setUp() async throws {
        analytics = SpyAnalytics()
        viewModel = HomeViewModel(analytics: analytics)
        filters = StoreFilters(analytics: analytics)
    }

    private func ids(location: CLLocation? = nil) -> [String] {
        viewModel.apply(to: stores, filters: filters, userLocation: location).map(\.id)
    }

    func testDefaultSortIsHighestDiscount() {
        XCTAssertEqual(ids(), ["hotel", "grill", "cafe"])
    }

    func testNewestSort() {
        viewModel.select(sort: .newest)
        XCTAssertEqual(ids(), ["cafe", "hotel", "grill"])
    }

    func testNearestSortUsesDistance() {
        viewModel.select(sort: .nearest)
        let nearGrill = CLLocation(latitude: 24.701, longitude: 46.701)
        XCTAssertEqual(ids(location: nearGrill), ["grill", "hotel", "cafe"])
    }

    func testNearestWithoutLocationFallsBackToHighestDiscount() {
        viewModel.select(sort: .nearest)
        XCTAssertEqual(ids(), ["hotel", "grill", "cafe"])
    }

    func testNearestPutsOnlineStoresLast() {
        let online = Fixtures.store(id: "online", category: .online, type: .online,
                                    latitude: nil, longitude: nil,
                                    items: [Fixtures.item(discounted: 50)])
        viewModel.select(sort: .nearest)
        let result = viewModel.apply(to: stores + [online], filters: filters,
                                     userLocation: CLLocation(latitude: 24.7, longitude: 46.7))
        XCTAssertEqual(result.last?.id, "online")
    }

    func testDiscountFilterUsesMaxDiscount() {
        filters.select(discount: .atLeast40)
        XCTAssertEqual(ids(), ["hotel", "grill"])
        filters.select(discount: .fifty)
        XCTAssertEqual(ids(), ["hotel"])
        filters.select(discount: .atLeast20)
        XCTAssertEqual(ids().count, 3)
    }

    func testCategoryFilter() {
        filters.select(category: .cafes)
        XCTAssertEqual(ids(), ["cafe"])
    }

    func testSearchIsArabicAware() {
        viewModel.query = "مقهي"
        XCTAssertEqual(ids(), ["cafe"])
        viewModel.query = "مشويات"
        XCTAssertEqual(ids(), ["grill"])
    }

    func testEmptyResultAndClearFilters() {
        viewModel.query = "بيتزا"
        filters.select(category: .hotels)
        XCTAssertTrue(ids().isEmpty)
        XCTAssertTrue(viewModel.hasQuery && filters.isActive)

        viewModel.query = ""
        filters.clear()
        XCTAssertFalse(filters.isActive)
        XCTAssertEqual(ids().count, 3)
    }

    func testFilterAndSearchAnalytics() {
        filters.select(category: .cafes)
        filters.select(discount: .atLeast30)
        viewModel.select(sort: .newest)
        viewModel.query = "قهوة"
        viewModel.searchSubmitted(resultCount: 1)
        XCTAssertEqual(analytics.events, [
            .filterUsed(filter: "category", value: "cafes"),
            .filterUsed(filter: "discount", value: "30"),
            .filterUsed(filter: "sort", value: "newest"),
            .searchPerformed(queryLength: 4, resultCount: 1),
        ])
    }

    func testNearestHiddenWithoutLocation() {
        XCTAssertFalse(SortOption.available(hasLocation: false).contains(.nearest))
        XCTAssertTrue(SortOption.available(hasLocation: true).contains(.nearest))
    }
}
