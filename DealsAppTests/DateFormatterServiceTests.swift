import XCTest
@testable import DealsApp

final class DateFormatterServiceTests: XCTestCase {
    private let day = DealDay(string: "2027-12-31")!

    func testArabicGregorianUsesWesternDigits() {
        let text = DateFormatterService(language: "ar").gregorian(day)
        XCTAssertEqual(text, "31 ديسمبر 2027")
    }

    func testEnglishGregorian() {
        XCTAssertEqual(DateFormatterService(language: "en").gregorian(day), "December 31, 2027")
    }

    func testHijriIsUmmAlQura() {
        let ar = DateFormatterService(language: "ar").hijri(day)
        let en = DateFormatterService(language: "en").hijri(day)
        // 31 Dec 2027 = 3 Sha'ban 1449 (Umm al-Qura).
        XCTAssertEqual(ar, "3 شعبان 1449 هـ")
        XCTAssertTrue(en.contains("1449") && en.contains("AH"), en)
    }

    /// Guard against the ar_SA default calendar (Hijri) leaking into the Gregorian line.
    func testGregorianLineStaysGregorianForSaudiRegion() {
        let text = DateFormatterService(language: "ar_SA").gregorian(day)
        XCTAssertTrue(text.contains("2027"), text)
    }

    func testArabicIndicOption() {
        let text = DateFormatterService(language: "ar", digitStyle: .arabicIndic).gregorian(day)
        XCTAssertTrue(text.contains("٢٠٢٧"), text)
    }
}
