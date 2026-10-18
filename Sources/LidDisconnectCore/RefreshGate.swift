/// Coalesces changes received during an in-flight snapshot into one more read.
public struct RefreshGate: Sendable {
    private var running = false
    private var pending = false
    public init() {}

    public mutating func request() -> Bool {
        if running { pending = true; return false }
        running = true
        return true
    }

    public mutating func finish() -> Bool {
        if pending { pending = false; return true }
        running = false
        return false
    }
}
