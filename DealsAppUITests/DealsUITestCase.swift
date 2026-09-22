import XCTest

/// Expected on-screen text per language. Kept here (not read from the app bundle) so the
/// tests also prove the right translation actually reaches the screen.
struct UIStrings {
    let homeTitle: String
    let favoritesTab: String
    let couponCopied: String
    let emptySearch: String
    let favoritesEmpty: String

    static let arabic = UIStrings(
        homeTitle: "العروض",
        favoritesTab: "المفضلة",
        couponCopied: "تم نسخ الكود",
        emptySearch: "لا توجد عروض تطابق بحثك. جرّب نسبة خصم أقل أو تصنيفًا آخر.",
        favoritesEmpty: "لم تضف أي متجر للمفضلة بعد.")

    static let english = UIStrings(
        homeTitle: "Deals",
        favoritesTab: "Favorites",
        couponCopied: "Code copied",
        emptySearch: "No deals match your search. Try a lower discount or another category.",
        favoritesEmpty: "You haven't added any stores to favorites yet.")
}

/// The Phase 5 flows (CLAUDE.md §7). Subclasses pick the language, so every test runs in
/// both Arabic (RTL) and English (LTR).
class DealsUITestCase: XCTestCase {
    var language: String { fatalError("subclass must set language") }
    var strings: UIStrings { fatalError("subclass must set strings") }
    var isRTL: Bool { language == "ar" }

    let app = XCUIApplication()
    private let timeout: TimeInterval = 10

    /// Only the language subclasses run; the shared base would crash on `language`.
    override class var defaultTestSuite: XCTestSuite {
        self == DealsUITestCase.self ? XCTestSuite(name: "DealsUITestCase (base)") : super.defaultTestSuite
    }

    /// Set when the run was started with `xcodebuild -testLanguage xx`, which forces that
    /// language on every launched app and overrides our own `-AppleLanguages`.
    private var schemeForcedLanguage: String? {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-AppleLanguages"), index + 1 < args.count else { return nil }
        return args[index + 1].trimmingCharacters(in: CharacterSet(charactersIn: "()\" "))
            .components(separatedBy: ",").first
    }

    override func setUpWithError() throws {
        if let forced = schemeForcedLanguage, !forced.hasPrefix(language) {
            throw XCTSkip("Run forces '\(forced)'; \(language) flows run in the default test run.")
        }
        continueAfterFailure = false
        app.launchArguments = ["-AppleLanguages", "(\(language))",
                               "-AppleLocale", language == "ar" ? "ar_SA" : "en_SA",
                               "-uiTestingReset", "YES"]
        app.launch()
        XCTAssertTrue(app.navigationBars[strings.homeTitle].waitForExistence(timeout: timeout),
                      "Home should open in \(language)")
    }

    // MARK: Helpers

    func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }

    func search(_ text: String) {
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: timeout))
        field.tap()
        field.typeText(text)
    }

    func openStore(_ id: String, searchingFor query: String) {
        search(query)
        let card = element("storeCard.\(id)")
        XCTAssertTrue(card.waitForExistence(timeout: timeout), "card \(id) for '\(query)'")
        card.tap()
        XCTAssertTrue(element("store.favorite").waitForExistence(timeout: timeout), "store detail opened")
    }

    func goBack() {
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }
}
