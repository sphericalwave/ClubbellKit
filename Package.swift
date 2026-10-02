// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClubbellKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "ClubbellKit", targets: ["ClubbellKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/sphericalwave/EquipmentKit.git", branch: "main"),
    ],
    targets: [
        .target(name: "ClubbellKit", dependencies: ["EquipmentKit"]),
        .testTarget(name: "ClubbellKitTests", dependencies: ["ClubbellKit"]),
    ]
)
