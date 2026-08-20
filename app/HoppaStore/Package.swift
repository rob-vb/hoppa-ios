// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HoppaStore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "HoppaStore", targets: ["HoppaStore"])
    ],
    dependencies: [
        // Relative, so the reference works on the VPS and on the Mac alike.
        .package(path: "../HoppaRules")
    ],
    targets: [
        // The seam. It imports HoppaRules, Foundation and Observation, and **never
        // SwiftUI**. That ban is what stops view state creeping back into the store.
        .target(name: "HoppaStore", dependencies: ["HoppaRules"]),
        .testTarget(
            name: "HoppaStoreTests",
            dependencies: ["HoppaStore"],
            // Read from disk by path, never bundled as resources.
            exclude: ["Fixtures"])
    ]
)
