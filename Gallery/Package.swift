// swift-tools-version: 6.2
import Foundation
import PackageDescription

// A path dependency is named after its folder, whatever the clone is called.
let kit = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().lastPathComponent

// Renders the shells offscreen. Not part of the AppShellKit package: `swift run --package-path Gallery
// AppShellKitGallery <output directory>` on macOS.
let package = Package(
    name: "AppShellKitGallery",
    platforms: [.macOS(.v26)],
    dependencies: [
        .package(path: ".."),
        .package(url: "https://github.com/Overlabing/ThemeKit", .upToNextMinor(from: "0.2.10")),
        .package(url: "https://github.com/Overlabing/AppSupportKit", .upToNextMinor(from: "0.1.2")),
    ],
    targets: [
        .executableTarget(
            name: "AppShellKitGallery",
            dependencies: [
                .product(name: "AppShellKit", package: kit),
                .product(name: "ColorCore", package: "ThemeKit"),
                .product(name: "ColorUI", package: "ThemeKit"),
                .product(name: "DesignKit", package: "ThemeKit"),
                .product(name: "Preferences", package: "AppSupportKit"),
                .product(name: "Spaces", package: "AppSupportKit"),
            ]),
    ])
