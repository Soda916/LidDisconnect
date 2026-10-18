import Foundation
import IOBluetooth
import LidDisconnectCore

/// Public classic Bluetooth connection notifications, not a polling timer.
@MainActor
final class BluetoothEventMonitor: NSObject {
    var onChange: (() -> Void)?
    var onError: (() -> Void)?
    private var connection: IOBluetoothUserNotification?
    private var disconnections: [BluetoothDeviceIdentity: IOBluetoothUserNotification] = [:]
    private var debounce: Task<Void, Never>?

    func start() {
        guard connection == nil else { return }
        connection = IOBluetoothDevice.register(forConnectNotifications: self, selector: #selector(changed(_:device:)))
        if connection == nil { onError?() }
    }

    func synchronize(_ devices: [DeviceSnapshot]) {
        let connected = Set(devices.filter(\.connected).map(\.id))
        for id in Array(disconnections.keys) where !connected.contains(id) {
            disconnections.removeValue(forKey: id)?.unregister()
        }
        for id in connected where disconnections[id] == nil {
            guard let device = IOBluetoothDevice(addressString: id.address),
                  let token = device.register(forDisconnectNotification: self, selector: #selector(changed(_:device:))) else {
                onError?()
                continue
            }
            disconnections[id] = token
        }
    }

    @objc private nonisolated func changed(_ notification: IOBluetoothUserNotification, device: IOBluetoothDevice) {
        // Do not transfer the framework's non-Sendable device object across actors.
        Task { @MainActor [weak self] in self?.scheduleChange() }
    }

    private func scheduleChange() {
        guard connection != nil else { return }
        debounce?.cancel()
        debounce = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(150)) }
            catch { return }
            guard let self, !Task.isCancelled, self.connection != nil else { return }
            self.onChange?()
        }
    }

    func stop() {
        debounce?.cancel()
        debounce = nil
        connection?.unregister()
        connection = nil
        for token in disconnections.values { token.unregister() }
        disconnections.removeAll()
    }
}
