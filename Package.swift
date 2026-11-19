// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "PaperAlmanac",
    platforms: [.macOS("27.0")],
    dependencies: [.package(path: "Engine")],
    targets: [
        .executableTarget(
            name: "DailyProof",
            dependencies: [.product(name: "TungShingDailyAlmanac", package: "Engine")],
            path: "DailyProof",
            resources: [.process("Fonts"), .process("Proverbs")]
        )
    ]
)
