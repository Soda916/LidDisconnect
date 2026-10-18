import Foundation

@MainActor
public struct Preferences {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    public var isEnabled: Bool {
        get { defaults.object(forKey: "enabled") as? Bool ?? false }
        nonmutating set { defaults.set(newValue, forKey: "enabled") }
    }

    public var selectedDevices: Set<BluetoothDeviceIdentity> {
        get {
            guard let data = defaults.data(forKey: "selectedDevices"),
                  let values = try? JSONDecoder().decode([BluetoothDeviceIdentity].self, from: data)
            else { return [] }
            return Set(values)
        }
        nonmutating set {
            if let data = try? JSONEncoder().encode(Array(newValue).sorted { $0.address < $1.address }) {
                defaults.set(data, forKey: "selectedDevices")
            }
        }
    }
}
