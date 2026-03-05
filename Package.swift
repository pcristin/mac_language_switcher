// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "mac_language_switcher",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MacLanguageSwitcher", targets: ["MacLanguageSwitcher"])
    ],
    targets: [
        .executableTarget(
            name: "MacLanguageSwitcher",
            linkerSettings: [
                .linkedFramework("ApplicationServices")
            ]
        ),
        .testTarget(
            name: "MacLanguageSwitcherTests",
            dependencies: ["MacLanguageSwitcher"]
        )
    ]
)
