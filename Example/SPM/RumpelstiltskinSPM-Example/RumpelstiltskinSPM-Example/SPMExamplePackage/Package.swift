// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SPMExamplePackage",
    defaultLocalization: "en",
    products: [        
        .library(
            name: "SPMExamplePackage",
            targets: ["SPMExamplePackage"]
        )
    ],
    dependencies: [
        .package(name: "RumpelstiltskinBuildPlugin", path: "../../../../../")
    ],
    targets: [
        .target(
            name: "SPMExamplePackage", dependencies: ["RumpelstiltskinBuildPlugin"]),

    ]
)
