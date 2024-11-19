// swift-tools-version: 5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let pacakge = Package(
    name: "WMSView",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "WMSView",
            type: .dynamic,
            targets: ["WMSView"]
        )
    ],
    targets: [
        .target(
            name: "WMSView",
            path: "Sources",
            exclude: ["Info.plist"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "WMSViewTests",
            dependencies: ["WMSView"],
            path: "WMSViewTests"
        )
    ]
)
