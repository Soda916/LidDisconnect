# LidDisconnect Handoff

## Goal and non-negotiable behavior

Native macOS menu bar app. Physical lid closure disconnects only user-selected paired Bluetooth devices using public Apple APIs. Never power off Bluetooth, infer lid closure from sleep/display events, alter sleep/Amphetamine/network/background services, invoke external runtime utilities or use private APIs. No automatic reconnect on lid open.

## Current phase

v1.0.0 implementation, localization and distributable artifacts verified locally; GitHub publication is the remaining delivery step in this work unit. User explicitly authorized PUBLIC visibility, Apache-2.0 and a downloadable release on 2026-10-18. This supersedes the initial private-only requirement. Release version does not certify untested hardware behavior.

The follow-up narrows CONTRIBUTING priorities to security and performance only. Other feature ideas are welcome for discussion; no plugin system or plugin API is provided.

## Environment and repository

- Host Apple Silicon; Xcode 27.1 selected; Swift 6.4; SDK macOS 27.0.
- Deployment target macOS 14.0 verified in both Universal binary slices with vtool.
- Repository: https://github.com/Soda916/LidDisconnect
- Reference folder /Users/dustlee/program/DynamicWallPaper was read-only. Used its English root + zh-TW/ + docs/ layout. Its GPL/commercial terms, plugin implementation and broad quarantine-removal instructions were not copied.
- Codex sandbox restricts .git, compiler caches and external access: use approved require_escalated commands where required, never chmod 777 as a workaround.

## Architecture and files

- Package.swift: executable, core library/resources, public C macro bridge, test target; no third-party package dependencies.
- Sources/LidDisconnect/LidDisconnectApp.swift: SwiftUI MenuBarExtra entry and --probe-lid / --check-localizations diagnostic modes.
- AppModel.swift / MenuView.swift: main-actor state, user selection, cancellation, saved language, login item and diagnostics UI.
- LidStateMonitor.swift: public IOPMrootDomain notification + AppleClamshellState; deduplicated initial state and events on main run loop.
- BluetoothEventMonitor.swift: public global connect notifications and connected paired-device disconnect subscriptions; 150 ms burst debounce.
- BluetoothManager.swift: actor isolates blocking classic Bluetooth calls, checks controller availability and re-resolves selected addresses against current paired devices.
- Sources/LidDisconnectCore/: LidPolicy, RefreshGate, validated normalized identity, Preferences, Localizer and AppText.
- Sources/LidDisconnectCore/Resources/: 8 native .lproj tables; 66 keys each, plus OS permission purpose translations.
- Sources/CPlatform/: bridges public clamshell SDK macro Swift cannot import. No hardcoded private message constants.
- Tests/LidDisconnectCoreTests/: 9 tests.
- Packaging/Info.plist: version 1.0.0, build 100, menu-bar-only, macOS 14+, localized Bluetooth purpose.
- scripts/build-app.sh: native or Universal bundle in build/LidDisconnect.app with resources/license/notice and ad-hoc signing.
- scripts/build-release.sh: Universal release, drag-to-Applications DMG, ZIP, SHA256SUMS.txt.
- README.md and zh-TW/README.md: downloads, first launch, language selection, hardware caveats, building.
- CONTRIBUTING/SECURITY/CHANGELOG plus zh-TW/ counterparts; docs/ARCHITECTURE, TESTING, RELEASING and matching zh-TW/docs/.
- docs/releases/v1.0.0.md: release body in English and Traditional Chinese.
- .github/: issue/PR templates and minimal read-only macOS build/test CI.
- LICENSE/NOTICE: Apache-2.0, Copyright 2026 Soda916 and contributors.
- HANDOFF.md intentionally remains at repository root per the user's handoff requirement.

## Completed work and decisions

- Corrected initial pairedDevices() [Any] cast bug; original failure was not caused by a placeholder.
- Real public lid monitoring; initial closed state never disconnects. Later open→closed transition required, including after enabling while closed.
- Public per-device closeConnection(), only selected confirmed paired addresses. No forced retries or arbitrary-name targeting.
- One close call followed by connection samples at about 1, 3, 8 seconds. Failure, persistent connection or observed reconnect pauses automation/stops batch.
- Bluetooth connection/disconnection notifications trigger refresh even with menu closed; manual Refresh retained. RefreshGate coalesces updates received during active reads rather than dropping them. No steady polling.
- Eight UI languages: English, Traditional/Simplified Chinese, Japanese, Korean, German, French, Spanish. Automatic follows preferred macOS languages, fallback English; manual persisted selector immediately LEFT of Quit.
- AppText stores semantic messages, so existing errors/status/history re-render when switching languages. OS-provided raw error detail may still follow the OS language.
- All translations authored directly by the agent; no translation API, external LLM, paid translation service or runtime network dependency.
- CoreBluetooth requests permission/controller status only; no scan/connect behavior. IOBluetooth handles classic devices.
- OSLog uses private messages; menu keeps 60 events, displays 15 and can copy full current-session diagnostics.
- SMAppService.mainApp login item; user should install to a fixed location before registering.
- Local ad-hoc signature, no Developer ID/notarization. Trusted users use System Settings > Privacy & Security > Open Anyway for this app. No global Gatekeeper/SIP bypass recommended or performed.
- Generated build/, dist/, caches, binaries, local logs and credentials are gitignored.
- History/source reviewed for common credential patterns before publication; no matches found.

## Tests and evidence

| Classification | Result |
| --- | --- |
| Actually verified | Public lid notification registration; initial physical_lid=open from host and read-only DMG executable probe |
| Build/unit verified | swift build and swift test, 9 tests passed on Xcode 27.1 |
| Translation verified | All 8 tables share all 66 keys/placeholders; detection, saved override and semantic history re-render tested |
| Universal build verified | arm64 + x86_64 Mach-O slices; each verified via lipo; vtool reports minos 14.0 for both |
| App/resource verified | plist, deep strict codesign verification; --check-localizations from packaged app, DMG and extracted ZIP all pass without depending on developer build paths |
| Artifact verified | hdiutil verify DMG; read-only mount contains App, Applications symlink, INSTALL.txt, LICENSE/NOTICE; ZIP unpack/signature/localizations verified; SHA-256 checks pass |
| Previous launch smoke | v0.1 app launched and survived; v1.0 actual visible UI/hardware acceptance still pending |
| Not verified | Cleer ARC II audio/multipoint slot release/reconnect, actual lid transitions with Amphetamine, hardware Bluetooth connect/disconnect notification delivery, login relaunch, Intel/macOS 14 runtime, downloaded Gatekeeper flow |

Known resolved packaging issue: this Xcode lipo rejected multiple architectures in one -verify_arch call; script now verifies arm64 and x86_64 separately. SDK warns x86_64 is deprecated but both slices build; macOS 14 runtime compatibility remains untested. hdiutil is deprecated on this beta but produced verified images; kept for older macOS build-tool compatibility.

Computer-use server timed out in prior work, so no fabricated visual/UI assertion. Verification probes do not invoke Bluetooth disconnection.

## Generated release artifacts

- build/LidDisconnect.app
- build/LidDisconnect-v1.0.0-macOS-Universal.dmg
- build/LidDisconnect-v1.0.0-macOS-Universal.zip
- build/SHA256SUMS.txt

Do not commit artifacts; upload them to GitHub release v1.0.0 using docs/releases/v1.0.0.md. Read-only verification mount was detached; extracted ZIP remains under ignored build/verification/.

## Recent Git commits

- dc1986a feat: refresh Bluetooth devices on connection events
- ec40bb0 feat: localize the entire interface in eight languages
- 3c37db7 docs: adopt Apache-2.0 and bilingual project documentation
- Previous v0.1 delivery: 5faf67b (and earlier atomic commits)
- Current packaging/CI work unit updates this file; obtain its commit hash via git log after commit.

## Remaining actions

1. Commit inspected packaging/CI files, make existing repository public with explicitly authorized gh repo edit, push, publish release v1.0.0 with DMG/ZIP/checksums.
2. Verify public visibility, license recognition, asset metadata/download availability and CI.
3. Update this handoff with publication URLs/outcome.
4. User hardware acceptance: run manual test while paused after confirming headphone name/address; then test real lid closure under their existing Amphetamine configuration. Public API failures require evidence/limitations and user decision before any change of approach.

Rebuild/start: bash scripts/build-app.sh; open build/LidDisconnect.app. Release: bash scripts/build-release.sh. The old v0.1 dist/ bundle may still be running; do not mistake its process/UI for v1.0.
