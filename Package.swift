// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "s2j-cozy-brew",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "CozyBrewCore", targets: ["CozyBrewCore"]),
        .library(name: "CozyBrewService", targets: ["CozyBrewService"]),
        .library(name: "CozyBrewUIComponents", targets: ["CozyBrewUIComponents"]),
    ],
    dependencies: [
        // S2J packages
        .package(url: "https://github.com/stein2nd/s2j-source-list.git", branch: "main"),
        .package(url: "https://github.com/stein2nd/s2j-about-window.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "CozyBrewCore",
            dependencies: []
        ),
        .target(
            name: "CozyBrewService",
            dependencies: ["CozyBrewCore"]
        ),
        .target(
            name: "CozyBrewUIComponents",
            dependencies: [
                "CozyBrewService",
                .product(name: "S2JSourceList", package: "s2j-source-list"),
                .product(name: "S2JAboutWindow", package: "s2j-about-window"),
            ]
        ),
        .testTarget(
            name: "CozyBrewCoreTests",
            dependencies: ["CozyBrewCore"]
        ),
        .testTarget(
            name: "CozyBrewServiceTests",
            dependencies: ["CozyBrewService", "CozyBrewCore"]
        ),
    ]
)
