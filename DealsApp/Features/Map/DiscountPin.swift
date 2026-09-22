import SwiftUI

/// Map marker showing the store's max discount, e.g. "40%".
struct DiscountPin: View {
    let pin: MapPin
    let isSelected: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            Text(verbatim: PriceFormatter().percent(pin.percent))
                .font(.footnote.weight(.bold))
                .monospacedDigit()
                .foregroundColor(isSelected ? Theme.onPrimary : Theme.dealAccentText)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Capsule().fill(isSelected ? Theme.primary : Theme.dealAccent))
                .overlay(Capsule().stroke(Color.white, lineWidth: 1.5))
            Triangle()
                .fill(isSelected ? Theme.primary : Theme.dealAccent)
                .frame(width: 10, height: 6)
        }
        .scaleEffect(isSelected && !reduceMotion ? 1.15 : 1)
        .animation(reduceMotion ? nil : .spring(response: 0.3), value: isSelected)
        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
        // The visible pin is small; the tappable area meets the 44pt minimum.
        .frame(minWidth: Theme.minTapTarget, minHeight: Theme.minTapTarget)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: L10n.tr("a11y.mapPin", pin.store.name.resolved(),
                                                   PriceFormatter().number(Double(pin.percent)))))
        .accessibilityAddTraits(.isButton)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
