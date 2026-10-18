[English](TESTING.md) | [繁體中文](../zh-TW/docs/TESTING.md)

# Testing

Automated checks: `swift test`, `bash scripts/build-release.sh`, and the packaged executable's `--check-localizations` and `--probe-lid 2` modes. The release script verifies architectures, localized resources, plist and signatures. Mount the DMG read-only and repeat the bundle checks to verify the delivered artifact.

The nine core tests cover lid transitions, paused/initial states, validated addresses, preferences/language round trip, refresh coalescing, preferred-language detection, all 66 translated keys and matching placeholders, and history rendering after language switches.

## Hardware acceptance

1. Start paused; grant Bluetooth permission and identify Cleer ARC II by name and address.
2. Connect/disconnect it using macOS Bluetooth controls. Confirm the app list updates without pressing Refresh, including while its menu is closed. Repeat during an in-flight refresh.
3. Play audio and use the manual disconnect test. Compare API result, Mac link/audio state, the headset state, and whether an iPhone/iPad can take the freed slot.
4. If the API fails, stays connected or reconnects, retain logs and stop release work on that behavior pending a design decision. Do not switch to private APIs/controller power toggles.
5. Reconnect manually. Test actual lid closure/opening under the user's existing Amphetamine setup. Also test without it, display-only sleep and duplicate notifications. App startup while closed must not disconnect.
6. Test all language menus including saved override/system fallback, long labels and existing result/history translation. Check login item registration and real relaunch from a permanent app location.

No physical lid closure, headset disconnection or login relaunch has been performed by the agent. Initial lid-open reading, build/tests, resource loading and packaging checks are separate evidence. Intel binaries can be cross-compiled here; Intel runtime and macOS 14 runtime are not thereby verified.
