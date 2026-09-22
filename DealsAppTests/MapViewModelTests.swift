import XCTest
@testable import DealsApp

@MainActor
final class MapViewModelTests: XCTestCase {
    private let stores = [
        Fixtures.store(id: "grill", category: .restaurants, items: [Fixtures.item(discounted: 60)]),
        Fixtures.store(id: "cafe", category: .cafes, items: [Fixtures.item(discounted: 75)]),
        Fixtures.store(id: "online", category: .online, type: .online, latitude: nil, longitude: nil,
                       items: [Fixtures.item(discounted: 50)]),
    ]

    func testOnlineStoresNeverGetPins() {
        let pins = MapViewModel().pins(from: stores, filters: StoreFilters(analytics: SpyAnalytics()))
        XCTAssertEqual(pins.map(\.id), ["grill", "cafe"])
        XCTAssertEqual(pins.map(\.percent), [40, 25])
    }

    func testPinsFollowSharedFilters() {
        let filters = StoreFilters(analytics: SpyAnalytics())
        filters.select(discount: .atLeast30)
        XCTAssertEqual(MapViewModel().pins(from: stores, filters: filters).map(\.id), ["grill"])
    }

    func testSelectionTogglesAndDisappearsWhenFilteredOut() {
        let viewModel = MapViewModel()
        let filters = StoreFilters(analytics: SpyAnalytics())
        viewModel.toggleSelection("cafe")
        XCTAssertEqual(viewModel.selectedPin(in: viewModel.pins(from: stores, filters: filters))?.id, "cafe")

        filters.select(category: .restaurants)
        XCTAssertNil(viewModel.selectedPin(in: viewModel.pins(from: stores, filters: filters)))

        viewModel.toggleSelection("cafe")
        XCTAssertNil(viewModel.selectedStoreID, "tapping the selected pin again deselects")
    }

    func testCityRegionCentersOnCity() {
        let region = MapViewModel.region(for: .riyadh)
        XCTAssertEqual(region.center.latitude, 24.7136, accuracy: 0.001)
    }
}
