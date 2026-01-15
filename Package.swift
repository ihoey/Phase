// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Phase",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Phase",
            targets: ["Phase"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Phase",
            dependencies: [],
            path: "Sources",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
