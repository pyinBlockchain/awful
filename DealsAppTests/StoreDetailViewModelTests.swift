import XCTest
@testable import DealsApp

@MainActor
final class StoreDetailViewModelTests: XCTestCase {
    private func makeStore(phone: String? = nil, whatsapp: String? = nil, website: URL? = nil,
                           coupon: String? = nil, located: Bool = true) -> Store {
        Store(id: "st_x", name: LocalizedText(ar: "مطعم النخلة", en: "Al Nakhla"),
              category: .restaurants, type: .physical, city: "riyadh", district: nil,
              latitude: located ? 24.81 : nil, longitude: located ? 46.61 : nil,
              phone: phone, whatsapp: whatsapp, website: website, couponCode: coupon,
              logoURL: nil, coverURL: nil, discountPermitNumber: nil, tags: [],
              items: [Fixtures.item(discounted: 60)])
    }

    func testOnlyActionsWithDataAreAvailable() {
        let bare = StoreDetailViewModel(store: makeStore(located: false))
        XCTAssertEqual(bare.availableActions, [])

        let full = StoreDetailViewModel(store: makeStore(
            phone: "+966500000001", whatsapp: "+966 50 000 0001",
            website: URL(string: "https://example.com")))
        XCTAssertEqual(full.availableActions, [.call, .whatsapp, .directions, .website])
    }

    func testActionURLs() {
        let vm = StoreDetailViewModel(store: makeStore(phone: "+966 50 000 0001",
                                                       whatsapp: "+966 50 000 0001"))
        XCTAssertEqual(vm.url(for: .call)?.absoluteString, "tel:+966500000001")
        XCTAssertEqual(vm.url(for: .whatsapp)?.absoluteString, "https://wa.me/966500000001")
        XCTAssertEqual(vm.url(for: .directions)?.absoluteString,
                       "http://maps.apple.com/?daddr=24.81,46.61&dirflg=d")
    }

    func testCopyCouponCopiesAndConfirms() {
        var copied: String?
        let analytics = SpyAnalytics()
        let vm = StoreDetailViewModel(store: makeStore(coupon: "NOKHBA30"), analytics: analytics,
                                      copyToPasteboard: { copied = $0 })
        vm.copyCoupon()
        XCTAssertEqual(copied, "NOKHBA30")
        XCTAssertTrue(vm.couponCopied)
        XCTAssertEqual(analytics.events, [.couponCopied(storeID: "st_x")])
    }

    func testAnalyticsForViewActionsItemAndFavorite() {
        let analytics = SpyAnalytics()
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let favorites = FavoritesStore(defaults: defaults)
        let store = makeStore(phone: "+966500000001")
        let vm = StoreDetailViewModel(store: store, analytics: analytics)

        vm.onAppear()
        vm.didPerform(.call)
        vm.select(store.items[0])
        vm.toggleFavorite(in: favorites)
        vm.didShare()

        XCTAssertEqual(vm.selectedItem, store.items[0])
        XCTAssertEqual(analytics.events, [
            .storeViewed(storeID: "st_x"), .callTapped(storeID: "st_x"),
            .itemViewed(storeID: "st_x", itemID: "it_test"),
            .storeFavorited(storeID: "st_x", isFavorite: true), .storeShared(storeID: "st_x"),
        ])
    }
}
