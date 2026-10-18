// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LidDisconnect",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "LidDisconnect", targets: ["LidDisconnect"])
    ],
    targets: [
        .target(name: "LidDisconnectCore", resources: [.process("Resources")]),
        .target(name: "CPlatform", publicHeadersPath: "include"),
        .executableTarget(
            name: "LidDisconnect",
            dependencies: ["LidDisconnectCore", "CPlatform"],
            path: "Sources/LidDisconnect"
        ),
        .testTarget(name: "LidDisconnectCoreTests", dependencies: ["LidDisconnectCore"])
    ]
)
