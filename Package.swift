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
            checksum: "623194282095ecd2da5ab56f2ab9b469dbdc1252c0031789c96b879f02898bba"
        ),
    ]
)
