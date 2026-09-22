import SwiftUI

struct StoreActionsView: View {
    @ObservedObject var viewModel: StoreDetailViewModel
    @Environment(\.openURL) private var openURL
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        // Four side-by-side buttons can't fit accessibility text sizes; stack them instead.
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 8))
            : AnyLayout(HStackLayout(spacing: 8))
        return layout {
            ForEach(viewModel.availableActions) { action in
                Button {
                    guard let url = viewModel.url(for: action) else { return }
                    viewModel.didPerform(action)
                    openURL(url)
                } label: {
                    label(for: action)
                        .foregroundColor(Theme.primary)
                        .frame(maxWidth: .infinity, minHeight: 64)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Theme.surface))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("action.\(action.rawValue)")
            }
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func label(for action: StoreAction) -> some View {
        if typeSize.isAccessibilitySize {
            HStack(spacing: 12) {
                Image(systemName: action.symbolName)
                Text(LocalizedStringKey(action.titleKey))
                    .font(.body.weight(.semibold))
            }
            .padding(12)
        } else {
            VStack(spacing: 6) {
                // Fixed icon box so labels line up even though SF Symbol heights differ.
                Image(systemName: action.symbolName)
                    .font(.title3)
                    .frame(height: 24)
                Text(LocalizedStringKey(action.titleKey))
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }
}

struct CouponCardView: View {
    @ObservedObject var viewModel: StoreDetailViewModel
    let code: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("store.coupon.title")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Theme.secondaryText)
            HStack(spacing: 12) {
                Text(verbatim: code)
                    .font(.title3.monospaced().weight(.bold))
                    .foregroundColor(Theme.ink)
                    .textSelection(.enabled)
                    .environment(\.layoutDirection, .leftToRight) // codes are Latin; keep them LTR
                    .accessibilityIdentifier("coupon.code")
                Spacer(minLength: 8)
                Button {
                    withAnimation(reduceMotion ? nil : .easeInOut) { viewModel.copyCoupon() }
                } label: {
                    Label("store.coupon.copy", systemImage: "doc.on.doc")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.onPrimary)
                        .frame(minHeight: Theme.minTapTarget)
                        .padding(.horizontal, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.primary)
                .accessibilityIdentifier("coupon.copy")
            }
            if viewModel.couponCopied {
                Label("store.coupon.copied", systemImage: "checkmark.circle.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(Theme.primary)
                    .accessibilityIdentifier("coupon.copied")
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            .foregroundColor(Theme.separator))
        .padding(.horizontal, 16)
        .onChange(of: viewModel.couponCopied) { copied in
            if copied {
                UIAccessibility.post(notification: .announcement, argument: L10n.tr("store.coupon.copied"))
            }
        }
    }
}
