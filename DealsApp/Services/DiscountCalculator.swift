import Foundation

/// Why an item is hidden from the UI. Surfaced as a DEBUG data warning.
enum ItemRejection: Equatable {
    case invalidOriginalPrice
    case invalidDiscountedPrice
    case notDiscounted
    case discountOutOfRange(exactPercent: Double)
    case expired
    case notStarted
}

/// Discount math and the validity rules from CLAUDE.md §1 and decision log §11.1–3.
///
/// All math runs on integer halalas (1 SAR = 100 halalas). Floating-point percentages
/// drift at exactly the boundaries we care about (20.000000000000004 vs 20), and Saudi
/// advertising rules require the claimed discount to be accurate.
struct DiscountCalculator {
    static let minPercent = 20
    static let maxPercent = 50

    /// Offer days are Riyadh days regardless of where the device is.
    var timeZone: TimeZone = AppConfig.dealsTimeZone

    static func halalas(_ sar: Double) -> Int {
        Int((sar * 100).rounded())
    }

    /// The exact discount, for logging and diagnostics. `nil` when prices make no sense.
    static func exactPercent(original: Double, discounted: Double) -> Double? {
        guard case let (o, d)? = sanePrices(original, discounted) else { return nil }
        return Double(o - d) * 100 / Double(o)
    }

    /// The percent shown to users: rounded DOWN so we never overstate (49.9% → 49%).
    static func displayPercent(original: Double, discounted: Double) -> Int? {
        guard case let (o, d)? = sanePrices(original, discounted) else { return nil }
        // Integer division of positive values is floor.
        return (o - d) * 100 / o
    }

    /// Validates the EXACT percent against 20...50 inclusive, without any rounding,
    /// so 19.5% is rejected and 50.1% is rejected even though it would display as 50%.
    static func isInAllowedRange(original: Double, discounted: Double) -> Bool {
        guard case let (o, d)? = sanePrices(original, discounted) else { return false }
        let scaledDiscount = (o - d) * 100
        return scaledDiscount >= minPercent * o && scaledDiscount <= maxPercent * o
    }

    /// `nil` means the item is valid and may be shown.
    func rejection(for item: Item, at now: Date) -> ItemRejection? {
        let o = Self.halalas(item.originalPrice)
        let d = Self.halalas(item.discountedPrice)
        if o <= 0 { return .invalidOriginalPrice }
        if d < 0 { return .invalidDiscountedPrice }
        if d >= o { return .notDiscounted }
        if !Self.isInAllowedRange(original: item.originalPrice, discounted: item.discountedPrice) {
            let exact = Self.exactPercent(original: item.originalPrice, discounted: item.discountedPrice) ?? 0
            return .discountOutOfRange(exactPercent: exact)
        }
        if now >= item.validUntil.end(in: timeZone) { return .expired }
        if now < item.validFrom.start(in: timeZone) { return .notStarted }
        return nil
    }

    private static func sanePrices(_ original: Double, _ discounted: Double) -> (Int, Int)? {
        let o = halalas(original)
        let d = halalas(discounted)
        guard o > 0, d >= 0, d < o else { return nil }
        return (o, d)
    }
}
