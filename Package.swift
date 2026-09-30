// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VerkadaPassSDK",
    platforms: [
        // Must match the minos of the xcframework in `binaryTarget` below. Declaring a lower
        // floor than the binary lets consumers build and then crash at launch: dyld refuses a
        // framework whose minos exceeds the running OS. `release.sh` in the source repo rewrites
        // this line from that repo's manifest on every release, so it tracks the binary itself.
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
            url: "https://github.com/verkada/Verkada-Pass-iOS-SDK/releases/download/1.0.0/VerkadaPassSDK.xcframework.zip",
            checksum: "a424bdf744c28f86b6224b6ff060ecf76ce3b4f199da221a3f360ff10e5949ab"
        ),
    ]
)
