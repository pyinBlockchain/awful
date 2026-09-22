import SwiftUI

/// Shown whenever a store or item has no image. We never use real brand logos.
struct PlaceholderImage: View {
    enum Content {
        case initials(String)
        case symbol(String)
    }

    let seed: String
    let content: Content
    var cornerRadius: CGFloat = 12

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Theme.placeholderColor(for: seed))
            switch content {
            case .initials(let text):
                Text(verbatim: text)
                    .font(.title2.weight(.bold))
                    .minimumScaleFactor(0.5)
                    .foregroundColor(.white)
                    .padding(4)
            case .symbol(let name):
                Image(systemName: name)
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .accessibilityHidden(true)
    }
}

/// Loads a remote image when there is one, otherwise falls back to a placeholder.
struct RemoteOrPlaceholderImage: View {
    let url: URL?
    let placeholder: PlaceholderImage

    var body: some View {
        if let url = url {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    placeholder
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: placeholder.cornerRadius, style: .continuous))
        } else {
            placeholder
        }
    }
}

extension Store {
    /// Arabic letters join, so two Arabic initials would read as a word; use one letter.
    /// Generic leading words are skipped ("مطعم النخلة" → "ن", not "م"), as is "ال".
    func initials(language: String = AppLanguage.current) -> String {
        let words = name.resolved(language: language).split(separator: " ").map(String.init)
        if language == "ar" {
            let distinctive = words.first { !Self.genericArabicWords.contains($0) } ?? words.first
            guard let word = distinctive else { return "" }
            let stem = word.hasPrefix("ال") && word.count > 2 ? String(word.dropFirst(2)) : word
            return String(stem.prefix(1))
        }
        return words.prefix(2).compactMap(\.first).map { String($0).uppercased() }.joined()
    }

    private static let genericArabicWords: Set<String> = [
        "مطعم", "مطبخ", "مقهى", "كافيه", "متجر", "فندق", "نزل", "نُزل", "صالون", "سبا", "حلاق", "مركز", "بيت",
    ]

    var logoPlaceholder: PlaceholderImage {
        PlaceholderImage(seed: id, content: .initials(initials()))
    }
}
