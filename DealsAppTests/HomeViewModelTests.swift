import XCTest
@testable import DealsApp

@MainActor
final class HomeViewModelTests: XCTestCase {
    private var analytics: SpyAnalytics!
    private var viewModel: HomeViewModel!

    // Max discounts: cafe 25%, grill 40%, hotel 50%.
    private let stores = [
        Fixtures.store(id: "cafe", category: .cafes, nameAr: "مقهى الرمال", nameEn: "Rimal Café",
                       items: [Fixtures.item(id: "c1", discounted: 75, from: "2026-09-20")]),
        Fixtures.store(id: "grill", category: .restaurants, nameAr: "مطعم النخلة", nameEn: "Nakhla",
                       tags: ["مشويات"],
                       items: [Fixtures.item(id: "g1", discounted: 60, from: "2026-09-01")]),
        Fixtures.store(id: "hotel", category: .hotels, type: .hotel, nameAr: "فندق الواحة", nameEn: "Oasis",
                       items: [Fixtures.item(id: "h1", discounted: 50, from: "2026-09-10")]),
    ]

    override func setUp() async throws {
        analytics = SpyAnalytics()
        viewModel = HomeViewModel(analytics: analytics)
    }

    func testDefaultSortIsHighestDiscount() {
        XCTAssertEqual(viewModel.apply(to: stores).map(\.id), ["hotel", "grill", "cafe"])
    }

    func testNewestSort() {
        viewModel.select(sort: .newest)
        XCTAssertEqual(viewModel.apply(to: stores).map(\.id), ["cafe", "hotel", "grill"])
    }

    func testDiscountFilterUsesMaxDiscount() {
        viewModel.select(discount: .atLeast40)
        XCTAssertEqual(viewModel.apply(to: stores).map(\.id), ["hotel", "grill"])
        viewModel.select(discount: .fifty)
        XCTAssertEqual(viewModel.apply(to: stores).map(\.id), ["hotel"])
        viewModel.select(discount: .atLeast20)
        XCTAssertEqual(viewModel.apply(to: stores).count, 3)
    }

    func testCategoryFilter() {
        viewModel.select(category: .cafes)
        XCTAssertEqual(viewModel.apply(to: stores).map(\.id), ["cafe"])
    }

    func testSearchIsArabicAware() {
        viewModel.query = "مقهي"
        XCTAssertEqual(viewModel.apply(to: stores).map(\.id), ["cafe"])
        viewModel.query = "مشويات"
        XCTAssertEqual(viewModel.apply(to: stores).map(\.id), ["grill"])
    }

    func testEmptyResultAndClearFilters() {
        viewModel.query = "بيتزا"
        viewModel.select(category: .hotels)
        XCTAssertTrue(viewModel.apply(to: stores).isEmpty)
        XCTAssertTrue(viewModel.hasActiveFilters)

        viewModel.clearFilters()
        XCTAssertFalse(viewModel.hasActiveFilters)
        XCTAssertEqual(viewModel.apply(to: stores).count, 3)
    }

    func testFilterAndSearchAnalytics() {
        viewModel.select(category: .cafes)
        viewModel.select(discount: .atLeast30)
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
