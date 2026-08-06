# VerkadaPass iOS SDK

A Swift SDK for embedding Verkada Pass — Verkada's mobile credential — into iOS apps. The SDK authenticates a user against a Verkada Command organization, surfaces the doors and elevators they can unlock, advertises the device as a BLE credential, and issues remote unlocks with optional geofence enforcement.

- **Platform:** iOS 13+
- **Language:** Swift 5.9
- **Distribution:** Swift Package Manager (binary `XCFramework`)

## Installation

A special API token is required to use the Verkada Pass SDK. If you are interested in implementing this SDK, contact Verkada support.

### Swift Package Manager

Add the package to your project:

```swift
dependencies: [
    .package(url: "https://github.com/verkada/Verkada-Pass-iOS-SDK.git", from: "0.4.0")
]
```

Then add the `VerkadaPassSDK` product to your application target.

A SwiftUI example app lives in [`verkada-pass-sdk-example/`](verkada-pass-sdk-example/) — open `VerkadaPassSDKExample.xcodeproj` and build the `VerkadaPassSDKExample` scheme.

The example app does not embed an API key. On first launch it shows a **Login** screen:

1. A PKCE `code_challenge` is generated automatically and shown in the read-only field. Tap **Copy** to put it on the clipboard.
2. From your own server (or a script) call the Verkada public API to exchange your API key for an auth token (`POST /token` with `x-api-key`) and then mint an SDK token for the target user (`POST /v2/access/user/pass/sdk_token` with `user_id` and the copied `code_challenge`).
3. Paste the returned SDK token into the **SDK Token** field and tap **Login**. On success the app advances to the doors list and persists credentials, so subsequent launches skip login until you tap **Logout** in the top-right.

Override the `shard` constant at the top of [`VerkadaPassSDKExampleApp.swift`](verkada-pass-sdk-example/VerkadaPassSDKExample/VerkadaPassSDKExampleApp.swift) to point the example at a different region (defaults to `.staging`).

## Project setup

The SDK uses Bluetooth and Location at runtime, so the host application must declare the matching capabilities, background modes, and Info.plist usage descriptions.

### Capabilities

In **Signing & Capabilities**, add **Background Modes** and enable:

- **Acts as a Bluetooth LE accessory**
- **Uses Bluetooth LE accessory**

### Info.plist keys

Add the following keys with messages explaining why your app needs each permission:

| Key | Purpose |
| --- | --- |
| `NSBluetoothAlwaysUsageDescription` | Advertise the device as a Verkada Pass credential and scan for nearby readers. |
| `NSLocationWhenInUseUsageDescription` | Detect when the user is near a building so doors can be unlocked. |
| `NSLocationAlwaysAndWhenInUseUsageDescription` | Allow geofence monitoring while the app is in the background. |

`UIBackgroundModes` should include `bluetooth-central` and `bluetooth-peripheral` (the example app's `Info.plist` already does).

## Quick start

The SDK does not handle API-key exchange itself. The host application is responsible for obtaining a short-lived **SDK token** from the Verkada public API and passing it to ``configure(with:clientID:shard:)``. The PKCE `code_challenge` for that exchange comes from `sdk.generateChallenge()`.

`configure(...)` only needs to be called **once per user** — the SDK persists the resulting credentials. On subsequent launches, check `sdk.isConfigured` and skip the configure step entirely if it is `true`. Calling `configure(...)` again is only required after `clearConfiguration()`, or when switching users.

```swift
import VerkadaPassSDK

let sdk = VerkadaPass.shared

// 1. Configure once per user. On subsequent launches, isConfigured is true
//    and you can jump straight to step 2.
if !sdk.isConfigured {
    // 1a. Generate a PKCE challenge; the SDK retains the matching verifier.
    let codeChallenge = sdk.generateChallenge()

    // 1b. Exchange your API key for an SDK token via the Verkada public API
    //     (POST /token, then POST /v2/access/user/pass/sdk_token with the
    //     challenge and user_id). This step must happen on a trusted backend —
    //     your API key should never ship inside the iOS app.
    let sdkToken: String = try await yourBackend.fetchSDKToken(
        userID: "<user-id>",
        codeChallenge: codeChallenge
    )

    // 1c. Configure for a specific client/shard. The user identity is derived
    //     from the SDK token itself. Credentials are persisted across launches.
    try await sdk.configure(
        with: sdkToken,
        clientID: "<your-client-id>",
        shard: .us
    )
}

// 2. Request runtime permissions.
sdk.bluetoothService.askPermission()
sdk.locationService.askPermission()

// 3. Load the user's doors and elevators. This MUST run before
//    bluetoothService.start() / locationService.startMonitoring() —
//    fetchDevices() pulls the reader list, building/floor geofences,
//    and org configuration the BLE and location services need to
//    operate. Starting them first leaves them with no readers to
//    advertise to or regions to monitor.
let sections: [DoorSection] = try await sdk.fetchDevices()

// 4. Start scanning and locating.
sdk.locationService.startLocating()
sdk.locationService.startMonitoring()
sdk.bluetoothService.start() // also enables BLE unlock (proximity-based) — see below

// 5. Mobile (remote) unlock — fired from a user tap.
do {
    try await sdk.unlock(row)
} catch let error as UnlockError {
    print(error.message)
}

// 6. When the user signs out, clear the cached configuration. The next
//    launch will see isConfigured == false and prompt for login again.
sdk.clearConfiguration()
```

> **Order matters:** always call `fetchDevices()` before starting the BLE or location services. The fetch is what populates the reader list and geofence data those services rely on — if you call `bluetoothService.start()` or `locationService.startMonitoring()` first, they'll come up with nothing to do until the next `fetchDevices()` completes. Call `fetchDevices()` again whenever you want to pick up server-side changes (e.g. when the app returns to the foreground).

## Unlock paths

The SDK supports two complementary unlock paths:

- **Mobile (remote) unlock** — explicit, app-driven. The host calls `sdk.unlock(row)` (typically from a button tap). The SDK validates schedules and geofence, then asks the Verkada backend to release the lock. Use this when you want a visible Unlock action in your UI.
- **BLE unlock** — implicit, reader-driven, proximity-based. After `sdk.bluetoothService.start()` is running, the device advertises itself as a Verkada Pass credential. When the phone comes within range of a reader the user is permitted to unlock, the reader can release the lock automatically without any call from the app. Whether this happens, and how close the phone has to be (tap-to-unlock, short-range proximity, etc.), is governed by the reader's settings in Verkada Command.

## Public API overview

### Entry point — `VerkadaPass`

The SDK is a singleton. All interaction goes through `VerkadaPass.shared`.

| Member | Description |
| --- | --- |
| `shared` | The singleton instance. |
| `bluetoothService: BLEService` | Drives BLE advertisement, scanning, and Bluetooth permission state. |
| `locationService: LocationService` | Drives location updates, geofence monitoring, and beacon ranging. |
| `logger: Logger` | Stream of structured log lines. |
| `generateChallenge() -> String` | Generates a fresh PKCE `code_verifier` (kept in memory) and returns the matching base64url-encoded SHA-256 `code_challenge` for the host app to send to the Verkada public API. |
| `configure(with:clientID:shard:) async throws` | Binds the SDK to a user/shard using a pre-fetched SDK token. The host app is responsible for exchanging its API key for this token. |
| `isConfigured: Bool` | `true` when the SDK has cached credentials from a previous `configure(...)` and `clearConfiguration()` has not been called since. Read this on launch to decide whether to skip the configure step. |
| `clearConfiguration()` | Stops BLE scanning/advertising, stops location monitoring, and wipes cached authentication data. The host must call `configure(...)` again before any further SDK calls. |
| `fetchDevices() async throws -> [DoorSection]` | Loads unlockables and refreshes BLE/location state. |
| `unlock(_:) async throws -> Int?` | Performs a mobile (remote) unlock; returns the unlock duration in seconds. Independent from BLE unlocks (proximity-based), which are driven by the reader once `bluetoothService.start()` is running. |

### Services

- **`BLEService`** — protocol exposing BLE authorization state, the live `connectedEntities` stream, and lifecycle methods (`start`, `stop`, `clean`). Mirrors `PermissionGranting` for permission prompts.
- **`LocationService`** — protocol exposing location authorization state, `currentLocation`, `nearbyEntities`, geofence helpers (`isWithinGeofenceRegion`, `isLocationRestrictedWithEnabledGeofence`), and `onRegionEntry`, which fires when the device enters a monitored beacon region — including background wakes after the system relaunched your app. Use it to re-arm BLE scanning; `VerkadaPass.shared` wires it for you.
- **`PermissionGranting`** — common shape for any service that requests a system permission. Provides `authorized`, `authorizationNotAsked`, `authorizationDeniedOrRestricted`, and an `authorizationChanged` Combine subject.
- **`Logger`** — exposes a `PassthroughSubject<LogLine, Never>` and a configurable `minLevel`.

### Models

| Type | Description |
| --- | --- |
| `Shard` | Selects the Verkada Command deployment. Use `.us`, `.eu`, `.au`, or `.staging`, or build one with `Shard(name:hostMetadata:)` for a deployment the built-ins don't cover (GovCloud, a per-organization shard map). |
| `DoorSection` | Group of doors/elevators sharing a building and floor. |
| `DoorRow` | `ObservableObject` view-model for a single door or elevator; exposes `lockState` and `status`. After a successful `unlock(_:)` the row publishes `.unlocked(duration)` and returns to `.locked` on its own once that window elapses. |
| `Door`, `Elevator` | The two concrete `AccessEntity` types the SDK can unlock. |
| `AccessEntity` | Common protocol for unlockables surfaced by `BLEService` / `LocationService`. |
| `Building`, `Floor` | Physical groupings used for geofencing and section headers. |
| `UnlockablesResponse`, `Unlockables`, `UserDoorSchedule`, `UserDoorScheduleEvent` | Raw access data returned by the API. |
| `AccessReader`, `DeviceIO`, `DeviceIOMetadata`, `DeviceIOConfiguration`, `AccessEntityConfiguration` | Hardware-level metadata attached to doors and elevators. |
| `APIError`, `APICode`, `HTTPError` | Typed errors for API and transport failures. |
| `UnlockError` | Domain-specific error thrown by the unlock method. |

Every public type carries DocC-style comments — option-click any symbol in Xcode (or build documentation via **Product → Build Documentation**) for full reference.

## Permission flow

The SDK does not prompt the user implicitly. The host application is expected to call `askPermission()` in response to a user gesture and react to `authorizationChanged`:

```swift
sdk.bluetoothService.authorizationChanged
    .sink { _ in
        if sdk.bluetoothService.authorized {
            sdk.bluetoothService.start()
        }
    }
    .store(in: &cancellables)
```

The same pattern applies to `locationService`. `LocationService.authorizationAlwaysOn` reports whether background monitoring is available.

## Logging

`VerkadaPass.shared.logger.log` is a Combine subject. Forward it into your own logger:

```swift
sdk.logger.minLevel = .info
sdk.logger.log
    .sink { line in
        os_log("%{public}@", line.message)
    }
    .store(in: &cancellables)
```

## Error handling

`unlock(_:)` throws `UnlockError`, which has a `.message` suitable for display:

```swift
do {
    try await sdk.unlock(row)
} catch let error as UnlockError {
    show(error.message)
} catch let error as APIError {
    show(error.message)
}
```

Network/API failures from `configure(...)` and `fetchDevices()` surface as `APIError` (typed server response) or `HTTPError` (non-2xx status). `APIError.isTokenExpired` indicates that the host should re-authenticate.

## License

See [LICENSE](LICENSE).
