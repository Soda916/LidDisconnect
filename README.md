[English](README.md) | [繁體中文](zh-TW/README.md)

# LidDisconnect

[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue?logo=apple)](https://www.apple.com/macos/)
[![Apache-2.0](https://img.shields.io/badge/license-Apache--2.0-blue)](LICENSE)
[![Release](https://img.shields.io/github/v/release/Soda916/LidDisconnect)](https://github.com/Soda916/LidDisconnect/releases/latest)

A native macOS menu bar app that disconnects **only your selected Bluetooth devices when the MacBook lid physically closes**. Useful for freeing a multipoint headphone connection while your Mac keeps running with your existing Amphetamine setup.

## Download and install

**v1.0.0 · macOS 14 or later**

| Download | Architecture |
| --- | --- |
| [DMG](https://github.com/Soda916/LidDisconnect/releases/download/v1.0.0/LidDisconnect-v1.0.0-macOS-Universal.dmg) | Universal: Apple Silicon and Intel |
| [ZIP](https://github.com/Soda916/LidDisconnect/releases/download/v1.0.0/LidDisconnect-v1.0.0-macOS-Universal.zip) | Universal: Apple Silicon and Intel |
| [SHA-256 checksums](https://github.com/Soda916/LidDisconnect/releases/download/v1.0.0/SHA256SUMS.txt) | Verify the downloaded artifact |

1. Open the DMG, drag LidDisconnect to Applications, and eject the disk image.
2. Launch it from Applications. Look for the pause icon in the menu bar; there is no Dock icon or regular main window.
3. Allow Bluetooth access, select your headphones by **name and address**, and test disconnection while automation is paused.
4. Confirm the connection slot is actually released using your headphones and other phone/tablet. Then reconnect manually and enable automatic lid-close disconnection.

### Opening an app from an unidentified developer

The download has a local ad-hoc signature but **no Developer ID signature or Apple notarization**. macOS may block its first launch. Only proceed if you trust this repository and have verified your download.

After attempting to open the app, go to **System Settings → Privacy & Security → Open Anyway** for LidDisconnect, then confirm opening it. See [Apple’s instructions](https://support.apple.com/en-us/102445). This creates an exception for this app; do not disable Gatekeeper or SIP globally.

If macOS reports the app is damaged, download it again and compare the published SHA-256 checksum before proceeding. Managed Macs may prohibit overrides; contact your administrator. Do not treat an actual malware warning as a normal unsigned-app warning.

## Features

- Physical lid notifications through public IOKit APIs, independent of system/display sleep notifications.
- Per-device IOBluetooth disconnection; never powers off the Bluetooth controller.
- **Automatic device-list refresh on Bluetooth connection/disconnection events**, with manual Refresh retained.
- Notifications are coalesced; no periodic device polling.
- Duplicate lid events are ignored. Starting or enabling while already closed waits for a later open→closed transition.
- Persistent selected device addresses and pause/enable settings.
- Manual disconnect test with bounded connection checks at about 1, 3 and 8 seconds.
- Pauses automation on an API failure, persistent connection or observed reconnection.
- Launch at login through Apple ServiceManagement.
- Recent activity and copyable diagnostics.
- No Homebrew, blueutil, private APIs, background translation service or runtime dependencies.

## Languages

English, Traditional Chinese, Simplified Chinese, Japanese, Korean, German, French and Spanish. The default follows macOS preferred languages, falling back to English. Select a manual override using the language menu **immediately left of Quit**; it is saved and applies to status, errors and existing activity messages.

All translations are included locally. There are no translation API calls, paid LLM services or network translation costs.

## Behavior and limitations

LidDisconnect does not keep your Mac awake or configure Amphetamine. Keep your existing sleep arrangement. It never reconnects devices when opening the lid and never retries disconnection indefinitely.

Public `closeConnection()` is synchronous and runs away from the UI actor. Cancellation stops remaining work but cannot undo an already submitted native call. Brief or later reconnections can fall outside the bounded checks. Connection-state snapshots do not prove that an earphone's audio profile or multipoint slot was released; verify on the actual hardware.

v1.0.0 is the requested release version, **not a claim that every headphone or macOS version has passed hardware acceptance**. Build, tests and packaging are verified locally on Apple Silicon with Xcode 27.1. Actual Cleer ARC II slot release, Amphetamine lid transitions, event delivery across all peripherals and login relaunch still require device testing. See [testing](docs/TESTING.md).

For launch at login, move the app to its permanent location before enabling the option and approve it in System Settings if requested. Disable the option before moving/removing the app.

## Build from source

Requires a compatible Swift 6 toolchain, preferably full Xcode. Both Xcode and Command Line Tools may remain installed; select one matching toolchain:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
git clone https://github.com/Soda916/LidDisconnect.git
cd LidDisconnect
swift test
bash scripts/build-app.sh
open build/LidDisconnect.app
```

Build distributable Universal DMG/ZIP artifacts with Apple's built-in tools:

```bash
bash scripts/build-release.sh
```

Outputs go to `build/`, and are not committed to Git. A read-only lid probe is available:

```bash
swift run LidDisconnect --probe-lid 60
```

## Project documents

- [Architecture](docs/ARCHITECTURE.md) · [Testing](docs/TESTING.md) · [Releasing](docs/RELEASING.md)
- [Contributing](CONTRIBUTING.md): focus on **security and performance**. Other ideas are welcome for discussion; the project does not provide a plugin system.
- [Security policy](SECURITY.md) · [Changelog](CHANGELOG.md) · [Agent handoff](HANDOFF.md)

## License

Copyright 2026 Soda916 and the LidDisconnect contributors. Licensed under the [Apache License 2.0](LICENSE). See [NOTICE](NOTICE). No affiliation with Apple or headphone manufacturers.
