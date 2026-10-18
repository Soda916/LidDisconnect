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
- Implemented main-run-loop IOKit general-interest notification on `IOPMrootDomain`, using the public clamshell message and initial registry property.
- Added pure transition policy and 3 passing Swift Testing tests for initial closed state, duplicate events, pause/re-enable, and unknown state.
- Full executable builds successfully using Xcode 27.1.
- Bluetooth controller runs on a separate actor; resolves selected normalized addresses against the current paired list before calling only `closeConnection()`.
- After a single disconnect attempt, observes connection at ~1, 3, 8 seconds; records API failures, persistent connection or observed reconnection. No forced retry or controller power changes.
- Settings default to paused and store validated device addresses. 5 unit tests now pass, including settings round trip/corrupt data and address normalization.

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
- `CPlatform` is a tiny C bridge for the public SDK macro `kIOPMMessageClamshellStateChange`, which Swift cannot directly import. No private headers or hard-coded message numbers.
- Treat compilation as compilation-only evidence; hardware behavior requires explicit real-device testing.

## Known limitations

- Hardware feasibility remains pending; current code is a validation build, not a certified Cleer ARC II integration.
- No claims about physical lid reliability or Bluetooth disconnection are validated yet.

## Test status

- Actually verified: environment inspection only.
- Source compilation reproduced an actual bug: `pairedDevices()` returns `[Any]!`; added a checked cast to `IOBluetoothDevice`. Placeholder methods were not the compiler error.
- Restricted execution cannot access compiler caches; use approved elevated build execution.
- Not verified: all lid, sleep-prevention, Bluetooth, reconnection, and UI behavior.
- Compile verified: `swift test` (3 tests passed) and `swift build` passed on 2026-10-18.
- Known failures: initial `[Any]` cast bug fixed; private repository and authentication were verified using elevated execution in the prior session.

## Recent Git commit

`dae2b44 feat: monitor physical lid transitions with public IOKit notifications`; this work unit adds background Bluetooth validation and persisted device identity.

## Next recommended action

Build the v0.1 validation menu UI and signed app bundle; inspect current lid state, then have the user explicitly select and test Cleer ARC II before enabling automation.
