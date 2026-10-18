import AppKit
import Combine
import CoreBluetooth
import LidDisconnectCore
import OSLog
import ServiceManagement

struct EventEntry: Identifiable {
    let id = UUID()
    let date = Date()
    let message: AppText
}

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var isEnabled: Bool
    @Published private(set) var selected: Set<BluetoothDeviceIdentity>
    @Published private(set) var devices: [DeviceSnapshot] = []
    @Published private(set) var lidClosed: Bool?
    @Published private(set) var lidError: AppText?
    @Published private(set) var bluetoothStatus: AppText = .key("bluetooth.initial")
    @Published private(set) var authorization = CBManager.authorization
    @Published private(set) var isRefreshing = false
    @Published private(set) var isDisconnecting = false
    @Published private(set) var lastResult: AppText = .key("disconnect.initial")
    @Published private(set) var language: AppLanguage
    @Published private(set) var events: [EventEntry] = []
    @Published private(set) var loginEnabled = SMAppService.mainApp.status == .enabled
    @Published private(set) var loginNeedsApproval = SMAppService.mainApp.status == .requiresApproval

    private let preferences = Preferences()
    private let monitor = LidStateMonitor()
    private let bluetooth = BluetoothManager()
    private let permission = BluetoothAuthorization()
    private let bluetoothEvents = BluetoothEventMonitor()
    private var refreshGate = RefreshGate()
    private let logger = Logger(subsystem: "com.soda916.LidDisconnect", category: "events")
    private var policy = LidPolicy()
    private var started = false
    private var operation: Task<Void, Never>?
    private var operationID = UUID()
    private var refreshTask: Task<Void, Never>?

    init() {
        language = preferences.language
        isEnabled = preferences.isEnabled
        selected = preferences.selectedDevices
    }

    var localizer: Localizer { Localizer(language: language) }
    var version: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0" }
    func t(_ key: String, _ arguments: String...) -> String {
        localizer.render(.localized(key, arguments.map(AppText.literal)))
    }
    func t(_ message: AppText) -> String { localizer.render(message) }
    func deviceName(_ device: DeviceSnapshot) -> String { device.name.isEmpty ? t("device.unnamed") : device.name }
    func setLanguage(_ value: AppLanguage) {
        language = value
        preferences.language = value
    }

    func start() {
        guard !started else { return }
        started = true
        record(.key(isEnabled ? "log.start.enabled" : "log.start.paused", .literal(version)))
        monitor.onStateChange = { [weak self] closed in
            guard let self else { return }
            self.lidClosed = closed
            self.lidError = nil
            self.record(.key("log.lid", .key(closed ? "state.closed" : "state.open")))
            let shouldDisconnect = self.policy.receive(isClosed: closed, enabled: self.isEnabled)
            if shouldDisconnect { self.disconnectSelected(automatic: true) }
        }
        monitor.onError = { [weak self] message in
            guard let self else { return }
            self.lidClosed = nil
            self.lidError = message
            _ = self.policy.receive(isClosed: nil, enabled: false)
            self.pause(reason: message)
        }
        permission.onChange = { [weak self] in self?.refresh() }
        bluetoothEvents.onChange = { [weak self] in self?.refresh() }
        bluetoothEvents.onError = { [weak self] in
            self?.record(.key("log.eventsFailed"))
        }
        monitor.start()
        refresh()
    }

    func setEnabled(_ value: Bool) {
        guard !value || (lidError == nil && lidClosed != nil && !selected.isEmpty && authorization == .allowedAlways) else { return }
        if !value { cancelOperation() }
        isEnabled = value
        preferences.isEnabled = value
        record(.key(value ? "log.enabled" : "log.paused"))
    }

    func setSelected(_ id: BluetoothDeviceIdentity, selected value: Bool) {
        guard !isDisconnecting else { return }
        if value {
            guard devices.contains(where: { $0.id == id }) else { return }
            selected.insert(id)
        } else {
            selected.remove(id)
        }
        preferences.selectedDevices = selected
        if selected.isEmpty { setEnabled(false) }
    }

    func requestBluetooth() {
        guard Bundle.main.bundleURL.pathExtension == "app" else {
            lastResult = .key("permission.bundle")
            record(lastResult)
            return
        }
        if authorization == .denied || authorization == .restricted {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Bluetooth") {
                NSWorkspace.shared.open(url)
            }
        } else {
            permission.request()
        }
    }

    func refresh() {
        authorization = CBManager.authorization
        updateLoginStatus()
        guard authorization == .allowedAlways else {
            bluetoothEvents.stop()
            devices = []
            bluetoothStatus = .key(authorization == .notDetermined ? "bluetooth.permission" : "bluetooth.denied")
            if isEnabled { pause(reason: bluetoothStatus) }
            return
        }
        bluetoothEvents.start()
        guard refreshGate.request() else { return }
        isRefreshing = true
        refreshTask = Task { [weak self] in
            guard let self else { return }
            defer { self.isRefreshing = false }
            repeat {
                do {
                    let snapshot = try await self.bluetooth.pairedDevices()
                    guard !Task.isCancelled, CBManager.authorization == .allowedAlways else { break }
                    self.devices = snapshot
                    self.bluetoothEvents.synchronize(snapshot)
                    self.bluetoothStatus = self.devices.isEmpty ? .key("bluetooth.empty") : .key("bluetooth.count", .literal(String(self.devices.count)))
                } catch is CancellationError {
                    break
                } catch {
                    self.devices = []
                    self.bluetoothEvents.synchronize([])
                    self.bluetoothStatus = Self.errorText(error)
                    self.record(self.bluetoothStatus)
                }
            } while self.refreshGate.finish()
            self.refreshGate = RefreshGate()
        }
    }

    func disconnectSelected(automatic: Bool = false) {
        guard !isDisconnecting, !selected.isEmpty else { return }
        guard CBManager.authorization == .allowedAlways else {
            pause(reason: .key("error.permission"))
            return
        }
        let ids = selected.sorted { $0.address < $1.address }
        let names = Dictionary(uniqueKeysWithValues: devices.map { ($0.id, $0.name) })
        let token = UUID()
        operationID = token
        isDisconnecting = true
        lastResult = .key("disconnect.progress", .literal(String(ids.count)))
        record(.key(automatic ? "log.auto" : "log.manual"))
        operation = Task { [weak self] in
            guard let self else { return }
            defer {
                if self.operationID == token {
                    self.isDisconnecting = false
                    self.refresh()
                }
            }
            for id in ids {
                guard !Task.isCancelled, self.operationID == token,
                      self.selected.contains(id), !automatic || (self.isEnabled && self.lidClosed == true) else { return }
                do {
                    let report = try await self.bluetooth.disconnect(id)
                    guard !Task.isCancelled, self.operationID == token else { return }
                    let name = names[id] ?? ""
                    let label: AppText = name.isEmpty ? .key("device.unnamed") : .literal(name)
                    self.lastResult = .key("result.device", label, report.message)
                    self.record(self.lastResult)
                    if report.needsReview {
                        self.isEnabled = false
                        self.preferences.isEnabled = false
                        self.record(.key("log.review"))
                        return
                    }
                } catch is CancellationError {
                    return
                } catch {
                    guard self.operationID == token else { return }
                    self.lastResult = Self.errorText(error)
                    self.record(self.lastResult)
                    self.isEnabled = false
                    self.preferences.isEnabled = false
                    return
                }
            }
        }
    }

    func setLoginEnabled(_ enabled: Bool) {
        guard Bundle.main.bundleURL.pathExtension == "app" else {
            record(.key("login.bundle")); return
        }
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
            updateLoginStatus()
            record(.key(loginNeedsApproval ? "login.approval" : "login.updated"))
        } catch { record(.key("login.error", .literal(error.localizedDescription))) }
    }

    func openLoginSettings() { SMAppService.openSystemSettingsLoginItems() }

    func copyDiagnostics() {
        let text = events.reversed().map { "\($0.date.ISO8601Format()) \(t($0.message))" }.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    func stop() {
        cancelOperation()
        refreshTask?.cancel()
        bluetoothEvents.stop()
        monitor.stop()
    }

    private func cancelOperation() {
        operation?.cancel()
        operationID = UUID()
        if isDisconnecting { lastResult = .key("operation.cancelled") }
        isDisconnecting = false
    }

    private func pause(reason: AppText) {
        cancelOperation()
        isEnabled = false
        preferences.isEnabled = false
        lastResult = reason
        record(reason)
    }

    private func updateLoginStatus() {
        loginEnabled = SMAppService.mainApp.status == .enabled
        loginNeedsApproval = SMAppService.mainApp.status == .requiresApproval
    }

    private static func errorText(_ error: any Error) -> AppText {
        if let error = error as? BluetoothError { return error.message }
        return .key("error.system", .literal(error.localizedDescription))
    }

    private func record(_ message: AppText) {
        events.insert(EventEntry(message: message), at: 0)
        if events.count > 60 { events.removeLast(events.count - 60) }
        logger.info("\(self.t(message), privacy: .private)")
    }
}
