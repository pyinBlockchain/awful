import XCTest
@testable import DealsApp

/// Every UI string must exist, non-empty, in both Arabic and English (CLAUDE.md §3, §9).
final class LocalizationTests: XCTestCase {
    private func table(_ language: String) throws -> [String: String] {
        let path = try XCTUnwrap(Bundle.main.path(forResource: "Localizable", ofType: "strings",
                                                  inDirectory: nil, forLocalization: language))
        return try XCTUnwrap(NSDictionary(contentsOfFile: path) as? [String: String])
    }

    func testArabicAndEnglishHaveTheSameKeys() throws {
        let ar = try table("ar"), en = try table("en")
        XCTAssertEqual(Set(ar.keys).subtracting(en.keys), [], "missing in en")
        XCTAssertEqual(Set(en.keys).subtracting(ar.keys), [], "missing in ar")
    }

    func testNoEmptyValuesAndMatchingPlaceholders() throws {
        let ar = try table("ar"), en = try table("en")
        for (key, arValue) in ar {
            let enValue = en[key] ?? ""
            XCTAssertFalse(arValue.isEmpty, "ar \(key)")
            XCTAssertFalse(enValue.isEmpty, "en \(key)")
            XCTAssertEqual(placeholderCount(arValue), placeholderCount(enValue), key)
        }
    }

    func testCodeReferencedKeysExist() throws {
        let ar = try table("ar")
        var keys = StoreCategory.allCases.map(\.titleKey) + City.allCases.map(\.titleKey)
        keys += SortOption.allCases.map(\.titleKey) + StoreAction.allCases.map(\.titleKey)
        for key in keys {
            XCTAssertNotNil(ar[key], key)
        }
    }

    func testFilterChipTitles() {
        let formatter = PriceFormatter(language: "en")
        XCTAssertEqual(DiscountFilter.fifty.title(formatter: formatter), "50%")
    }

    private func placeholderCount(_ s: String) -> Int {
        s.components(separatedBy: "%@").count + s.components(separatedBy: "$@").count
    }
}

final class InfoPlistLocalizationTests: XCTestCase {
    func testLocationPromptIsLocalizedInBothLanguages() throws {
        for (language, expected) in [("ar", "نستخدم موقعك لعرض أقرب العروض إليك فقط."),
                                     ("en", "We use your location only to show the deals nearest to you.")] {
            let path = try XCTUnwrap(Bundle.main.path(forResource: "InfoPlist", ofType: "strings",
                                                      inDirectory: nil, forLocalization: language))
            let table = try XCTUnwrap(NSDictionary(contentsOfFile: path) as? [String: String])
            XCTAssertEqual(table["NSLocationWhenInUseUsageDescription"], expected)
        }
        XCTAssertNotNil(Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription"))
    }
}
