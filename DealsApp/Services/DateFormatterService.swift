import Foundation

/// Offer dates: Gregorian first, Hijri (Umm al-Qura) as the secondary line (CLAUDE.md §3).
/// Uses the same digit setting as `PriceFormatter` so numbers look consistent on screen.
struct DateFormatterService {
    var language: String = AppLanguage.current
    var digitStyle: PriceFormatter.DigitStyle = PriceFormatter.defaultDigitStyle
    var timeZone: TimeZone = AppConfig.dealsTimeZone

    func gregorian(_ day: DealDay) -> String {
        string(for: day, calendar: .gregorian)
    }

    func hijri(_ day: DealDay) -> String {
        string(for: day, calendar: .islamicUmmAlQura)
    }

    private func string(for day: DealDay, calendar identifier: Calendar.Identifier) -> String {
        let formatter = DateFormatter()
        var calendar = Calendar(identifier: identifier)
        calendar.timeZone = timeZone
        // The calendar must be set explicitly: the ar_SA default is already Hijri, which would
        // silently make the "Gregorian" line Hijri on Saudi devices.
        formatter.calendar = calendar
        formatter.timeZone = timeZone
        let numbers = digitStyle == .western ? "latn" : "arab"
        formatter.locale = Locale(identifier: "\(language)@numbers=\(numbers)")
        if language.hasPrefix("ar") {
            // iOS's Arabic long style inserts a comma ("31 ديسمبر، 2027"); Saudi usage omits it.
            formatter.dateFormat = identifier == .gregorian ? "d MMMM y" : "d MMMM y G"
        } else {
            formatter.dateStyle = .long
            formatter.timeStyle = .none
        }
        return formatter.string(from: day.start(in: timeZone))
    }
}
