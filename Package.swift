// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DSWaveformImage",
    platforms: [
        .iOS(.v13),
        .macOS(.v11),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "DSWaveformImage",
            targets: ["DSWaveformImage"]),
        .library(
            name: "DSWaveformImageViews",
            targets: ["DSWaveformImageViews"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .target(name: "DSWaveformImage"),
        .target(
            name: "DSWaveformImageViews",
            dependencies: ["DSWaveformImage"]
        ),
    ]
)
