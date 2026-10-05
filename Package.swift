// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "JellyfinIos",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v26)
    ],
    targets: [
        .executableTarget(
            name: "JellyfinIos",
            path: "jellyfin-ios",
            resources: [.process("Resources")]
        )
    ]
)
