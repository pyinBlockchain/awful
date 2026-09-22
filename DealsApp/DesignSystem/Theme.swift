import SwiftUI
import UIKit

/// Raw light/dark values, kept separate from `Color` so tests can check contrast ratios.
struct ThemeColor {
    let light: UInt32
    let dark: UInt32

    var color: Color {
        Color(UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

/// Every brand color lives here (CLAUDE.md §5). Rebranding = edit this + project.yml.
enum Palette {
    static let ink = ThemeColor(light: 0x1A2233, dark: 0xECEFF4)
    static let secondaryText = ThemeColor(light: 0x566074, dark: 0xA9B2C1)
    static let primary = ThemeColor(light: 0x0F6B4F, dark: 0x4FB490)
    /// Text/icons on `primary`. White fails contrast on the lighter dark-mode green (2.5:1),
    /// so dark mode uses deep ink instead (7.2:1).
    static let onPrimary = ThemeColor(light: 0xFFFFFF, dark: 0x0F1522)
    /// Saffron is reserved for discount badges so percentages are the one bold thing on screen.
    static let dealAccent = ThemeColor(light: 0xF2A900, dark: 0xF2A900)
    /// Ink on saffron in both modes: white on saffron fails contrast.
    static let dealAccentText = ThemeColor(light: 0x1A2233, dark: 0x1A2233)
    static let surface = ThemeColor(light: 0xF3EEE6, dark: 0x1D2535)
    static let background = ThemeColor(light: 0xFFFFFF, dark: 0x0F1522)
    static let separator = ThemeColor(light: 0xE2DBD0, dark: 0x2C3547)

    /// Muted tones for generated placeholders; each carries white text at ≥ 4.5:1.
    static let placeholders: [UInt32] = [0x0F6B4F, 0x2F5D8A, 0x8A4B2F, 0x6B4F8A, 0x4F6B2F, 0x8A2F4B]
}

enum Theme {
    static let ink = Palette.ink.color
    static let secondaryText = Palette.secondaryText.color
    static let primary = Palette.primary.color
    static let onPrimary = Palette.onPrimary.color
    static let dealAccent = Palette.dealAccent.color
    static let dealAccentText = Palette.dealAccentText.color
    static let surface = Palette.surface.color
    static let background = Palette.background.color
    static let separator = Palette.separator.color

    static let cornerRadius: CGFloat = 14
    static let minTapTarget: CGFloat = 44

    /// Stable across launches (unlike `hashValue`), so a store keeps its color.
    static func placeholderColor(for seed: String) -> Color {
        let hash = seed.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0x7FFF_FFFF }
        let hex = Palette.placeholders[hash % Palette.placeholders.count]
        return ThemeColor(light: hex, dark: hex).color
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: 1)
    }
}
