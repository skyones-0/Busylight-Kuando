// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "BusylightShared",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "BusylightShared",
            targets: ["BusylightShared"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "BusylightShared",
            dependencies: [],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "BusylightSharedTests",
            dependencies: ["BusylightShared"]
        ),
    ]
)
