// swift-tools-version: 5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let pacakge = Package(
    name: "MapView",
    platforms: [
        .iOS(.v14),
        .macOS(.v10_13)
    ],
    products: [
        .library(
            name: "MapView",
            type: .dynamic,
            targets: ["MapView"]
        )
    ],
    targets: [
        .target(
            name: "MapView",
            path: "Sources",
            exclude: ["Info.plist"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "MapViewTests",
            dependencies: ["MapView"],
            path: "MapViewTests"
        )
    ]
)
