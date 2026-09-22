import SwiftUI

struct StoreCardView: View {
    let store: Store
    /// Meters from the user; `nil` without location permission or for online stores.
    var distance: Double?
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // The logo is decorative; at accessibility sizes the text needs the width.
            if !typeSize.isAccessibilitySize {
                RemoteOrPlaceholderImage(url: store.logoURL, placeholder: store.logoPlaceholder)
                    .frame(width: 56, height: 56)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: store.name.resolved())
                    .font(.headline)
                    .foregroundColor(Theme.ink)
                    .lineLimit(2)
                Text(verbatim: subtitle)
                    .font(.subheadline)
                    .foregroundColor(Theme.secondaryText)
                    .lineLimit(2)
                // Below the text rather than trailing, so long Arabic names aren't truncated.
                if let maxDiscount = store.maxDiscount {
                    DiscountBadge(percent: maxDiscount)
                        .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: Theme.minTapTarget)
        .background(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
            .fill(Theme.surface))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    /// "مطاعم · حي الملقا · 2.4 كم"
    private var subtitle: String {
        var parts = [L10n.tr(store.category.titleKey)]
        if let district = store.district {
            parts.append(district.resolved())
        }
        if let distance = distance {
            parts.append(DistanceFormatter().string(meters: distance))
        }
        return parts.joined(separator: " · ")
    }
}
