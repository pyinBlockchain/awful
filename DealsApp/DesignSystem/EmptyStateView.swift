import SwiftUI

/// iOS 16 stand-in for `ContentUnavailableView` (see MIGRATION.md).
struct EmptyStateView: View {
    let symbol: String
    let messageKey: String
    var actionKey: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 44))
                .foregroundColor(Theme.secondaryText)
                .accessibilityHidden(true)
            Text(LocalizedStringKey(messageKey))
                .font(.body)
                .foregroundColor(Theme.ink)
                .multilineTextAlignment(.center)
            if let actionKey = actionKey, let action = action {
                Button(action: action) {
                    Text(LocalizedStringKey(actionKey))
                        .font(.body.weight(.semibold))
                        .frame(minHeight: Theme.minTapTarget)
                        .padding(.horizontal, 20)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.primary)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}
