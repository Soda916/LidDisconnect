import AppKit
import LidDisconnectCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let lidMonitor = LidStateMonitor()
    private let bluetoothManager = BluetoothManager()
    private var policy = LidPolicy()
    private var enabled = false

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
            guard let self, self.policy.receive(isClosed: isClosed, enabled: self.enabled) else { return }
            self.disconnectConfiguredDevices()
        }
        lidMonitor.start()
    }

    @objc private func toggleEnabled(_ item: NSMenuItem) {
        item.state = item.state == .on ? .off : .on
        enabled = item.state == .on
    }

    private func disconnectConfiguredDevices() {
        // Device selection is intentionally not implemented until hardware behavior is validated.
        _ = bluetoothManager
    }

    @objc private func quit() {
        lidMonitor.stop()
        NSApplication.shared.terminate(nil)
    }
}

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.setActivationPolicy(.accessory)
application.run()
