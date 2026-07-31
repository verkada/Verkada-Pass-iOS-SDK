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
            // The binary target is exposed directly so consumers import the
            // prebuilt module itself. The wrapper cannot re-export it: see
            // Sources/VerkadaPassSDKWrapper/Reexport.swift.
            targets: ["VerkadaPassSDKWrapper", "VerkadaPassSDK"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.0"),
        .package(url: "https://github.com/jedisct1/swift-sodium.git",
                 from: "0.11.0"),
    ],
    targets: [
        .target(
            name: "VerkadaPassSDKWrapper",
            dependencies: [
                .target(name: "VerkadaPassSDK"),
                .product(name: "KeychainAccess", package: "KeychainAccess"),
                .product(name: "Sodium", package: "swift-sodium"),
                .product(name: "Clibsodium", package: "swift-sodium"),
            ],
            path: "Sources/VerkadaPassSDKWrapper"
        ),
        .binaryTarget(
            name: "VerkadaPassSDK",
            url: "https://github.com/verkada/Verkada-Pass-iOS-SDK/releases/download/0.4.0/VerkadaPassSDK.xcframework.zip",
            checksum: "31a158e393c2bd45f8c86fde77878fe78b07de9cfd05ce691924ec270fa30b6a"
        ),
    ]
)
