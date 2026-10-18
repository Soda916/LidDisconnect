import Testing
@testable import LidDisconnectCore

@Test func physicalTransitionsOnly() {
    var policy = LidPolicy()
    let results = [true, true, false, true, true, false].map {
        policy.receive(isClosed: $0, enabled: true)
    }
    #expect(results == [false, false, false, true, false, false])
}

@Test func pauseAndReenableWhileClosed() {
    var policy = LidPolicy()
    let events = [(false, false), (true, false), (true, true), (false, true), (true, true)]
    let results = events.map { policy.receive(isClosed: $0.0, enabled: $0.1) }
    #expect(results == [false, false, false, false, true])
}

@Test func unknownStateDoesNotImplyAnOpenLid() {
    var policy = LidPolicy()
    let events: [Bool?] = [false, nil, true]
    let results = events.map { policy.receive(isClosed: $0, enabled: true) }
    #expect(results == [false, false, false])
}
