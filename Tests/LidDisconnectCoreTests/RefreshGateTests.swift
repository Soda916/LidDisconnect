import Testing
@testable import LidDisconnectCore

@Test func changesDuringSnapshotAreNotLost() {
    var gate = RefreshGate()
    let first = gate.request()
    let burst = (0..<20).map { _ in gate.request() }
    let needsAnotherSnapshot = gate.finish()
    let finished = gate.finish()
    let nextEvent = gate.request()
    #expect(first)
    #expect(burst.allSatisfy { !$0 })
    #expect(needsAnotherSnapshot)
    #expect(!finished)
    #expect(nextEvent)
}
