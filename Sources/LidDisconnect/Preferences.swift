import Foundation

struct Preferences {
    private let defaults = UserDefaults.standard
    var isEnabled: Bool {
        get { defaults.object(forKey: "enabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "enabled") }
    }
    var selectedDevices: Set<BluetoothDeviceIdentity> {
        get {
            guard let data = defaults.data(forKey: "selectedDevices"),
                  let values = try? JSONDecoder().decode([BluetoothDeviceIdentity].self, from: data)
            else { return [] }
            return Set(values)
        }
        set {
            let data = try? JSONEncoder().encode(Array(newValue))
            defaults.set(data, forKey: "selectedDevices")
        }
    }
}
