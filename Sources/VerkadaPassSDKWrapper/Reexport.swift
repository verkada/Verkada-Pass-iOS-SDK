// Re-exports the prebuilt VerkadaPassSDK xcframework so consumers importing
// the SPM product `VerkadaPassSDK` get the same symbols they'd get from the
// binary directly. Keeping this file in a separate target lets us attach the
// xcframework's SPM dependencies (KeychainAccess, Sodium) to the public
// product graph — something a `.binaryTarget` cannot do on its own.
@_exported import VerkadaPassSDK
