// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "LumenBar",
    platforms: [.macOS(.v26)],
    targets: [
        // Rules and data logic with no SwiftUI, so tests run without the app.
        .target(name: "LumenBarKit"),
        .executableTarget(
            name: "LumenBar",
            dependencies: ["LumenBarKit"],
            // App code runs on the main thread unless you say otherwise.
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(name: "LumenBarKitTests", dependencies: ["LumenBarKit"]),
    ]
)
