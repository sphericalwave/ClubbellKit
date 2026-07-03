// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClubbellKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "ClubbellKit", targets: ["ClubbellKit"]),
    ],
    targets: [
        .target(name: "ClubbellKit"),
        .testTarget(name: "ClubbellKitTests", dependencies: ["ClubbellKit"]),
    ]
)
