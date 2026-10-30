import Foundation

/// Approximate civil sunrise/sunset hours for circadian scheduling without requiring location permission.
public enum SolarScheduleEstimator: Sendable {
    public struct Hours: Sendable, Equatable {
        public var dayStartHour: Double
        public var nightStartHour: Double
        public var sleepStartHour: Double

        public init(dayStartHour: Double, nightStartHour: Double, sleepStartHour: Double) {
            self.dayStartHour = dayStartHour
            self.nightStartHour = nightStartHour
            self.sleepStartHour = sleepStartHour
        }
    }

    /// Uses the calendar's time zone offset as a rough latitude proxy (mid-latitude default 45° when unknown).
    public static func estimatedHours(for date: Date = .now, timeZone: TimeZone = .current) -> Hours {
        let cal = Calendar(identifier: .gregorian)
        var utc = cal
        utc.timeZone = TimeZone(secondsFromGMT: 0)!
        let dayOfYear = utc.ordinality(of: .day, in: .year, for: date) ?? 180
        let lat = latitudeGuess(for: timeZone, date: date)
        let decl = solarDeclination(dayOfYear: dayOfYear)
        let sunrise = solarHourAngle(latitude: lat, declination: decl, rising: true)
        let sunset = solarHourAngle(latitude: lat, declination: decl, rising: false)
        let solarNoon = 12.0 - Double(timeZone.secondsFromGMT(for: date)) / 3600.0
        let rise = normalizeHour(solarNoon + sunrise)
        let set = normalizeHour(solarNoon + sunset)
        let sleep = normalizeHour(set + 2.0)
        return Hours(dayStartHour: rise, nightStartHour: set, sleepStartHour: min(sleep, 23.5))
    }

    private static func latitudeGuess(for timeZone: TimeZone, date: Date) -> Double {
        let hours = Double(timeZone.secondsFromGMT(for: date)) / 3600.0
        return max(-55, min(55, hours * 7.5))
    }

    private static func solarDeclination(dayOfYear: Int) -> Double {
        let n = Double(dayOfYear)
        return 23.44 * sin((360.0 / 365.0) * (n - 81.0) * .pi / 180.0)
    }

    private static func solarHourAngle(latitude: Double, declination: Double, rising: Bool) -> Double {
        let latRad = latitude * .pi / 180.0
        let decRad = declination * .pi / 180.0
        let cosH = -tan(latRad) * tan(decRad)
        let clamped = max(-1, min(1, cosH))
        let h = acos(clamped) * 180.0 / .pi / 15.0
        return rising ? -h : h
    }

    private static func normalizeHour(_ hour: Double) -> Double {
        var h = hour
        while h < 0 { h += 24 }
        while h >= 24 { h -= 24 }
        return (h * 2).rounded() / 2
    }
}
