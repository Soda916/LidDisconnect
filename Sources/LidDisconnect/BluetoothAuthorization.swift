import CoreBluetooth
import Foundation

@MainActor
final class BluetoothAuthorization: NSObject, CBCentralManagerDelegate {
    var onChange: (() -> Void)?
    private var manager: CBCentralManager?

    func request() {
        guard manager == nil else { onChange?(); return }
        manager = CBCentralManager(delegate: self, queue: .main, options: [CBCentralManagerOptionShowPowerAlertKey: false])
    }

    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor [weak self] in self?.onChange?() }
    }
}
