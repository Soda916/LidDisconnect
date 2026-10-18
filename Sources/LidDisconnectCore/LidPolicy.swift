/// Only a physical open-to-closed transition may trigger automatic disconnection.
/// Initial closed state and duplicate messages must not disconnect peripherals.
public struct LidPolicy: Sendable {
    public private(set) var lastState: Bool?

    public init() {}

    public mutating func receive(isClosed: Bool?, enabled: Bool) -> Bool {
        let previous = lastState
        lastState = isClosed
        return enabled && previous == false && isClosed == true
    }
}
