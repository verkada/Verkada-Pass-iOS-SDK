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
                // Clibsodium (the C library) only — NOT swift-sodium's `Sodium` Swift wrapper.
                // The wrapper compiles ObjC-visible Swift classes (GenericHash.Stream,
                // SecretStream.XChaCha20Poly1305.Push/PullStream) into every binary that links it,
                // so apps embedding this framework next to another framework that also links
                // swift-sodium got "Class _TtCV6Sodium… is implemented in both …" from the ObjC
                // runtime. The SDK calls libsodium's C API directly as of 0.5.0.
                .product(name: "Clibsodium", package: "swift-sodium"),
            ],
            path: "Sources/VerkadaPassSDKWrapper"
        ),
        .binaryTarget(
            name: "VerkadaPassSDK",
            url: "https://github.com/verkada/Verkada-Pass-iOS-SDK/releases/download/0.5/VerkadaPassSDK.xcframework.zip",
            checksum: "d5d1517f08a95164b37c52c281c08b110c769c503dac2ea4f678ab3e15d08e78"
        ),
    ]
)
