import Foundation

struct SkySite: Equatable {
    let latitude: Double
    let longitude: Double
    static let key = "moon.approximateSite"
    static var saved: Self? {
        guard let pair = DailyTheme.defaults.array(forKey: key) as? [Double], pair.count == 2,
              (-90...90).contains(pair[0]), (-180...180).contains(pair[1]) else { return nil }
        return Self(latitude: pair[0], longitude: pair[1])
    }
}

struct LocalEveningSky {
    let constellation: EveningConstellation
    let note: String
    let darkEnough: Bool

    init?(site: SkySite, info: DayInfo, sunLongitude: Double, zone: TimeZone) {
        let calendar = CivilDay.calendar(zone: zone)
        guard let instant = calendar.date(from: DateComponents(year: info.year, month: info.month, day: info.day, hour: 21)) else { return nil }
        // Mean sidereal time and horizon conversion, following USNO Astronomical
        // Applications. Rounded bright-star positions suffice for a five-degree guide.
        let radians = Double.pi / 180
        let days = instant.timeIntervalSince1970 / 86400 - 10957.5
        let sidereal = (280.46061837 + 360.98564736629 * days + site.longitude).truncatingRemainder(dividingBy: 360)
        let lat = site.latitude * radians
        func horizon(ra: Double, dec: Double) -> (alt: Double, az: Double) {
            let ha = (sidereal - ra) * radians
            let d = dec * radians
            let vertical = sin(lat) * sin(d) + cos(lat) * cos(d) * cos(ha)
            let az = atan2(-sin(ha) * cos(d), cos(lat) * sin(d) - sin(lat) * cos(d) * cos(ha))
            return (asin(min(1, max(-1, vertical))) / radians, (az / radians + 360).truncatingRemainder(dividingBy: 360))
        }
        let lambda = sunLongitude * radians, obliquity = 23.44 * radians
        let solar = horizon(ra: atan2(sin(lambda) * cos(obliquity), cos(lambda)) / radians,
                            dec: asin(sin(lambda) * sin(obliquity)) / radians)
        let candidates = EveningConstellation.allCases.map { figure in
            let star = figure.guideStar
            return (figure, star.name, horizon(ra: star.ra, dec: star.dec))
        }
        guard let best = candidates.max(by: { $0.2.alt < $1.2.alt }) else { return nil }
        constellation = best.0
        darkEnough = solar.alt < -12
        let elevation = Int((best.2.alt / 5).rounded()) * 5
        let direction = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"][Int((best.2.az / 45).rounded()) % 8]
        let position = elevation >= 85 ? "nearly overhead" : "about \(elevation)° above the \(direction) horizon"
        note = "At 9 PM, \(best.1) is \(position)." + (darkEnough ? "" : " The sky is still bright.")
    }
}

extension EveningConstellation {
    /// Bright guide stars, approximate J2000 right ascension and declination in degrees.
    var guideStar: (name: String, ra: Double, dec: Double) {
        switch self {
        case .orion: ("Rigel", 78.63, -8.20)
        case .leo: ("Regulus", 152.09, 11.97)
        case .cygnus: ("Deneb", 310.36, 45.28)
        case .pegasus: ("Markab", 346.19, 15.21)
        case .crux: ("Acrux", 186.65, -63.10)
        case .grus: ("Alnair", 332.06, -46.96)
        }
    }
}
