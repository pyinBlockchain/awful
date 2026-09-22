import SwiftUI

/// Tells people the deals may be out of date instead of failing silently.
struct OfflineBanner: View {
    var body: some View {
        Label("state.offline", systemImage: "wifi.slash")
            .font(.footnote.weight(.semibold))
            .foregroundColor(Theme.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .fill(Theme.surface))
            .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .stroke(Theme.separator, lineWidth: 1))
            .padding(.horizontal, 16)
            .accessibilityIdentifier("offlineBanner")
    }
}
