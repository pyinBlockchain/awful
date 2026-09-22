import XCTest
@testable import DealsApp

final class PriceFormatterTests: XCTestCase {
    private let arabic = PriceFormatter(language: "ar", digitStyle: .western)
    private let english = PriceFormatter(language: "en", digitStyle: .western)

    func testArabicWholeAmount() {
        XCTAssertEqual(arabic.string(sar: 120), "120 ر.س")
    }

    func testEnglishWholeAmount() {
        XCTAssertEqual(english.string(sar: 120), "SAR 120")
    }

    func testFractionalAmountsShowTwoDecimals() {
        XCTAssertEqual(arabic.string(sar: 12.5), "12.50 ر.س")
        XCTAssertEqual(english.string(sar: 38.5), "SAR 38.50")
        XCTAssertEqual(english.string(sar: 0.1 + 0.2), "SAR 0.30", "binary float noise is rounded to halalas")
    }

    func testThousandsGrouping() {
        XCTAssertEqual(arabic.string(sar: 1250), "1,250 ر.س")
        XCTAssertEqual(english.string(sar: 1299.99), "SAR 1,299.99")
    }

    func testDefaultIsWesternDigits() {
        XCTAssertEqual(PriceFormatter.defaultDigitStyle, .western)
    }

    func testArabicIndicDigitsOption() {
        let formatter = PriceFormatter(language: "ar", digitStyle: .arabicIndic)
        XCTAssertEqual(formatter.string(sar: 120), "١٢٠ ر.س")
        XCTAssertEqual(formatter.number(1250.5), "١٬٢٥٠٫٥٠")
    }
}

final class PercentFormatterTests: XCTestCase {
    func testEnglishPercent() {
        XCTAssertEqual(PriceFormatter(language: "en").percent(40), "40%")
    }

    func testArabicPercentIsBidiIsolated() {
        XCTAssertEqual(PriceFormatter(language: "ar").percent(40), "\u{2066}40%\u{2069}")
    }
}
