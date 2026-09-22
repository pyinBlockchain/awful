import SwiftUI

/// The one bold element in the app (CLAUDE.md §5).
struct DiscountBadge: View {
    enum Style {
        case upTo     // store headline: "خصم حتى 40%"
        case compact  // item: "40%"
    }

    let percent: Int
    var style: Style = .upTo

    private let formatter = PriceFormatter()
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Text(verbatim: title)
            .font(style == .upTo ? .subheadline.weight(.bold) : .footnote.weight(.bold))
            .monospacedDigit()
            .foregroundColor(Theme.dealAccentText)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.dealAccent))
            // Never truncate the discount; at accessibility sizes let it wrap instead of
            // forcing its row wider than the screen.
            .fixedSize(horizontal: !typeSize.isAccessibilitySize, vertical: true)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: accessibilityText))
    }

    private var title: String {
        let value = formatter.percent(percent)
        return style == .upTo ? L10n.tr("badge.upTo", value) : value
    }

    // VoiceOver reads "%" inconsistently in Arabic, so spell it out: "خصم 40 بالمئة".
    private var accessibilityText: String {
        let number = formatter.number(Double(percent))
        return style == .upTo ? L10n.tr("a11y.discountUpTo", number) : L10n.tr("a11y.discount", number)
    }
}
