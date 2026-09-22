import XCTest
@testable import DealsApp

/// WCAG contrast for every text/background pair we use, in light AND dark mode (CLAUDE.md §5).
final class ContrastTests: XCTestCase {
    private func luminance(_ hex: UInt32) -> Double {
        let channels = [16, 8, 0].map { Double((hex >> UInt32($0)) & 0xFF) / 255 }
        let linear = channels.map { $0 <= 0.03928 ? $0 / 12.92 : pow(($0 + 0.055) / 1.055, 2.4) }
        return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]
    }

    private func ratio(_ a: UInt32, _ b: UInt32) -> Double {
        let (hi, lo) = (max(luminance(a), luminance(b)), min(luminance(a), luminance(b)))
        return (hi + 0.05) / (lo + 0.05)
    }

    private func assertContrast(_ text: ThemeColor, on background: ThemeColor, name: String,
                                file: StaticString = #filePath, line: UInt = #line) {
        for (mode, fg, bg) in [("light", text.light, background.light), ("dark", text.dark, background.dark)] {
            let value = ratio(fg, bg)
            XCTAssertGreaterThanOrEqual(value, 4.5, "\(name) in \(mode) mode: \(value)", file: file, line: line)
        }
    }

    func testTextPairsMeetAA() {
        assertContrast(Palette.ink, on: Palette.background, name: "ink/background")
        assertContrast(Palette.ink, on: Palette.surface, name: "ink/surface")
        assertContrast(Palette.secondaryText, on: Palette.background, name: "secondary/background")
        assertContrast(Palette.secondaryText, on: Palette.surface, name: "secondary/surface")
        assertContrast(Palette.primary, on: Palette.background, name: "primary/background")
        assertContrast(Palette.primary, on: Palette.surface, name: "primary/surface")
        assertContrast(Palette.onPrimary, on: Palette.primary, name: "onPrimary/primary")
        assertContrast(Palette.dealAccentText, on: Palette.dealAccent, name: "badge")
    }

    func testPlaceholderColorsCarryWhiteText() {
        for hex in Palette.placeholders {
            XCTAssertGreaterThanOrEqual(ratio(0xFFFFFF, hex), 4.5, String(hex, radix: 16))
        }
    }
}
