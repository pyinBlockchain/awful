import Foundation

/// A discounted product or service inside a store. Prices are SAR, VAT-inclusive.
struct Item: Decodable, Identifiable, Hashable {
    let id: String
    let name: LocalizedText
    let description: LocalizedText?
    let originalPrice: Double
    let discountedPrice: Double
    let validFrom: DealDay
    let validUntil: DealDay
    let terms: LocalizedText?
    let imageURL: URL?
}

extension Item {
    /// The percent shown to users, floored so we never advertise more than the real discount.
    /// Never stored in data (CLAUDE.md §9). `nil` when the prices make no sense.
    var discountPercent: Int? {
        DiscountCalculator.displayPercent(original: originalPrice, discounted: discountedPrice)
    }

    func isValid(at now: Date, calculator: DiscountCalculator = DiscountCalculator()) -> Bool {
        calculator.rejection(for: self, at: now) == nil
    }
}
