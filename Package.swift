// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VectorNest",
    platforms: [
        .macOS(.v12), .iOS(.v15), .tvOS(.v16), .watchOS(.v9)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "VectorNest",
            targets: ["VectorNest"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/btfranklin/CleverBird", from: "3.2.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "VectorNest",
            dependencies: [
                .product(name: "CleverBird", package: "CleverBird"),
            ]),
        .testTarget(
            name: "VectorNestTests",
            dependencies: ["VectorNest"]),
    ]
)
