// swift-tools-version: 6.2
import PackageDescription

// The app itself is built by XcodeGen (project.yml): an iOS app needs Info.plist keys and
// entitlements SwiftPM can't give it. This package holds the UI-free core, so `swift test`
// checks it on the Mac in seconds.
let package = Package(
    name: "JellyfinKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(name: "JellyfinKit", targets: ["JellyfinKit"])
    ],
    targets: [
        .target(
            name: "JellyfinKit",
            path: "jellyfin-ios/Kit"
        ),
        .testTarget(
            name: "JellyfinKitTests",
            dependencies: ["JellyfinKit"],
            path: "Tests/JellyfinKitTests",
            resources: [.copy("Fixtures")]
        )
    ]
)
