import XCTest

extension DealsUITestCase {
    // MARK: Launch + RTL

    func runLaunchLayoutChecks() {
        // The first chip ("الكل"/"All") must sit where the reader starts: right in Arabic,
        // left in English. Catches the iOS 16 horizontal-ScrollView RTL bug regressing.
        let allChip = element("chip.category.all")
        XCTAssertTrue(allChip.waitForExistence(timeout: 10))
        let width = app.windows.firstMatch.frame.width
        if isRTL {
            XCTAssertGreaterThan(allChip.frame.midX, width * 0.7, "RTL: first chip on the right")
        } else {
            XCTAssertLessThan(allChip.frame.midX, width * 0.3, "LTR: first chip on the left")
        }
    }

    // MARK: 40%+ filter

    func runDiscountFilterChecks() {
        element("chip.discount.40").tap()
        // Neighborhood Burger's best deal is 30%: hidden at 40%+ ...
        search("Burger")
        XCTAssertTrue(app.staticTexts[strings.emptySearch].waitForExistence(timeout: 10))
        // ... and back once the filter is relaxed.
        element("chip.discount.20").tap()
        XCTAssertTrue(element("storeCard.st_004").waitForExistence(timeout: 10))
    }

    func runFortyPlusStoreStillShown() {
        element("chip.discount.40").tap()
        search("Nakhla")
        XCTAssertTrue(element("storeCard.st_001").waitForExistence(timeout: 10), "50% store passes 40%+")
    }

    // MARK: Only valid items

    func runOnlyValidItemsChecks() {
        openStore("st_004", searchingFor: "Burger")
        for valid in ["it_013", "it_014", "it_015"] {
            XCTAssertTrue(element("item.\(valid)").exists, "\(valid) is valid and must show")
        }
        XCTAssertFalse(element("item.it_016").exists, "expired item must be hidden")

        goBack()
        app.searchFields.firstMatch.buttons.firstMatch.tap() // clear search
        openStore("st_002", searchingFor: "Deera")
        XCTAssertTrue(element("item.it_005").exists)
        XCTAssertFalse(element("item.it_008").exists, "10% item is outside 20–50% and must be hidden")
    }

    func runHiddenStoreChecks() {
        // Every item of this store is invalid, so the store itself must never appear.
        search("Ghaima")
        XCTAssertTrue(app.staticTexts[strings.emptySearch].waitForExistence(timeout: 10))
        XCTAssertFalse(element("storeCard.st_021").exists)
    }

    // MARK: Coupon

    func runCopyCouponChecks() {
        openStore("st_016", searchingFor: "Nokhba")
        XCTAssertEqual(element("coupon.code").label, "NOKHBA30")
        element("coupon.copy").tap()
        let confirmation = element("coupon.copied")
        XCTAssertTrue(confirmation.waitForExistence(timeout: 2))
        XCTAssertEqual(confirmation.label, strings.couponCopied)
    }

    // MARK: Favorites

    func runFavoriteChecks() {
        app.tabBars.buttons[strings.favoritesTab].tap()
        XCTAssertTrue(app.staticTexts[strings.favoritesEmpty].waitForExistence(timeout: 10),
                      "starts empty (state reset)")
        app.tabBars.buttons.element(boundBy: 0).tap()

        openStore("st_001", searchingFor: "Nakhla")
        element("store.favorite").tap()
        app.tabBars.buttons[strings.favoritesTab].tap()
        XCTAssertTrue(element("favoriteCard.st_001").waitForExistence(timeout: 10))

        // Unfavorite from the store screen: the list empties again.
        element("favoriteCard.st_001").tap()
        XCTAssertTrue(element("store.favorite").waitForExistence(timeout: 10))
        element("store.favorite").tap()
        goBack()
        XCTAssertTrue(app.staticTexts[strings.favoritesEmpty].waitForExistence(timeout: 10))
    }
}

final class ArabicFlowTests: DealsUITestCase {
    override var language: String { "ar" }
    override var strings: UIStrings { .arabic }

    func testLaunchIsRightToLeft() { runLaunchLayoutChecks() }
    func testFortyPlusFilterHidesLowerDiscounts() { runDiscountFilterChecks() }
    func testFortyPlusFilterKeepsQualifyingStores() { runFortyPlusStoreStillShown() }
    func testStoreShowsOnlyValidItems() { runOnlyValidItemsChecks() }
    func testAllInvalidStoreIsHidden() { runHiddenStoreChecks() }
    func testCopyCoupon() { runCopyCouponChecks() }
    func testFavoriteStore() { runFavoriteChecks() }

    func testArabicSearchIgnoresSpellingVariants() {
        // "مقهي" (ي, no hamza/ى) must still find "مقهى الرمال".
        search("مقهي الرمال")
        XCTAssertTrue(element("storeCard.st_005").waitForExistence(timeout: 10))
    }
}

final class EnglishFlowTests: DealsUITestCase {
    override var language: String { "en" }
    override var strings: UIStrings { .english }

    func testLaunchIsLeftToRight() { runLaunchLayoutChecks() }
    func testFortyPlusFilterHidesLowerDiscounts() { runDiscountFilterChecks() }
    func testFortyPlusFilterKeepsQualifyingStores() { runFortyPlusStoreStillShown() }
    func testStoreShowsOnlyValidItems() { runOnlyValidItemsChecks() }
    func testAllInvalidStoreIsHidden() { runHiddenStoreChecks() }
    func testCopyCoupon() { runCopyCouponChecks() }
    func testFavoriteStore() { runFavoriteChecks() }
}
