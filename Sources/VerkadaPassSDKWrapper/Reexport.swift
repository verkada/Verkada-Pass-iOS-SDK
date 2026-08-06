// Carrier target: exists only to attach the xcframework's SPM dependencies
// (KeychainAccess, Clibsodium) to the public product graph — something a
// `.binaryTarget` cannot do on its own.
//
// It deliberately does NOT `@_exported import VerkadaPassSDK`. The xcframework
// is built from a source checkout whose SPM identity mangles to the same
// package name as this package (`verkada_pass_ios_sdk`), so the prebuilt module
// reports itself as belonging to this package. Swift then allows that import
// only from source or a package interface, while Xcode's explicit-module
// scanner resolves the framework from `.private.swiftinterface` — failing with
// "module 'VerkadaPassSDK' is in package 'verkada_pass_ios_sdk' but was built
// from a non-package interface".
//
// Instead the binary target is listed in the product alongside this one, so
// `import VerkadaPassSDK` in consumer code resolves to the prebuilt module
// directly while this target still contributes the link-time dependencies.
