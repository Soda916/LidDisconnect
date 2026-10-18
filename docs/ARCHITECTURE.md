[English](ARCHITECTURE.md) | [繁體中文](../zh-TW/docs/ARCHITECTURE.md)

# Architecture

- **MenuView / AppModel:** SwiftUI MenuBarExtra, main-actor presentation/settings, semantic localizable messages and OSLog. Language selection lives immediately before Quit.
- **LidStateMonitor:** public IOPMrootDomain general-interest notifications and AppleClamshellState. The CPlatform bridge only exposes an SDK macro Swift cannot import.
- **BluetoothEventMonitor:** global public connect notification plus per-connected-device disconnect subscriptions. A 150 ms debounce merges bursts; RefreshGate queues one additional snapshot if events arrive during a read. No steady polling.
- **BluetoothManager:** actor handles synchronous discovery/disconnect. Selected normalized addresses are re-resolved against current paired devices. A bounded observer checks link state without a retry loop.
- **Core:** tested lid transition policy, refresh coalescing, settings and eight native localization tables. AppText retains message meaning so history/errors re-render on language changes.
- **Packaging:** relocatable SwiftPM resource bundle in Contents/Resources, localized permission purpose strings, Apache license/notice and local ad-hoc signature. Release script makes a Universal image with a drag-to-Applications link.

LidDisconnect neither creates sleep assertions nor powers Bluetooth on/off. CoreBluetooth only requests permission/controller status; classic device connections use IOBluetooth. There is no plugin system, update service, analytics or runtime network dependency.
