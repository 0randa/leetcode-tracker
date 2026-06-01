import Foundation

/// Parsing/formatting for the raw date strings the backend returns
/// (LocalDate "2026-06-01", Instant ISO-8601). All display is in UTC to match
/// the backend's start-of-day scheduling.
enum DateFmt {
    private static let utc = TimeZone(identifier: "UTC")!

    private static let localDate: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = utc
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let isoNoFrac: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static func date(fromLocal s: String) -> Date? { localDate.date(from: s) }

    static func date(fromInstant s: String) -> Date? {
        iso.date(from: s) ?? isoNoFrac.date(from: s)
    }

    /// "Mon" weekday for the Today header.
    static func weekday(_ date: Date) -> String { fmt(date, "EEE") }
    /// "Jun 1" for the Today header / schedule preview.
    static func monthDay(_ date: Date) -> String { fmt(date, "MMM d") }
    /// "May 28" for history rows (from an Instant).
    static func shortDate(fromInstant s: String) -> String {
        guard let d = date(fromInstant: s) else { return "" }
        return monthDay(d)
    }

    /// Single-letter weekday initials for the last `n` UTC days, oldest → newest
    /// ending today — matching the backend's weekly window order.
    static func lastNWeekdayInitials(_ n: Int) -> [String] {
        guard n > 0 else { return [] }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = utc
        let today = cal.startOfDay(for: Date())
        return (0..<n).reversed().compactMap { back in
            cal.date(byAdding: .day, value: -back, to: today)
        }.map { String(fmt($0, "EEE").prefix(1)) }
    }

    private static func fmt(_ date: Date, _ pattern: String) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = utc
        f.dateFormat = pattern
        return f.string(from: date)
    }
}
