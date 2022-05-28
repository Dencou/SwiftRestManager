// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RestManager",
    platforms: [
        .iOS(.v14),
        .tvOS(.v14),
        .macOS(.v10_15)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "RestManager",
            targets: ["RestManager"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/immobiliare/RealHTTP", .branch("main")),
        .package(url: "https://github.com/AFNetworking/AFNetworking.git", .upToNextMajor(from: "4.0.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "RestManager",
            dependencies: ["RealHTTP", "AFNetworking"]),
        .testTarget(
            name: "RestManagerTests",
            dependencies: ["RestManager", "RealHTTP", "AFNetworking"]),
    ]
)
