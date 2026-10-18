import Foundation
import IOBluetooth

struct BluetoothDeviceIdentity: Hashable, Codable {
    let address: String
}

final class BluetoothManager {
    func pairedDevices() -> [BluetoothDeviceIdentity] {
        IOBluetoothDevice.pairedDevices().compactMap { device in
            guard let address = device.addressString else { return nil }
            return BluetoothDeviceIdentity(address: address)
        }
    }

    func disconnect(_ identity: BluetoothDeviceIdentity) -> Bool {
        guard let device = IOBluetoothDevice(addressString: identity.address) else { return false }
        return device.closeConnection() == kIOReturnSuccess
    }
}
