import Foundation

/// Decodes an array, skipping elements that fail instead of failing the whole array.
struct LossyArray<Element: Decodable>: Decodable {
    private(set) var elements: [Element] = []
    private(set) var failures: [String] = []

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        while !container.isAtEnd {
            do {
                elements.append(try container.decode(Element.self))
            } catch {
                failures.append(String(describing: error))
                // A failed decode doesn't advance the cursor; consume the element explicitly.
                _ = try? container.decode(Skipped.self)
            }
        }
    }

    func logFailures(context: String) {
        for failure in failures {
            DataWarningLog.warn("Skipped malformed entry in \(context): \(failure)")
        }
    }

    private struct Skipped: Decodable {
        init(from decoder: Decoder) throws {}
    }
}
