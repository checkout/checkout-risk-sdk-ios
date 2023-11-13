// swift-tools-version:5.6

import PackageDescription

let package = Package(
    name: "Risk",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Risk",
            targets: ["Risk"]),
    ],
    dependencies: [
        .package(url: "https://github.com/fingerprintjs/fingerprintjs-pro-ios", .exact("2.2.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Risk",
            dependencies: [
                .product(
                    name: "FingerprintPro",
                    package: "fingerprintjs-pro-ios"),
            ],
            path: "Sources"),
        .testTarget(
            name: "RiskTests",
            dependencies: ["Risk"]),
    ]
)
