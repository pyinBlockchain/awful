import XCTest
@testable import DealsApp

final class PlaceholderTests: XCTestCase {
    private func initials(_ ar: String, _ en: String, _ language: String) -> String {
        Fixtures.store(nameAr: ar, nameEn: en, items: []).initials(language: language)
    }

    func testArabicInitialSkipsGenericWordsAndDefiniteArticle() {
        XCTAssertEqual(initials("مطعم النخلة", "", "ar"), "ن")
        XCTAssertEqual(initials("متجر نخبة الإلكتروني", "", "ar"), "ن")
        XCTAssertEqual(initials("سلة التمور", "", "ar"), "س")
        XCTAssertEqual(initials("مطعم", "", "ar"), "م", "falls back when every word is generic")
    }

    func testEnglishInitialsUseTwoLetters() {
        XCTAssertEqual(initials("", "Al Nakhla Restaurant", "en"), "AN")
    }
}
