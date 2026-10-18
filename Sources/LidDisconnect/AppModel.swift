import AppKit
import Combine
import CoreBluetooth
import LidDisconnectCore
import OSLog
import ServiceManagement

struct EventEntry: Identifiable {
    let id = UUID()
    let date = Date()
    let message: String
}

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var isEnabled: Bool
    @Published private(set) var selected: Set<BluetoothDeviceIdentity>
    @Published private(set) var devices: [DeviceSnapshot] = []
    @Published private(set) var lidClosed: Bool?
    @Published private(set) var lidError: String?
    @Published private(set) var bluetoothStatus = "尚未讀取藍牙裝置"
    @Published private(set) var authorization = CBManager.authorization
    @Published private(set) var isRefreshing = false
    @Published private(set) var isDisconnecting = false
    @Published private(set) var lastResult = "請選定裝置，先按「測試斷線」確認耳機行為。"
    @Published private(set) var events: [EventEntry] = []
    @Published private(set) var loginEnabled = SMAppService.mainApp.status == .enabled
    @Published private(set) var loginNeedsApproval = SMAppService.mainApp.status == .requiresApproval

    private let preferences = Preferences()
    private let monitor = LidStateMonitor()
    private let bluetooth = BluetoothManager()
    private let permission = BluetoothAuthorization()
    private let logger = Logger(subsystem: "com.soda916.LidDisconnect", category: "events")
    private var policy = LidPolicy()
    private var started = false
    private var operation: Task<Void, Never>?
    private var operationID = UUID()
    private var refreshTask: Task<Void, Never>?

    init() {
        isEnabled = preferences.isEnabled
        selected = preferences.selectedDevices
    }

    func start() {
        guard !started else { return }
        started = true
        record("LidDisconnect 0.1 啟動；\(isEnabled ? "自動功能啟用" : "暫停中")。")
        monitor.onStateChange = { [weak self] closed in
            guard let self else { return }
            self.lidClosed = closed
            self.lidError = nil
            self.record("實際上蓋：\(closed ? "闔蓋" : "開蓋")。")
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
        monitor.start()
        refresh()
    }

    func setEnabled(_ value: Bool) {
        guard !value || (lidError == nil && lidClosed != nil && !selected.isEmpty && authorization == .allowedAlways) else { return }
        if !value { cancelOperation() }
        isEnabled = value
        preferences.isEnabled = value
        record(value ? "已啟用：下次實際闔蓋時中斷所選裝置。" : "自動功能已暫停。")
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
            lastResult = "請使用 scripts/build-app.sh 產生的 .app，才能正確要求藍牙權限。"
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
            devices = []
            bluetoothStatus = authorization == .notDetermined ? "請授權藍牙存取，再讀取已配對裝置。" : "藍牙權限未允許；請至系統設定開啟。"
            if isEnabled { pause(reason: bluetoothStatus) }
            return
        }
        guard !isRefreshing else { return }
        isRefreshing = true
        refreshTask = Task { [weak self] in
            guard let self else { return }
            defer { self.isRefreshing = false }
            do {
                self.devices = try await self.bluetooth.pairedDevices()
                self.bluetoothStatus = self.devices.isEmpty ? "沒有可用的已配對裝置。" : "\(self.devices.count) 個已配對裝置"
            } catch is CancellationError {
                return
            } catch {
                self.devices = []
                self.bluetoothStatus = error.localizedDescription
                self.record(error.localizedDescription)
            }
        }
    }

    func disconnectSelected(automatic: Bool = false) {
        guard !isDisconnecting, !selected.isEmpty else { return }
        guard CBManager.authorization == .allowedAlways else {
            pause(reason: "藍牙權限未允許，已略過斷線。")
            return
        }
        let ids = selected.sorted { $0.address < $1.address }
        let names = Dictionary(uniqueKeysWithValues: devices.map { ($0.id, $0.name) })
        let token = UUID()
        operationID = token
        isDisconnecting = true
        lastResult = "正在中斷 \(ids.count) 個所選裝置並觀察 8 秒…"
        record(automatic ? "收到實際闔蓋事件，開始斷線。" : "使用者啟動手動斷線測試。")
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
                    let label = names[id] ?? "所選裝置"
                    self.lastResult = "\(label)：\(report.message)"
                    self.record(self.lastResult)
                    if report.needsReview {
                        self.isEnabled = false
                        self.preferences.isEnabled = false
                        self.record("需人工檢查，自動功能已暫停；不再嘗試其他裝置。")
                        return
                    }
                } catch is CancellationError {
                    return
                } catch {
                    guard self.operationID == token else { return }
                    self.lastResult = error.localizedDescription
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
            record("登入啟動需要使用打包後的 LidDisconnect.app。"); return
        }
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
            updateLoginStatus()
            record(loginNeedsApproval ? "請在系統設定核准登入項目。" : "登入啟動設定已更新。")
        } catch { record("登入啟動設定失敗：\(error.localizedDescription)") }
    }

    func openLoginSettings() { SMAppService.openSystemSettingsLoginItems() }

    func copyDiagnostics() {
        let text = events.reversed().map { "\($0.date.ISO8601Format()) \($0.message)" }.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    func stop() {
        cancelOperation()
        refreshTask?.cancel()
        monitor.stop()
    }

    private func cancelOperation() {
        operation?.cancel()
        operationID = UUID()
        if isDisconnecting { lastResult = "後續操作已取消；已送出的斷線要求無法撤回。" }
        isDisconnecting = false
    }

    private func pause(reason: String) {
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

    private func record(_ message: String) {
        events.insert(EventEntry(message: message), at: 0)
        if events.count > 60 { events.removeLast(events.count - 60) }
        logger.info("\(message, privacy: .private)")
    }
}
