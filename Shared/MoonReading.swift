import Foundation
import TungShingDailyAlmanac

/// The page uses the engine's noon UTC sample and a north-up lunar disk.
struct MoonReading {
    let info: DayInfo
    let sky: CelestialSky?
    let constellation: EveningConstellation
    let milestone: SpaceMilestone?

    let localSky: LocalEveningSky?

    init(_ page: PrintedDay, site: SkySite? = nil, zone: TimeZone = .autoupdatingCurrent) {
        info = DayInfo(page: page)
        sky = try? CelestialSky(date: page.date)
        if let site, let sky {
            localSky = LocalEveningSky(site: site, info: info, sunLongitude: sky.sunLongitude, zone: zone)
        } else {
            localSky = nil
        }
        constellation = localSky?.constellation ?? EveningConstellation(month: info.month)
        milestone = SpaceMilestone.anniversary(month: info.month, day: info.day, year: info.year)
    }

    var darkSky: Bool { (localSky?.darkEnough ?? true) && (sky.map { $0.moonIllumination <= 0.015 } ?? false) }

    var phase: String { Self.phase(of: sky) }

    static func phase(of sky: CelestialSky?) -> String {
        guard let sky else { return "Moon phase unavailable" }
        let fraction = sky.moonAgeDays / CelestialSky.meanSynodicMonthDays
        // Reserve the principal phase names for the nearest daily sample.
        let halfDay = 0.5 / CelestialSky.meanSynodicMonthDays
        if fraction <= halfDay || fraction >= 1 - halfDay { return "New moon" }
        if abs(fraction - 0.25) <= halfDay { return "First quarter" }
        if abs(fraction - 0.5) <= halfDay { return "Full moon" }
        if abs(fraction - 0.75) <= halfDay { return "Last quarter" }
        if sky.moonIsWaxing { return fraction < 0.25 ? "Waxing crescent" : "Waxing gibbous" }
        return fraction < 0.75 ? "Waning gibbous" : "Waning crescent"
    }

    var illumination: String? {
        sky.map { String(Int(($0.moonIllumination * 100).rounded())) + "% lit" }
    }

    var caption: String {
        if let milestone { return String(milestone.year) + "  ·  " + milestone.name }
        return constellation.rawValue + (localSky == nil ? "  ·  Northern sky" : "  ·  Local sky")
    }

    var note: String {
        if let milestone { return milestone.note }
        if let localSky { return localSky.note }
        if darkSky { return "Little moonlight tonight. " + constellation.notes[0] }
        if info.day.isMultiple(of: 2), let sky {
            switch (sky.moonIsWaxing, sky.moonIllumination < 0.5) {
            case (true, true): return "Look west after sunset for the slender, sunlit edge."
            case (true, false): return "The Moon is gaining light. Look for it in the evening sky."
            case (false, false): return "The Moon rises later each night as its bright face narrows."
            case (false, true): return "Look east before sunrise for the waning crescent."
            }
        }
        return constellation.notes[(info.day / 2) % constellation.notes.count]
    }

    var summary: String {
        [info.page.date.label, phase, illumination, caption, note].compactMap { $0 }.joined(separator: ". ")
    }
}

enum EveningConstellation: String, CaseIterable {
    case orion = "Orion", leo = "Leo", cygnus = "Cygnus", pegasus = "Pegasus"
    case crux = "Crux", grus = "Grus"

    init(month: Int) {
        switch month {
        case 3...5: self = .leo
        case 6...8: self = .cygnus
        case 9...11: self = .pegasus
        default: self = .orion
        }
    }

    var notes: [String] {
        switch self {
        case .crux: ["Trace the long axis of the Southern Cross."]
        case .grus: ["Find Alnair in the southern constellation of the Crane."]
        case .orion: ["Find Orion by the three stars in his belt.", "Look below Orion’s belt for the hazy glow of his sword.", "Compare ruddy Betelgeuse with blue-white Rigel."]
        case .leo: ["Trace the backward question mark of Leo’s mane.", "Regulus marks the bright foot of the Sickle in Leo.", "Follow Leo east from the Sickle to Denebola at the lion’s tail."]
        case .cygnus: ["Trace the Northern Cross along the body and wings of Cygnus.", "Deneb marks the swan’s tail in the Summer Triangle.", "Follow the neck of Cygnus to Albireo at its beak."]
        case .pegasus: ["Look for the four widely spaced stars of the Great Square.", "Three corners of the Great Square belong to Pegasus.", "Alpheratz links the Great Square to the chain of Andromeda."]
        }
    }
}

struct SpaceMilestone {
    enum Drawing { case voyager, hubble, eagle, sputnik }
    let year: Int
    let name: String
    let note: String
    let drawing: Drawing

    static func anniversary(month: Int, day: Int, year: Int) -> Self? {
        let entry: Self
        switch (month, day) {
        case (1, 24): entry = Self(year: 1986, name: "Voyager 2", note: "Voyager 2 swept past Uranus, the first spacecraft to visit the planet.", drawing: .voyager)
        case (4, 24): entry = Self(year: 1990, name: "Hubble", note: "Discovery carried the Hubble Space Telescope into orbit.", drawing: .hubble)
        case (7, 20): entry = Self(year: 1969, name: "Apollo 11", note: "Eagle touched down in the Sea of Tranquility with two astronauts aboard.", drawing: .eagle)
        case (8, 20): entry = Self(year: 1977, name: "Voyager 2", note: "Voyager 2 set out from Earth on its journey to the giant planets.", drawing: .voyager)
        case (8, 25): entry = Self(year: 1989, name: "Voyager 2", note: "Voyager 2 passed Neptune, the last planet on its outward journey.", drawing: .voyager)
        case (10, 4): entry = Self(year: 1957, name: "Sputnik 1", note: "A small metal sphere began circling Earth, broadcasting its radio pulse.", drawing: .sputnik)
        default: return nil
        }
        return year >= entry.year ? entry : nil
    }
}
