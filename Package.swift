// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "biblescraper",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.7.0")
    ],
    targets: [
        .executableTarget(
            name: "biblescraper",
            dependencies: ["SwiftSoup"]
        ),
    ]
)
