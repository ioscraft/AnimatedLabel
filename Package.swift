// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AnimatedLabel",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "AnimatedLabel", targets: ["AnimatedLabel"])
    ],
    targets: [
        .target(
            name: "AnimatedLabel",
            path: "AnimatedLabel/Sources/AnimatedLabel"
        )
    ]
)
