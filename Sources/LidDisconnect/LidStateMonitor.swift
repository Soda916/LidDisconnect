import Foundation
import IOKit

final class LidStateMonitor {
    var isEnabled = true
    var onStateChange: ((Bool) -> Void)?

    func start() {
        // TODO: validate the published IOKit lid-state property and event semantics on hardware.
        // This placeholder deliberately does not infer lid state from sleep or display events.
    }
}
