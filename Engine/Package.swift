// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "PaperAlmanacEngine",
    platforms: [.iOS("27.1"), .macOS("27.0")],
    products: [
        .library(name: "TungShingDailyAlmanac", type: .static, targets: ["TungShingDailyAlmanac"])
    ],
    targets: [
        .target(
            name: "TungShingDailyAlmanac",
            dependencies: ["TungShingCore", "TungShingData", "TungShingAlmanac", "TungShingJapanHolidays"],
            resources: [
                .copy("Resources/calendar-1901-2100-runtime.json"),
                .copy("Resources/calendar-1901-2100-context-terms.json"),
                .copy("Resources/almanac-1901-2100-differences.json"),
                .copy("Resources/celestial-japanese-context.json"),
                .copy("Resources/celestial-conjunctions.json"),
                .copy("Resources/japanese-microseason-starts.json"),
                .copy("Resources/vietnamese-months.json"),
                .copy("Resources/THIRD_PARTY_NOTICES.txt"),
                .copy("Resources/PROVENANCE.json"),
            ]
        ),
        .target(name: "TungShingCore", exclude: ["NOTICES.md"]),
        .target(name: "TungShingCalendar", dependencies: ["TungShingCore"]),
        .target(name: "TungShingData", dependencies: ["TungShingCore", "TungShingCalendar"]),
        .target(name: "TungShingAlmanac", dependencies: ["TungShingCore", "TungShingCalendar"], exclude: ["NOTICES.md"]),
        .target(
            name: "TungShingJapanHolidays",
            exclude: ["HolidayData/PROVENANCE.md"],
            resources: [.copy("HolidayData/JP_RUNTIME_DATA.json")]
        ),
    ]
)
