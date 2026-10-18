// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LidDisconnect",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "LidDisconnect", targets: ["LidDisconnect"])
    ],
    targets: [
        .executableTarget(
            name: "LidDisconnect",
            path: "Sources/LidDisconnect"
        )
    ]
)
