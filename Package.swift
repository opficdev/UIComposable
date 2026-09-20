// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "UIComposable",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "UIComposable",
            targets: ["UIComposable"]
        )
    ],
    targets: [
        .target(name: "UIComposable"),
        .testTarget(
            name: "UIComposableTests",
            dependencies: ["UIComposable"]
        )
    ]
)
