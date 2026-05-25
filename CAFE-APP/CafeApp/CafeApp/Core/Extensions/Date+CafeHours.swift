import Foundation

extension Date {

    func isWithinOrderingWindow(config: CafeConfig) -> Bool {
        var cal = Calendar.current
        cal.timeZone = config.timezone

        guard
            let open = timeToday(hhmm: config.openTime, using: cal),
            let close = timeToday(hhmm: config.closeTime, using: cal)
        else { return false }

        let cutoff = close.addingTimeInterval(-Double(config.orderCutoffMinutes) * 60)
        return self >= open && self <= cutoff
    }

    func minutesUntilClose(config: CafeConfig) -> Int {
        var cal = Calendar.current
        cal.timeZone = config.timezone
        guard let close = timeToday(hhmm: config.closeTime, using: cal) else { return 0 }
        return max(0, Int(close.timeIntervalSince(self) / 60))
    }

    private func timeToday(hhmm: String, using cal: Calendar) -> Date? {
        let parts = hhmm.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        var components = cal.dateComponents([.year, .month, .day], from: self)
        components.hour = parts[0]
        components.minute = parts[1]
        components.second = 0
        return cal.date(from: components)
    }
}
