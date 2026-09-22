import SwiftUI
import UIKit

/// Every brand color lives here (CLAUDE.md §5). Rebranding = edit this file + project.yml.
enum Theme {
    static let ink = Color(light: 0x1A2233, dark: 0xECEFF4)
    static let secondaryText = Color(light: 0x566074, dark: 0xA9B2C1)
    static let primary = Color(light: 0x0F6B4F, dark: 0x4FB490)
    /// Saffron is reserved for discount badges so percentages are the one bold thing on screen.
    static let dealAccent = Color(light: 0xF2A900, dark: 0xF2A900)
    /// Ink on saffron in both modes: white on saffron fails contrast.
    static let dealAccentText = Color(light: 0x1A2233, dark: 0x1A2233)
    static let surface = Color(light: 0xF3EEE6, dark: 0x1D2535)
    static let background = Color(light: 0xFFFFFF, dark: 0x0F1522)
    static let separator = Color(light: 0xE2DBD0, dark: 0x2C3547)

    static let cornerRadius: CGFloat = 14
    static let minTapTarget: CGFloat = 44

    /// Muted tones for generated placeholders; chosen to carry white text at AA contrast.
    private static let placeholderPalette: [Color] = [
        Color(light: 0x0F6B4F, dark: 0x0F6B4F), Color(light: 0x2F5D8A, dark: 0x2F5D8A),
        Color(light: 0x8A4B2F, dark: 0x8A4B2F), Color(light: 0x6B4F8A, dark: 0x6B4F8A),
        Color(light: 0x4F6B2F, dark: 0x4F6B2F), Color(light: 0x8A2F4B, dark: 0x8A2F4B),
    ]

    /// Stable across launches (unlike `hashValue`), so a store keeps its color.
    static func placeholderColor(for seed: String) -> Color {
        let hash = seed.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0x7FFF_FFFF }
        return placeholderPalette[hash % placeholderPalette.count]
    }
}

extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: 1)
    }
}
