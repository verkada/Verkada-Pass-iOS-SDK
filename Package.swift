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
            targets: ["VerkadaPassSDKWrapper"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.0"),
        .package(url: "https://github.com/jedisct1/swift-sodium.git",
                 revision: "cfd195c76882aa9b997560ca7cb95d72fbf5db00"),
    ],
    targets: [
        .target(
            name: "VerkadaPassSDKWrapper",
            dependencies: [
                .target(name: "VerkadaPassSDK"),
                .product(name: "KeychainAccess", package: "KeychainAccess"),
                .product(name: "Sodium", package: "swift-sodium"),
            ],
            path: "Sources/VerkadaPassSDKWrapper"
        ),
        .binaryTarget(
            name: "VerkadaPassSDK",
            url: "https://github.com/verkada/Verkada-Pass-iOS-SDK/releases/download/0.1/VerkadaPassSDK.xcframework.zip",
            checksum: "22dfba0c82604fbb3425f2d451a7c0788879ce74dbeaa42b3340adb147711239"
        ),
    ]
)
