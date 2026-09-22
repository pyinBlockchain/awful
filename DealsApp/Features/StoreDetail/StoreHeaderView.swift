import SwiftUI

struct StoreHeaderView: View {
    let store: Store

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .bottomLeading) {
                RemoteOrPlaceholderImage(
                    url: store.coverURL,
                    placeholder: PlaceholderImage(seed: store.id + "cover",
                                                  content: .symbol(store.category.symbolName),
                                                  cornerRadius: 0))
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
                    .clipped()

                RemoteOrPlaceholderImage(url: store.logoURL, placeholder: store.logoPlaceholder)
                    .frame(width: 72, height: 72)
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.background, lineWidth: 3))
                    .padding(.leading, 16)
                    .offset(y: 36)
            }
            .padding(.bottom, 36)

            VStack(alignment: .leading, spacing: 8) {
                Text(verbatim: store.name.resolved())
                    .font(.title2.weight(.bold))
                    .foregroundColor(Theme.ink)
                    .accessibilityAddTraits(.isHeader)
                Text(verbatim: subtitle)
                    .font(.subheadline)
                    .foregroundColor(Theme.secondaryText)
                HStack(spacing: 8) {
                    if let maxDiscount = store.maxDiscount {
                        DiscountBadge(percent: maxDiscount)
                    }
                    if let permit = store.discountPermitNumber {
                        LicensedBadge(permitNumber: permit)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var subtitle: String {
        var parts = [L10n.tr(store.category.titleKey)]
        if let district = store.district {
            parts.append(district.resolved())
        }
        return parts.joined(separator: " · ")
    }
}

/// Shown only when the merchant has a discount permit number on file.
private struct LicensedBadge: View {
    let permitNumber: String

    var body: some View {
        Label("store.licensed", systemImage: "checkmark.seal.fill")
            .font(.footnote.weight(.semibold))
            .foregroundColor(Theme.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().stroke(Theme.primary, lineWidth: 1))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: L10n.tr("a11y.licensed", permitNumber)))
    }
}
