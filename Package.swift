// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VerkadaPassSDK",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(
            name: "VerkadaPassSDK",
            targets: ["VerkadaPassSDK"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "VerkadaPassSDK",
            url: "https://github.com/verkada/Verkada-Pass-iOS-SDK/releases/download/0.0.1/VerkadaPassSDK.xcframework.zip",
            checksum: "5d64daab3a650f80c95a1fef8e316caaa5dae7bfb8b4801c3f86b340dbb16644"
        ),
    ]
)
