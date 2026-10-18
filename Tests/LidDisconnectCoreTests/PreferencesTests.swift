import Foundation
import Testing
@testable import LidDisconnectCore

@Test func stableDeviceIdentity() throws {
    let first = try #require(BluetoothDeviceIdentity(address: "aa-bb-cc-dd-ee-01"))
    let second = try #require(BluetoothDeviceIdentity(address: "AA:BB:CC:DD:EE:01"))
    #expect(first == second)
    #expect(first.address == "AA:BB:CC:DD:EE:01")
    #expect(BluetoothDeviceIdentity(address: "Cleer ARC II") == nil)
    #expect(BluetoothDeviceIdentity(address: "00:00:00:00:00:00") == nil)
    #expect(BluetoothDeviceIdentity(address: "GG:BB:CC:DD:EE:01") == nil)
}

@Test @MainActor func settingsRoundTripAndCorruptData() throws {
    let suite = "LidDisconnect.tests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    let settings = Preferences(defaults: defaults)
    #expect(!settings.isEnabled)
    #expect(settings.language == .automatic)
    #expect(settings.selectedDevices.isEmpty)
    let first = try #require(BluetoothDeviceIdentity(address: "AA:BB:CC:DD:EE:01"))
    let second = try #require(BluetoothDeviceIdentity(address: "AA:BB:CC:DD:EE:02"))
    settings.isEnabled = true
    settings.language = .japanese
    settings.selectedDevices = [first, second]
    let restored = Preferences(defaults: defaults)
    #expect(restored.isEnabled)
    #expect(restored.language == .japanese)
    #expect(restored.selectedDevices == [first, second])
    defaults.set(Data("invalid".utf8), forKey: "selectedDevices")
    #expect(restored.selectedDevices.isEmpty)
}
