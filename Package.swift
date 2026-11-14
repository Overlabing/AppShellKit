// swift-tools-version: 6.2
import PackageDescription

// Swift 6 language mode (strict concurrency) is the default with tools 6.2. No third-party dependency. Kits depend on
// each other by patch range and apps pin exact: an app's exact ThemeKit or AppSupportKit pin resolves inside the range.
let package = Package(
    name: "AppShellKit",
    defaultLocalization: "en",
    platforms: [.macOS(.v26), .iOS(.v26)],
    products: [
        .library(name: "AppShellKit", targets: ["AppShellKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Overlabing/ThemeKit", .upToNextMinor(from: "0.2.10")),
        .package(url: "https://github.com/Overlabing/AppSupportKit", .upToNextMinor(from: "0.1.2")),
    ],
    targets: [
        .target(
            name: "AppShellKit",
            dependencies: [
                .product(name: "ColorCore", package: "ThemeKit"),
                .product(name: "ColorUI", package: "ThemeKit"),
                .product(name: "DesignKit", package: "ThemeKit"),
                .product(name: "Localization", package: "AppSupportKit"),
                .product(name: "Preferences", package: "AppSupportKit"),
                .product(name: "Spaces", package: "AppSupportKit"),
            ],
            resources: [.process("Resources")]),
        .testTarget(
            name: "AppShellKitTests",
            dependencies: [
                "AppShellKit",
                .product(name: "ColorCore", package: "ThemeKit"),
                .product(name: "Preferences", package: "AppSupportKit"),
                .product(name: "Spaces", package: "AppSupportKit"),
            ]),
    ]
)
