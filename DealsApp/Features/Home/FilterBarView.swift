import SwiftUI

/// Category chips on the first row, discount chips on the second.
struct FilterBarView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.layoutDirection) private var layoutDirection

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            chipRow {
                FilterChip(title: L10n.tr("filter.all"), isSelected: viewModel.category == nil) {
                    viewModel.select(category: nil)
                }
                ForEach(StoreCategory.allCases) { category in
                    FilterChip(title: L10n.tr(category.titleKey),
                               isSelected: viewModel.category == category) {
                        viewModel.select(category: category)
                    }
                }
            }
            chipRow {
                ForEach(DiscountFilter.allCases) { filter in
                    FilterChip(title: filter.title(), isSelected: viewModel.discountFilter == filter) {
                        viewModel.select(discount: filter)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    /// iOS 16 horizontal ScrollViews misbehave in RTL: they open at the wrong end and
    /// `scrollTo` lands off-content. Workaround: run the scroll view left-to-right (which is
    /// reliable), lay the chips out reversed in RTL, and start scrolled to the right edge,
    /// where the first chip ("الكل") is. Chip text keeps the real layout direction.
    private func chipRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        let chips = content()
        let isRTL = layoutDirection == .rightToLeft
        return ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                // Spacers (8pt + 8pt spacing) give the 16pt edge inset; the first one marks
                // the start of the row, which sits at the right edge in RTL.
                HStack(spacing: 8) {
                    Color.clear.frame(width: 8, height: 1).id(Self.rowStart)
                    chips
                    Color.clear.frame(width: 8, height: 1)
                }
                .environment(\.layoutDirection, layoutDirection)
            }
            .environment(\.layoutDirection, .leftToRight)
            .onAppear {
                guard isRTL else { return }
                DispatchQueue.main.async { proxy.scrollTo(Self.rowStart, anchor: .trailing) }
            }
        }
    }

    private static let rowStart = "chipRow.start"
}
