# LidDisconnect Handoff

## Project goal

LidDisconnect is a native macOS menu bar app intended to detect the physical MacBook lid state and disconnect only user-selected Bluetooth devices when the lid closes. It must not disable the Bluetooth controller, interfere with sleep or background services, use private APIs, or depend on external executables.

## Current phase

Phase 1 — feasibility validation; v0.1 implementation underway.

## Environment

- Host: Apple Silicon, macOS SDK target reported as macOS 27.0.0
- Swift: 6.4
- Xcode 27.1 is installed and selected at `/Applications/Xcode.app/Contents/Developer`.
- Private repository verified: https://github.com/Soda916/LidDisconnect

## Architecture and important files

- `Package.swift`: Swift Package Manager executable target for the native prototype.
- `Sources/LidDisconnect/main.swift`: AppKit menu bar application entry point.
- `Sources/LidDisconnect/LidStateMonitor.swift`: IOKit lid-state monitoring boundary.
- `Sources/LidDisconnect/BluetoothManager.swift`: IOBluetooth device discovery and per-device disconnect boundary.
- `Sources/LidDisconnect/Preferences.swift`: UserDefaults-backed settings model.

## Completed

- Initial environment and Git/GitHub checks performed.
- Created this handoff document.
- Added initial SwiftPM/AppKit/IOKit/IOBluetooth prototype sources.
- No hardware or physical-lid behavior has been tested yet.

## Not completed

- GitHub private repository creation: remote appears to exist; visibility and push still require valid authentication.
- Build verification with Xcode and native frameworks.
- Physical lid event verification while Amphetamine prevents sleep.
- Verification that `IOBluetoothDevice.closeConnection()` disconnects Cleer ARC II and whether it immediately reconnects.
- Production UI, login item integration, logging, and integration tests.

## Technical decisions

- Keep lid sensing and Bluetooth control behind separate protocols so hardware-dependent behavior can be tested or replaced without coupling the UI.
- Use device address/identifier rather than display name as the persisted identity.
- Never implement controller-wide Bluetooth power changes.
- Treat compilation as compilation-only evidence; hardware behavior requires explicit real-device testing.

## Known limitations

- The current machine lacks full Xcode, so an Xcode project and AppKit/IOKit integration cannot yet be validated end-to-end.
- Command Line Tools may not provide all frameworks or entitlements needed for a menu bar app.
- No claims about physical lid reliability or Bluetooth disconnection are validated yet.

## Test status

- Actually verified: environment inspection only.
- Source compilation reproduced an actual bug: `pairedDevices()` returns `[Any]!`; added a checked cast to `IOBluetoothDevice`. Placeholder methods were not the compiler error.
- Restricted execution cannot access compiler caches; use approved elevated build execution.
- Not verified: all lid, sleep-prevention, Bluetooth, reconnection, and UI behavior.
- Known failures: GitHub authentication is invalid in the current shell; `xcodebuild` is unavailable with the active developer directory; build has not reached source compilation.

## Recent Git commit

`0a81210 chore: bootstrap native macOS app` (pushed to private origin/main).

## Next recommended action

Make `gh auth status` succeed, verify the remote is private, commit and push the bootstrap, then install/select a matching full Xcode toolchain and perform the physical-lid and Cleer ARC II tests on the target MacBook.
