// swift-tools-version: 5.9

import PackageDescription

let package: Package = Package(
    name: "Rumpelstiltskin",
    defaultLocalization: "en",
    products: [
        .plugin(name: "RumpelstiltskinBuildPlugin", targets: ["RumpelstiltskinBuildPlugin"]),
        .executable(name: "RumpelstiltskinBin", targets: ["RumpelstiltskinBin"])
    ],
    targets: [
        .executableTarget(
            name: "RumpelstiltskinBin",
            path: ".",
            exclude: ["Example"],
            sources: ["main.swift"]
        ),
        .plugin(
            name: "RumpelstiltskinBuildPlugin",
            capability: .buildTool(),
            dependencies: ["RumpelstiltskinBin"],
            path: "Plugins",
            exclude: ["../Example"]
        ),
    ]
)
