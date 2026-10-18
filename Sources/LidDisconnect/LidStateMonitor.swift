import Foundation
import IOKit
import IOKit.pwr_mgt
import CPlatform

@MainActor
final class LidStateMonitor {
    var onStateChange: ((Bool) -> Void)?
    var onError: ((String) -> Void)?
    private(set) var state: Bool?
    private var service: io_service_t = 0
    private var notifier: io_object_t = 0
    private var port: IONotificationPortRef?
    private var source: CFRunLoopSource?

    func start() {
        guard port == nil else { return }
        service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPMrootDomain"))
        guard service != 0 else { fail("無法取得電源管理服務"); return }
        guard let createdPort = IONotificationPortCreate(kIOMainPortDefault) else {
            fail("無法建立闔蓋事件通知"); return
        }
        port = createdPort
        guard let runLoopSource = IONotificationPortGetRunLoopSource(createdPort)?.takeUnretainedValue() else {
            fail("無法建立闔蓋事件來源"); return
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
        guard result == kIOReturnSuccess else { fail("闔蓋事件註冊失敗：\(result)"); return }
        guard let value = IORegistryEntryCreateCFProperty(
            service, kAppleClamshellStateKey as CFString, kCFAllocatorDefault, 0
        )?.takeRetainedValue() as? Bool else {
            fail("此硬體未提供實際闔蓋狀態"); return
        }
        deliver(value)
    }

    private func deliver(_ closed: Bool) {
        guard state != closed else { return }
        state = closed
        onStateChange?(closed)
    }

    private func fail(_ message: String) {
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
