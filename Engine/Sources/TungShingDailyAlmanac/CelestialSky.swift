import Foundation
import TungShingCore

public enum CelestialSkyError: Error, Sendable, Hashable {
    case outsideSupportedDomain
}

/// An approximate, geocentric Sun/Moon reading and schematic heliocentric planet positions.
/// Evaluated at noon UTC by default or noon JST for a Japanese lunar page. Tokyo daylight uses
/// a separate local-midday declination sample. The base daily report keeps its own +08 noon.
/// These illustrative calculations never determine lunar dates, solar terms or almanac rules.
/// Method and precision: docs/design/CELESTIAL_SKY.md.
public struct CelestialSky: Sendable, Hashable {
    public static let algorithmRevision = "celestial-sky-2"
    public static let sampleUTCHour = 12
    public static let meanSynodicMonthDays = 29.530588853
    public let date: GregorianDate
    /// Geometric tropical longitude of date, in degrees in 0..<360. Nutation/aberration omitted.
    public let sunLongitude: Double
    /// Tropical sign: 0 Aries, 1 Taurus, … 11 Pisces. Approximate at noon, not a birth sign.
    public var sunSignIndex: Int { Int(sunLongitude / 30) }
    /// Illuminated fraction of the apparent lunar disk, 0...1; geocentric spherical model.
    public let moonIllumination: Double
    public let moonIsWaxing: Bool
    /// Phase-equivalent age: directed elongation / 360 × mean synodic month.
    /// An estimate, NOT elapsed time since the preceding astronomical conjunction.
    public let moonAgeDays: Double
    /// Elapsed uniform TT days since the preceding modeled Sun–Moon conjunction, sampled at
    /// the selected hour with frozen TT−clock=69.184s. Nil if the timestamp resource fails validation.
    /// This is separate from the phase-equivalent `moonAgeDays` used for diagram geometry.
    public let elapsedMoonAgeDays: Double?
    /// Heliocentric ecliptic longitudes in degrees, J2000 frame; Mercury, Venus, Earth, Mars,
    /// Jupiter, Saturn, Uranus, Neptune. Earth uses the Earth–Moon barycenter approximation.
    /// Orbital radii and sizes are intentionally left to the schematic renderer.
    public let planetLongitudes: [Double]
    /// Approximate sunrise-to-sunset duration at Tokyo, 35.6762° N, for the supplied civil date.
    /// Solar-center altitude −0.833° includes standard refraction and disk radius; flat horizon.
    /// Rounded minutes, using declination at 13:00 JST; not a local sunrise/set time service.
    public let tokyoDaylightMinutes: Int

    /// Days since conjunction at noon JST (03:00 UTC) for Japanese printed calendars.
    public static func lunarAgeAtJapaneseNoon(on date: GregorianDate) -> Double? {
        guard DailyAlmanacReader.firstDate <= date, date <= DailyAlmanacReader.lastDate else { return nil }
        return CelestialConjunctions.bundled?.elapsedDays(at: date, utcHour: 3)
    }

    public init(date: GregorianDate) throws(CelestialSkyError) {
        try self.init(date: date, utcHour: Self.sampleUTCHour)
    }

    /// Sample the same lunar geometry at 12:00 Japan Standard Time.
    public static func atJapaneseNoon(on date: GregorianDate) throws(CelestialSkyError) -> Self {
        try Self(date: date, utcHour: 3)
    }

    private init(date: GregorianDate, utcHour: Int) throws(CelestialSkyError) {
        guard DailyAlmanacReader.firstDate <= date, date <= DailyAlmanacReader.lastDate else {
            throw .outsideSupportedDomain
        }
        self.date = date
        elapsedMoonAgeDays = CelestialConjunctions.bundled?.elapsedDays(at: date, utcHour: utcHour)
        let jd = Double(date.dayID.value) + 2_440_587.5 + Double(utcHour) / 24
        let d = jd - 2_451_543.5 // Schlyter epoch: 1999-12-31 00:00 UT.
        let solarAnomaly = 356.0470 + 0.9856002585 * d
        let solarPerihelion = 282.9404 + 4.70935e-5 * d
        let sun = SkyMath.sun(d: d)
        sunLongitude = sun.longitude
        // Tokyo duration belongs to this Tokyo civil date; use 13:00 JST = 04:00 UTC
        // declination, independently of the edition's 12:00 UTC sky reading.
        let daylightD = d + Double(4 - utcHour) / 24
        let daylightSun = SkyMath.sun(d: daylightD)
        let obliquity = 23.4393 - 3.563e-7 * daylightD
        let declination = asin(SkyMath.sin(obliquity) * SkyMath.sin(daylightSun.longitude)) * 180 / .pi
        let cosHourAngle = (SkyMath.sin(-0.833) - SkyMath.sin(35.6762) * SkyMath.sin(declination))
            / (SkyMath.cos(35.6762) * SkyMath.cos(declination))
        tokyoDaylightMinutes = Int((8 * acos(min(1, max(-1, cosHourAngle))) * 180 / .pi).rounded())

        let lunarAnomaly = 115.3654 + 13.0649929509 * d
        let lunarNode = 125.1228 - 0.0529538083 * d
        let lunarPerihelion = 318.0634 + 0.1643573223 * d
        let moon = SkyMath.orbit(a: 60.2666, e: 0.054900, inclination: 5.1454,
                                 node: lunarNode, perihelion: lunarPerihelion, anomaly: lunarAnomaly)
        let elongation = lunarAnomaly + lunarPerihelion + lunarNode - solarAnomaly - solarPerihelion
        let f = lunarAnomaly + lunarPerihelion
        let m = lunarAnomaly, s = solarAnomaly, q = elongation
        // Schlyter §9: all twelve longitude and all five latitude perturbations.
        let longitudeCorrection = -1.274 * SkyMath.sin(m - 2*q) + 0.658 * SkyMath.sin(2*q)
            - 0.186 * SkyMath.sin(s) - 0.059 * SkyMath.sin(2*m - 2*q)
            - 0.057 * SkyMath.sin(m - 2*q + s) + 0.053 * SkyMath.sin(m + 2*q)
            + 0.046 * SkyMath.sin(2*q - s) + 0.041 * SkyMath.sin(m - s)
            - 0.035 * SkyMath.sin(q) - 0.031 * SkyMath.sin(m + s)
            - 0.015 * SkyMath.sin(2*f - 2*q) + 0.011 * SkyMath.sin(m - 4*q)
        let latitudeCorrection = -0.173 * SkyMath.sin(f - 2*q)
            - 0.055 * SkyMath.sin(m - f - 2*q) - 0.046 * SkyMath.sin(m + f - 2*q)
            + 0.033 * SkyMath.sin(f + 2*q) + 0.017 * SkyMath.sin(2*m + f)
        let directed = SkyMath.normalized(moon.longitude + longitudeCorrection - sunLongitude)
        let cosElongation = SkyMath.cos(directed) * SkyMath.cos(moon.latitude + latitudeCorrection)
        // Exact Sun–Moon–Earth triangle from the approximate vectors; lunar distance is in
        // Earth radii (Schlyter's AU conversion is 23450 Earth radii per AU).
        let lunarDistance = (moon.radius - 0.58 * SkyMath.cos(m - 2*q) - 0.46 * SkyMath.cos(2*q)) / 23_450
        let moonSunDistance = sqrt(sun.radius * sun.radius + lunarDistance * lunarDistance
                                   - 2 * sun.radius * lunarDistance * cosElongation)
        let cosPhase = (lunarDistance - sun.radius * cosElongation) / moonSunDistance
        moonIllumination = min(1, max(0, (1 + cosPhase) / 2))
        moonIsWaxing = directed < 180
        moonAgeDays = directed / 360 * Self.meanSynodicMonthDays

        let centuries = (jd - 2_451_545) / 36_525
        // Table 1's stated interval ends at 2050; use the long-range fit from 2050 onward.
        let longRange = date.year >= 2050
        planetLongitudes = (longRange ? SkyMath.longRangeElements : SkyMath.nearElements).enumerated().map { index, row in
            let values = (0..<6).map { row[$0] + row[$0 + 6] * centuries }
            var anomaly = values[3] - values[4]
            if longRange, index >= 4 {
                let extra = SkyMath.extraTerms[index - 4]
                anomaly += extra[0] * centuries * centuries + extra[1] * SkyMath.cos(extra[3] * centuries)
                    + extra[2] * SkyMath.sin(extra[3] * centuries)
            }
            return SkyMath.orbit(a: values[0], e: values[1], inclination: values[2], node: values[5],
                                 perihelion: values[4] - values[5], anomaly: anomaly).longitude
        }
    }
}

private enum SkyMath {
    static func sun(d: Double) -> (longitude: Double, latitude: Double, radius: Double) {
        orbit(a: 1, e: 0.016709 - 1.151e-9 * d, inclination: 0, node: 0,
              perihelion: 282.9404 + 4.70935e-5 * d, anomaly: 356.0470 + 0.9856002585 * d)
    }
    static func normalized(_ value: Double) -> Double {
        let remainder = value.truncatingRemainder(dividingBy: 360)
        return remainder < 0 ? remainder + 360 : remainder
    }
    static func sin(_ degrees: Double) -> Double { Foundation.sin(normalized(degrees) * .pi / 180) }
    static func cos(_ degrees: Double) -> Double { Foundation.cos(normalized(degrees) * .pi / 180) }

    static func orbit(a: Double, e: Double, inclination: Double, node: Double,
                      perihelion: Double, anomaly: Double) -> (longitude: Double, latitude: Double, radius: Double) {
        let m = normalized(anomaly) * .pi / 180
        var eccentric = m + e * Foundation.sin(m)
        for _ in 0..<12 {
            let correction = (eccentric - e * Foundation.sin(eccentric) - m) / (1 - e * Foundation.cos(eccentric))
            eccentric -= correction
            if abs(correction) < 1e-12 { break }
        }
        let x = a * (Foundation.cos(eccentric) - e)
        let y = a * sqrt(1 - e*e) * Foundation.sin(eccentric)
        let v = atan2(y, x) * 180 / .pi + perihelion
        let radius = hypot(x, y)
        let hx = radius * (cos(node) * cos(v) - sin(node) * sin(v) * cos(inclination))
        let hy = radius * (sin(node) * cos(v) + cos(node) * sin(v) * cos(inclination))
        let hz = radius * sin(v) * sin(inclination)
        return (normalized(atan2(hy, hx) * 180 / .pi), atan2(hz, hypot(hx, hy)) * 180 / .pi, radius)
    }

    // JPL Approximate Positions, Table 1: a,e,I,L,varpi,Omega then their rates / Julian century.
    static let nearElements: [[Double]] = [
        [0.38709927,0.20563593,7.00497902,252.25032350,77.45779628,48.33076593, 0.00000037,0.00001906,-0.00594749,149472.67411175,0.16047689,-0.12534081],
        [0.72333566,0.00677672,3.39467605,181.97909950,131.60246718,76.67984255, 0.00000390,-0.00004107,-0.00078890,58517.81538729,0.00268329,-0.27769418],
        [1.00000261,0.01671123,-0.00001531,100.46457166,102.93768193,0, 0.00000562,-0.00004392,-0.01294668,35999.37244981,0.32327364,0],
        [1.52371034,0.09339410,1.84969142,-4.55343205,-23.94362959,49.55953891, 0.00001847,0.00007882,-0.00813131,19140.30268499,0.44441088,-0.29257343],
        [5.20288700,0.04838624,1.30439695,34.39644051,14.72847983,100.47390909, -0.00011607,-0.00013253,-0.00183714,3034.74612775,0.21252668,0.20469106],
        [9.53667594,0.05386179,2.48599187,49.95424423,92.59887831,113.66242448, -0.00125060,-0.00050991,0.00193609,1222.49362201,-0.41897216,-0.28867794],
        [19.18916464,0.04725744,0.77263783,313.23810451,170.95427630,74.01692503, -0.00196176,-0.00004397,-0.00242939,428.48202785,0.40805281,0.04240589],
        [30.06992276,0.00859048,1.77004347,-55.12002969,44.96476227,131.78422574, 0.00026291,0.00005105,0.00035372,218.45945325,-0.32241464,-0.00508664]
    ]
    // JPL Tables 2a,2b, valid 3000 BC–3000 AD; never extrapolate Table 1 past its interval.
    static let longRangeElements: [[Double]] = [
        [0.38709843,0.20563661,7.00559432,252.25166724,77.45771895,48.33961819, 0,0.00002123,-0.00590158,149472.67486623,0.15940013,-0.12214182],
        [0.72332102,0.00676399,3.39777545,181.97970850,131.76755713,76.67261496, -0.00000026,-0.00005107,0.00043494,58517.81560260,0.05679648,-0.27274174],
        [1.00000018,0.01673163,-0.00054346,100.46691572,102.93005885,-5.11260389, -0.00000003,-0.00003661,-0.01337178,35999.37306329,0.31795260,-0.24123856],
        [1.52371243,0.09336511,1.85181869,-4.56813164,-23.91744784,49.71320984, 0.00000097,0.00009149,-0.00724757,19140.29934243,0.45223625,-0.26852431],
        [5.20248019,0.04853590,1.29861416,34.33479152,14.27495244,100.29282654, -0.00002864,0.00018026,-0.00322699,3034.90371757,0.18199196,0.13024619],
        [9.54149883,0.05550825,2.49424102,50.07571329,92.86136063,113.63998702, -0.00003065,-0.00032044,0.00451969,1222.11494724,0.54179478,-0.25015002],
        [19.18797948,0.04685740,0.77298127,314.20276625,172.43404441,73.96250215, -0.00020455,-0.00001550,-0.00180155,428.49512595,0.09266985,0.05739699],
        [30.06952752,0.00895439,1.77005520,304.22289287,46.68158724,131.78635853, 0.00006447,0.00000818,0.00022400,218.46515314,0.01009938,-0.00606302]
    ]
    static let extraTerms: [[Double]] = [
        [-0.00012452,0.06064060,-0.35635438,38.35125000],
        [0.00025899,-0.13434469,0.87320147,38.35125000],
        [0.00058331,-0.97731848,0.17689245,7.67025000],
        [-0.00041348,0.68346318,-0.10162547,7.67025000]
    ]
}
