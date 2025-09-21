// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Diagramming",
    platforms: [.macOS("15"), .custom("linux", versionString: "1")],

    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Diagramming",
            targets: ["Diagramming"]),
        .executable(
            name: "pictogram",
            targets: ["pictogram"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/openpoiesis/poietic-core", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Diagramming",
            dependencies: [
                .product(name: "PoieticCore", package: "poietic-core"),
            ],
        ),
        .executableTarget(
            name: "pictogram",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "Diagramming",
            ]
        ),
        .testTarget(
            name: "DiagrammingTests",
            dependencies: ["Diagramming"]
        ),
    ]
)
