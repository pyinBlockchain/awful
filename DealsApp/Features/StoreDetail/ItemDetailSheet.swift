import SwiftUI

struct ItemDetailSheet: View {
    let item: Item
    let store: Store
    @Environment(\.dismiss) private var dismiss

    private let dates = DateFormatterService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ItemImage(item: item, store: store, cornerRadius: Theme.cornerRadius)
                        .frame(height: 140)
                        .frame(maxWidth: .infinity)

                    Text(verbatim: item.name.resolved())
                        .font(.title2.weight(.bold))
                        .foregroundColor(Theme.ink)
                        .accessibilityAddTraits(.isHeader)

                    HStack(alignment: .center, spacing: 12) {
                        PriceLine(item: item, formatter: PriceFormatter(), font: .title3)
                        Spacer(minLength: 8)
                        if let percent = item.discountPercent {
                            DiscountBadge(percent: percent, style: .compact)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: L10n.tr("item.validUntil", dates.gregorian(item.validUntil)))
                            .font(.subheadline)
                        Text(verbatim: dates.hijri(item.validUntil))
                            .font(.footnote)
                    }
                    .foregroundColor(Theme.secondaryText)

                    if let description = item.description {
                        section(titleKey: "item.details", text: description.resolved())
                    }
                    if let terms = item.terms {
                        section(titleKey: "item.terms", text: terms.resolved())
                    }

                    Text("store.vatNote")
                        .font(.footnote)
                        .foregroundColor(Theme.secondaryText)
                }
                .padding(16)
            }
            .background(Theme.background)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("sheet.close") { dismiss() }
                        .frame(minHeight: Theme.minTapTarget)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func section(titleKey: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStringKey(titleKey))
                .font(.headline)
                .foregroundColor(Theme.ink)
            Text(verbatim: text)
                .font(.body)
                .foregroundColor(Theme.ink)
        }
    }
}
