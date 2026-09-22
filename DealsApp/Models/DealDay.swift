import Foundation

/// A calendar day with no time or zone, the way offers are published ("2026-10-31").
/// Kept apart from `Date` so parsing can never shift the day through the device time zone;
/// the zone is applied only when comparing against "now".
struct DealDay: Hashable, Comparable, Decodable, CustomStringConvertible {
    let year: Int
    let month: Int
    let day: Int

    init?(year: Int, month: Int, day: Int) {
        let components = DateComponents(year: year, month: month, day: day)
        guard components.isValidDate(in: Self.gregorian(in: TimeZone(identifier: "UTC")!)) else { return nil }
        self.year = year
        self.month = month
        self.day = day
    }

    /// Accepts strictly `yyyy-MM-dd`.
    init?(string: String) {
        let parts = string.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              let y = Int(parts[0]), let m = Int(parts[1]), let d = Int(parts[2]) else { return nil }
        self.init(year: y, month: m, day: d)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        guard let value = DealDay(string: raw) else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Expected yyyy-MM-dd, got \(raw)")
        }
        self = value
    }

    /// The first instant of this day in `timeZone`.
    func start(in timeZone: TimeZone) -> Date {
        let components = DateComponents(year: year, month: month, day: day)
        // Safe: validity was checked at init with the same (Gregorian) calendar.
        return Self.gregorian(in: timeZone).date(from: components)!
    }

    /// The first instant of the following day, i.e. the exclusive end of this day.
    func end(in timeZone: TimeZone) -> Date {
        let calendar = Self.gregorian(in: timeZone)
        return calendar.date(byAdding: .day, value: 1, to: start(in: timeZone))!
    }

    static func < (lhs: DealDay, rhs: DealDay) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    var description: String { String(format: "%04d-%02d-%02d", year, month, day) }

    private static func gregorian(in timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }
}
