import SwiftUI

struct ItemRowView: View {
    let item: Item
    let store: Store

    private let prices = PriceFormatter()
    private let dates = DateFormatterService()
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if !typeSize.isAccessibilitySize {
                ItemImage(item: item, store: store)
                    .frame(width: 64, height: 64)
            }

            VStack(alignment: .leading, spacing: 4) {
                // At accessibility sizes the text needs the full width: badge moves up here
                // and the decorative image is dropped.
                if typeSize.isAccessibilitySize, let percent = item.discountPercent {
                    DiscountBadge(percent: percent, style: .compact)
                }
                Text(verbatim: item.name.resolved())
                    .font(.body.weight(.semibold))
                    .foregroundColor(Theme.ink)
                    .multilineTextAlignment(.leading)
                PriceLine(item: item, formatter: prices)
                Text(verbatim: L10n.tr("item.validUntil", dates.gregorian(item.validUntil)))
                    .font(.caption)
                    .foregroundColor(Theme.secondaryText)
                Text(verbatim: dates.hijri(item.validUntil))
                    .font(.caption2)
                    .foregroundColor(Theme.secondaryText)
            }

            Spacer(minLength: 8)

            if !typeSize.isAccessibilitySize, let percent = item.discountPercent {
                DiscountBadge(percent: percent, style: .compact)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
            .fill(Theme.surface))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

struct PriceLine: View {
    let item: Item
    let formatter: PriceFormatter
    var font: Font = .body

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))
        return layout {
            Text(verbatim: formatter.string(sar: item.discountedPrice))
                .font(font.weight(.bold))
                .foregroundColor(Theme.primary)
                .accessibilityLabel(Text(verbatim: L10n.tr("a11y.discountedPrice",
                                                           formatter.string(sar: item.discountedPrice))))
            Text(verbatim: formatter.string(sar: item.originalPrice))
                .font(.subheadline)
                .strikethrough()
                .foregroundColor(Theme.secondaryText)
                // Strikethrough is invisible to VoiceOver; say it in words.
                .accessibilityLabel(Text(verbatim: L10n.tr("a11y.originalPrice",
                                                           formatter.string(sar: item.originalPrice))))
        }
        .monospacedDigit()
    }
}

struct ItemImage: View {
    let item: Item
    let store: Store
    var cornerRadius: CGFloat = 12

    var body: some View {
        RemoteOrPlaceholderImage(
            url: item.imageURL,
            placeholder: PlaceholderImage(seed: item.id, content: .symbol(store.category.symbolName),
                                          cornerRadius: cornerRadius))
    }
}
