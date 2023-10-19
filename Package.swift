// swift-tools-version:5.6

import PackageDescription

let package = Package(
    name: "RiskIos",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "RiskIos",
            targets: ["RiskIos"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "RiskIos",
            path: "Sources"),
        .testTarget(
            name: "RiskIosTests",
            dependencies: ["RiskIos"]),
    ]
)
