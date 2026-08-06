// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VerkadaPassSDK",
    platforms: [
        // Must match the minos of the xcframework in `binaryTarget` below. Declaring a lower
        // floor than the binary lets consumers build and then crash at launch: dyld refuses a
        // framework whose minos exceeds the running OS.
        .iOS(.v13),
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
                // Clibsodium only. The `Sodium` Swift wrapper was dropped from the SDK because
                // its ObjC-visible classes collide with any other framework in the host app that
                // also links swift-sodium; attaching it here would put those same classes back
                // into the consumer's binary and undo that fix.
                .product(name: "Clibsodium", package: "swift-sodium"),
            ],
            path: "Sources/VerkadaPassSDKWrapper"
        ),
        .binaryTarget(
            name: "VerkadaPassSDK",
            url: "https://github.com/verkada/Verkada-Pass-iOS-SDK/releases/download/0.3/VerkadaPassSDK.xcframework.zip",
            checksum: "ad4ebee87d1af5cd561bd9e0c8564e29997c5f7dea0702f0ca097181f02815c3"
        ),
    ]
)
