import XCTest
@testable import DealsApp

final class ArabicSearchNormalizerTests: XCTestCase {
    private func n(_ s: String) -> String { ArabicSearchNormalizer.normalize(s) }

    func testAlefVariants() {
        XCTAssertEqual(n("أحمد"), "احمد")
        XCTAssertEqual(n("إسبريسو"), "اسبريسو")
        XCTAssertEqual(n("آيس"), "ايس")
        XCTAssertEqual(n("ٱلقهوة"), "القهوه")
    }

    func testYaaTaaMarbutaWawAndYaaHamza() {
        XCTAssertEqual(n("مستشفى"), "مستشفي")
        XCTAssertEqual(n("قهوة"), "قهوه")
        XCTAssertEqual(n("مؤسسة"), "موسسه")
        XCTAssertEqual(n("هيئة"), "هييه")
    }

    func testDiacriticsAndTatweelRemoved() {
        XCTAssertEqual(n("مَطْعَمٌ"), "مطعم")
        XCTAssertEqual(n("مطــــعم"), "مطعم")
        XCTAssertEqual(n("عُرُوض"), "عروض")
    }

    func testDecomposedHamzaIsHandled() {
        // Some keyboards/pastes send ا + combining hamza (U+0654) instead of أ.
        XCTAssertEqual(n("\u{0627}\u{0654}حمد"), "احمد")
    }

    func testEnglishCaseAndSpaces() {
        XCTAssertEqual(n("  Family   GRILL  "), "family grill")
        XCTAssertEqual(n("Café"), "cafe")
        XCTAssertEqual(n("مطعم\t\n النخلة"), "مطعم النخله")
    }

    func testArabicIndicDigitsAndInvisibleMarks() {
        XCTAssertEqual(n("خصم ٥٠٪"), "خصم 50٪")
        XCTAssertEqual(n("\u{200F}قهوة\u{200E}"), "قهوه")
    }

    func testMatchingIgnoresSpellingVariants() {
        XCTAssertTrue(ArabicSearchNormalizer.matches(query: "قهوه", in: ["قَهْوَة سعودية"]))
        XCTAssertTrue(ArabicSearchNormalizer.matches(query: "اسبريسو", in: ["إسبريسو"]))
        XCTAssertTrue(ArabicSearchNormalizer.matches(query: "", in: ["anything"]))
        XCTAssertFalse(ArabicSearchNormalizer.matches(query: "بيتزا", in: ["برجر"]))
    }

    func testEveryWordMustMatchSomewhere() {
        let fields = ["مطعم النخلة", "وجبة مشويات عائلية"]
        XCTAssertTrue(ArabicSearchNormalizer.matches(query: "النخله مشويات", in: fields))
        XCTAssertFalse(ArabicSearchNormalizer.matches(query: "النخله بيتزا", in: fields))
    }

    func testStoreSearchCoversNamesItemsCategoryAndTags() {
        let store = Fixtures.store(category: .cafes, nameAr: "مقهى الرمال", nameEn: "Al Rimal Café",
                                   tags: ["specialty coffee"],
                                   items: [Fixtures.item(nameAr: "كيكة التمر", nameEn: "Date cake")])
        XCTAssertTrue(StoreSearch.matches(store, query: "مقهي الرمال"))
        XCTAssertTrue(StoreSearch.matches(store, query: "rimal cafe"))
        XCTAssertTrue(StoreSearch.matches(store, query: "كيكه"))
        XCTAssertTrue(StoreSearch.matches(store, query: "date CAKE"))
        XCTAssertTrue(StoreSearch.matches(store, query: "مقاهي"), "Arabic category name")
        XCTAssertTrue(StoreSearch.matches(store, query: "cafés"), "English category name")
        XCTAssertTrue(StoreSearch.matches(store, query: "Specialty"))
        XCTAssertFalse(StoreSearch.matches(store, query: "فندق"))
    }
}
