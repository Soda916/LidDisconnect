# LidDisconnect Handoff

## Project goal

LidDisconnect is a native macOS menu bar app intended to detect the physical MacBook lid state and disconnect only user-selected Bluetooth devices when the lid closes. It must not disable the Bluetooth controller, interfere with sleep or background services, use private APIs, or depend on external executables.

## Current phase

v0.1 executable validation build implemented. Core/UI code is complete for this version; the original Phase 1 hardware acceptance gate is still pending. Do not label the Cleer ARC II integration production-verified until the user completes the hardware matrix below.

## Environment

- Host: Apple Silicon; SDK macOS 27.0, deployment target macOS 14
- Swift: 6.4
- Xcode 27.1 is installed and selected at `/Applications/Xcode.app/Contents/Developer`.
- Private repository verified: https://github.com/Soda916/LidDisconnect

## Architecture and important files

- `Package.swift`: SwiftPM executable, core library, C bridge, and Swift Testing target; no third-party dependencies.
- `Sources/LidDisconnect/LidDisconnectApp.swift`: SwiftUI `MenuBarExtra` entry point and read-only `--probe-lid` mode.
- `Sources/LidDisconnect/AppModel.swift`: main-actor coordination, permission status, selection, cancellation, OSLog/events, and login item controls.
- `Sources/LidDisconnect/MenuView.swift`: native device selection/status/results interface.
- `Sources/LidDisconnect/LidStateMonitor.swift`: public IOKit notification registration, initial state read, cleanup.
- `Sources/LidDisconnect/BluetoothManager.swift`: separate actor for paired-device discovery, per-device disconnection and bounded observation.
- `Sources/LidDisconnect/BluetoothAuthorization.swift`: explicit user-triggered CoreBluetooth permission request; does not scan or connect.
- `Sources/LidDisconnectCore/`: independently tested transition policy, normalized/validated address identity, and UserDefaults preferences.
- `Sources/CPlatform/`: tiny public-SDK macro bridge.
- `Tests/LidDisconnectCoreTests/`: 5 Swift Testing tests.
- `Packaging/Info.plist`, `scripts/build-app.sh`: local signed `.app` packaging and Bluetooth privacy purpose string.
- `README.md`: build/start commands and hardware acceptance procedure.
- `dist/LidDisconnect.app`: generated, gitignored runnable local app. Already launched during this session.

## Completed

- Created/verified private GitHub repository; used conventional atomic commits.
- Reproduced and fixed actual build bug: `pairedDevices()` returns `[Any]!` and needs a checked device cast. The placeholder did not cause that compiler error.
- Implemented main-run-loop IOKit general-interest notification on `IOPMrootDomain`, using the public clamshell message and initial registry property.
- Added pure transition policy and 3 passing Swift Testing tests for initial closed state, duplicate events, pause/re-enable, and unknown state.
- Full executable builds successfully using Xcode 27.1.
- Bluetooth controller runs on a separate actor; resolves selected normalized addresses against the current paired list before calling only `closeConnection()`.
- After a single disconnect attempt, observes connection at ~1, 3, 8 seconds; records API failures, persistent connection or observed reconnection. No forced retry or controller power changes.
- Settings default to paused and store validated device addresses. 5 unit tests now pass, including settings round trip/corrupt data and address normalization.
- Implemented SwiftUI `MenuBarExtra` with device selection, pause/enable, manual disconnect, bounded result observation, recent events/copy diagnostics, Bluetooth permission request, and `SMAppService.mainApp` login-item controls.
- Added `--probe-lid [seconds]` read-only diagnostics mode, which never invokes Bluetooth or modifies sleep behavior.
- Actually verified on host: `swift run LidDisconnect --probe-lid 2` successfully registered IOKit notifications and read `physical_lid=open` at 2026-10-18T14:59:36Z. No close/open transition has been induced yet.
- Generated `dist/LidDisconnect.app`; `plutil -lint` and `codesign --verify --strict --verbose=2` passed.
- Launched the bundle with `open`; confirmed its exact process path remained running after approximately one minute. This verifies launch/process survival, not the visible UI.

## Not completed

- Human-visible menu rendering and Bluetooth permission flow: computer-use inspection failed twice with server timeout `-10005`; no successful visual assertion.
- Read paired devices in the authorized app, manually confirm Cleer ARC II identity, test real audio/baseband disconnection and release of its multipoint connection slot.
- Real close/open transitions with Amphetamine both enabled and disabled; confirm duplicate-event behavior and lack of unrelated sleep/display triggers.
- Reconnection behavior beyond the bounded sample window; actual login relaunch and Gatekeeper behavior on another machine.
- Formal release signing/notarization/distribution and wider macOS compatibility.

## Technical decisions

- Separate main-actor UI/lid monitoring, background Bluetooth actor, and pure testable core. No third-party abstraction layer is needed for v0.1.
- Use device address/identifier rather than display name as the persisted identity.
- Never implement controller-wide Bluetooth power changes.
- `CPlatform` is a tiny C bridge for the public SDK macro `kIOPMMessageClamshellStateChange`, which Swift cannot directly import. No private headers or hard-coded message numbers.
- Treat compilation as compilation-only evidence; hardware behavior requires explicit real-device testing.
- Default paused, no selected devices. Initial closed state never triggers a disconnect. Enabling while closed requires a later physical open→closed transition.
- Only user-selected addresses are resolved against the current paired list. No disconnection is performed by the agent before user device selection.
- A failed API call, persistent connection or observed reconnect pauses automatic operation and stops the batch. Investigate and ask the user before changing the public-API design if hardware tests fail.
- No continuous polling: lid events are notification-based; device list refresh is user/UI/operation driven; post-disconnect observations are bounded to ~1, 3, 8 seconds.
- Packaged local app is ad-hoc signed. No sandbox entitlement or elevated system privilege is requested by the app. OS Bluetooth permission is requested explicitly by the user.

## Known limitations

- Hardware feasibility remains pending; current code is a validation build, not a certified Cleer ARC II integration.
- No actual physical close event or Bluetooth disconnect was initiated during development.
- Public `closeConnection()` is synchronous; it runs off the main actor but cannot be forcibly interrupted. Pause cancels subsequent work and observations, not an already issued call.
- Bounded connection snapshots cannot rule out very brief or later reconnects, nor prove an earphone multipoint slot was released. Check the headphone and second device.
- Local ad-hoc signatures may require fresh permission approval after rebuild; stable Developer ID signing is future work.

## Test status

| Classification | Evidence |
| --- | --- |
| Actually verified | Xcode selected; initial physical lid open state; notification registration; signed bundle launch and process survival |
| Compile/unit verified | `swift build`; `swift test` with 5 passed tests; all SwiftUI/IOKit/IOBluetooth/ServiceManagement code builds |
| Packaging verified | `bash -n scripts/build-app.sh`; `bash scripts/build-app.sh`; plist validation; strict code-signature verification |
| Not verified | Actual close/open transitions, Amphetamine interaction, paired listing under app permission, Cleer ARC II disconnect/audio slot release/reconnect, visible UI, login relaunch |
| Known failure | Initial paired-device cast bug fixed; computer-use server unavailable for UI inspection |

Hardware acceptance method: follow README's first-use steps. First manual disconnect while paused; verify on Mac, headphone and iPhone/iPad; reconnect manually, enable automation, test actual lid events with Amphetamine. If public API demonstrably fails, stop that feature's release work, document evidence and await the user's decision.

Environment note: this Codex sandbox restricts `.git`, compiler caches and external access. Use approved `require_escalated` commands for git writes/builds/push. Do not advise `chmod 777` or misreport a sandbox-only authentication error as proof that the user's CLI is broken.

## Recent Git commit

- `32b56c6 fix: cast paired Bluetooth devices to native device type`
- `dae2b44 feat: monitor physical lid transitions with public IOKit notifications`
- `0ce6566 feat: validate selected Bluetooth disconnections off the main thread`
- `3dd1138 feat: add native menu bar controls and feasibility diagnostics`

This packaging/documentation work unit includes the final handoff; obtain its hash with `git log -1 --oneline` after commit. No history was rewritten.

## Next recommended action

The app is already running from `dist/LidDisconnect.app`. Have the user click the menu bar pause icon, authorize Bluetooth and confirm/select Cleer ARC II by name AND address, then run the manual disconnect test before enabling automatic physical-lid disconnection. Report/copied logs must distinguish an API return, observed link state and actual headphone slot release. For rebuilding: `bash scripts/build-app.sh`; for starting: `open dist/LidDisconnect.app`.
