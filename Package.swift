// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "R2Desk",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "R2Desk", targets: ["R2Desk"]),
        .library(name: "R2DeskCore", targets: ["R2DeskCore"])
    ],
    targets: [
        .executableTarget(
            name: "R2Desk",
            dependencies: ["R2DeskCore"],
            exclude: ["Resources/Info.plist"]
        ),
        .target(
            name: "R2DeskCore"
        ),
        .testTarget(
            name: "R2DeskCoreTests",
            dependencies: ["R2DeskCore"]
        )
    ]
)
