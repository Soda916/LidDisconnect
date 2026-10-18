import Foundation

public struct BluetoothDeviceIdentity: Hashable, Codable, Sendable, Identifiable {
    public let address: String
    public var id: String { address }

    public init?(address: String) {
        let parts = address.replacingOccurrences(of: "-", with: ":").uppercased().split(separator: ":")
        guard parts.count == 6,
              parts.allSatisfy({ $0.count == 2 && $0.allSatisfy(\.isHexDigit) }),
              !parts.allSatisfy({ $0 == "00" }),
              !parts.allSatisfy({ $0 == "FF" }) else { return nil }
        self.address = parts.joined(separator: ":")
    }

    private enum CodingKeys: String, CodingKey { case address }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let address = try container.decode(String.self, forKey: .address)
        guard let value = Self(address: address) else {
            throw DecodingError.dataCorruptedError(forKey: .address, in: container, debugDescription: "Invalid Bluetooth address")
        }
        self = value
    }
}
