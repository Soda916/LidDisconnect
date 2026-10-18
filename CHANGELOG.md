[English](CHANGELOG.md) | [繁體中文](zh-TW/CHANGELOG.md)

# Changelog

## Unreleased

- Source compatibility: spell optional Bool switch patterns explicitly for older Swift 6 compilers. No runtime behavior change; the v1.0.0 artifacts were built successfully with Swift 6.4 and are unchanged.
- Source-build resource compatibility: resolve the actual localized file URL for older SwiftPM layouts; verify rendered values against all translated tables rather than allowing silent English fallback.

## 1.0.0 — 2026-10-18

- Refresh devices automatically on public Bluetooth connection/disconnection notifications; retain manual refresh.
- Coalesce event bursts and preserve changes received during an in-flight read.
- Add eight complete local UI translations, automatic system-language selection and a saved language menu immediately left of Quit.
- Package Universal Apple Silicon/Intel app, DMG, ZIP and SHA-256 checksums.
- Publish under Apache-2.0 with English root documentation and Traditional Chinese counterparts.
- Preserve public IOKit lid notifications, selected-address-only disconnection, bounded observation, pause/error handling and login item controls.

Hardware-specific Cleer ARC II multipoint release and Amphetamine behavior remain unverified; see the testing guide.

## 0.1.0 — 2026-10-18

Initial native validation build, physical lid probe, paired-device selection and per-device disconnection.
