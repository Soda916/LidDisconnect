import Foundation
import IOKit
import IOKit.pwr_mgt
import CPlatform
import LidDisconnectCore

@MainActor
final class LidStateMonitor {
    var onStateChange: ((Bool) -> Void)?
    var onError: ((AppText) -> Void)?
    private(set) var state: Bool?
    private var service: io_service_t = 0
    private var notifier: io_object_t = 0
    private var port: IONotificationPortRef?
    private var source: CFRunLoopSource?

    func start() {
        guard port == nil else { return }
        service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPMrootDomain"))
        guard service != 0 else { fail(.key("error.lid.service")); return }
        guard let createdPort = IONotificationPortCreate(kIOMainPortDefault) else {
            fail(.key("error.lid.port")); return
        }
        port = createdPort
        guard let runLoopSource = IONotificationPortGetRunLoopSource(createdPort)?.takeUnretainedValue() else {
            fail(.key("error.lid.source")); return
        }
        source = runLoopSource
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        let result = IOServiceAddInterestNotification(
            createdPort, service, kIOGeneralInterest,
            { context, _, message, argument in
                guard message == LDClamshellStateChangeMessage(), let context else { return }
                // The notification port is attached exclusively to the main run loop.
                MainActor.assumeIsolated {
                    let monitor = Unmanaged<LidStateMonitor>.fromOpaque(context).takeUnretainedValue()
                    let bits = UInt(bitPattern: argument)
                    monitor.deliver(bits & UInt(kClamshellStateBit) != 0)
                }
            },
            Unmanaged.passUnretained(self).toOpaque(), &notifier
        )
        guard result == kIOReturnSuccess else { fail(.key("error.lid.register", .literal(String(result)))); return }
        guard let value = IORegistryEntryCreateCFProperty(
            service, kAppleClamshellStateKey as CFString, kCFAllocatorDefault, 0
        )?.takeRetainedValue() as? Bool else {
            fail(.key("error.lid.unsupported")); return
        }
        deliver(value)
    }

    private func deliver(_ closed: Bool) {
        guard state != closed else { return }
        state = closed
        onStateChange?(closed)
    }

    private func fail(_ message: AppText) {
        stop()
        onError?(message)
    }

    func stop() {
        if notifier != 0 { IOObjectRelease(notifier); notifier = 0 }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        source = nil
        if let port { IONotificationPortDestroy(port) }
        port = nil
        if service != 0 { IOObjectRelease(service); service = 0 }
        state = nil
    }
}
