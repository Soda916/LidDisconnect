import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let lidMonitor = LidStateMonitor()
    private let bluetoothManager = BluetoothManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "laptopcomputer", accessibilityDescription: "LidDisconnect")

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "LidDisconnect", action: nil, keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Enabled", action: #selector(toggleEnabled(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu

        lidMonitor.onStateChange = { [weak self] isClosed in
            guard isClosed else { return }
            self?.disconnectConfiguredDevices()
        }
        lidMonitor.start()
    }

    @objc private func toggleEnabled(_ item: NSMenuItem) {
        item.state = item.state == .on ? .off : .on
        lidMonitor.isEnabled = item.state == .on
    }

    private func disconnectConfiguredDevices() {
        // Device selection is intentionally not implemented until hardware behavior is validated.
        _ = bluetoothManager
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.setActivationPolicy(.accessory)
application.run()
