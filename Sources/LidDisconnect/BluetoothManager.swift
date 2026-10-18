import Foundation
import IOBluetooth
import LidDisconnectCore

struct DeviceSnapshot: Identifiable, Sendable {
    let id: BluetoothDeviceIdentity
    let name: String
    let connected: Bool
}

enum BluetoothError: LocalizedError {
    case unavailable
    case missingDevice

    var errorDescription: String? {
        switch self {
        case .unavailable: "藍牙未開啟或控制器暫時無法使用。"
        case .missingDevice: "裝置已不在配對清單；已略過斷線。"
        }
    }
}

struct DisconnectReport: Sendable {
    let message: String
    let verified: Bool
    let needsReview: Bool
}

/// All synchronous IOBluetooth work runs on this actor, away from the UI actor.
actor BluetoothManager {
    func pairedDevices() throws -> [DeviceSnapshot] {
        try Task.checkCancellation()
        try requireController()
        let snapshots = nativeDevices().compactMap { device -> DeviceSnapshot? in
            guard let address = device.addressString,
                  let identity = BluetoothDeviceIdentity(address: address) else { return nil }
            return DeviceSnapshot(id: identity, name: device.name ?? "未命名裝置", connected: device.isConnected())
        }
        // Defend against duplicate records as well as duplicate display names.
        return Dictionary(snapshots.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            .values.sorted { ($0.name, $0.id.address) < ($1.name, $1.id.address) }
    }

    func disconnect(_ identity: BluetoothDeviceIdentity) async throws -> DisconnectReport {
        try Task.checkCancellation()
        try requireController()
        // Resolve only against paired devices now, never from a name or arbitrary address.
        guard let device = findPaired(identity) else { throw BluetoothError.missingDevice }
        guard device.isConnected() else {
            return DisconnectReport(message: "已斷線，無需操作。", verified: true, needsReview: false)
        }
        try Task.checkCancellation()
        let result = device.closeConnection()
        // A zero return code alone is not proof of a lasting disconnection.
        var observedDisconnected = !device.isConnected()
        var reconnected = false
        var lastConnected = !observedDisconnected
        // Bounded observation at approximately 1, 3 and 8 seconds. No retry loop.
        for delay in [1, 2, 5] {
            try await Task.sleep(for: .seconds(delay))
            try requireController()
            guard let current = findPaired(identity) else { throw BluetoothError.missingDevice }
            lastConnected = current.isConnected()
            if observedDisconnected && lastConnected { reconnected = true }
            if !lastConnected { observedDisconnected = true }
        }
        if result != kIOReturnSuccess {
            return DisconnectReport(
                message: "斷線 API 失敗（\(result)）；目前\(lastConnected ? "仍連線" : "顯示已斷線")。請檢查權限或手動驗證。",
                verified: false, needsReview: true
            )
        }
        if reconnected {
            return DisconnectReport(message: "觀察到裝置自行重新連線；已停止自動斷線，請檢查耳機／macOS 設定。", verified: false, needsReview: true)
        }
        if lastConnected {
            return DisconnectReport(message: "API 回傳成功，但 8 秒後仍連線；已停止自動斷線，需真機調查。", verified: false, needsReview: true)
        }
        return DisconnectReport(message: "已觀察到斷線，8 秒內未發現重新連線。", verified: true, needsReview: false)
    }

    private func nativeDevices() -> [IOBluetoothDevice] {
        (IOBluetoothDevice.pairedDevices() ?? []).compactMap { $0 as? IOBluetoothDevice }
    }

    private func findPaired(_ identity: BluetoothDeviceIdentity) -> IOBluetoothDevice? {
        nativeDevices().first {
            guard let address = $0.addressString else { return false }
            return BluetoothDeviceIdentity(address: address) == identity
        }
    }

    private func requireController() throws {
        guard let controller = IOBluetoothHostController.default(),
              controller.powerState == kBluetoothHCIPowerStateON else {
            throw BluetoothError.unavailable
        }
    }
}
