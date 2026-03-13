import Foundation

enum DateKey {
    /// Returns a stable date key based on local timezone and a daily reset time (e.g. 04:00).
    static func todayKey(now: Date = Date(), resetHour: Int = 4, calendar: Calendar = .current) -> String {
        var cal = calendar
        cal.timeZone = .current
        let comps = cal.dateComponents([.year, .month, .day, .hour], from: now)
        let hour = comps.hour ?? 0

        // If before reset hour, treat as previous day.
        let baseDate: Date
        if hour < resetHour {
            baseDate = cal.date(byAdding: .day, value: -1, to: now) ?? now
        } else {
            baseDate = now
        }

        let day = cal.startOfDay(for: baseDate)
        let ymd = cal.dateComponents([.year, .month, .day], from: day)
        let y = ymd.year ?? 1970
        let m = ymd.month ?? 1
        let d = ymd.day ?? 1
        return String(format: "%04d-%02d-%02d", y, m, d)
    }
}
