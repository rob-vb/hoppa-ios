// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HoppaRules",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "HoppaRules", targets: ["HoppaRules"])
    ],
    targets: [
        // The rules. This target imports nothing — not Foundation. The clock
        // enters as a Timestamp argument; no rule may reach for one itself.
        .target(name: "HoppaRules"),
        // The tests may import Foundation: they encode JSON and compute dates.
        .testTarget(
            name: "HoppaRulesTests",
            dependencies: ["HoppaRules"],
            // Read and re-recorded from disk by path, never bundled as resources.
            exclude: ["Fixtures", "Snapshots"])
    ]
)
