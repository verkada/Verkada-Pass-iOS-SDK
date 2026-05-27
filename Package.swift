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
            url: "https://github.com/verkada/Verkada-Pass-iOS-SDK/releases/download/0.1/VerkadaPassSDK.xcframework.zip",
            checksum: "22dfba0c82604fbb3425f2d451a7c0788879ce74dbeaa42b3340adb147711239"
        ),
    ]
)
