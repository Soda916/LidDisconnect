import AppKit
import CoreBluetooth
import LidDisconnectCore
import SwiftUI

struct MenuView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("LidDisconnect", systemImage: "laptopcomputer")
                        .font(.headline)
                    Spacer()
                    Text("v0.1").foregroundStyle(.secondary)
                }
                Text("\(model.isEnabled ? "啟用中" : "已暫停") · 上蓋\(lidText)")
                    .font(.subheadline)
                if let error = model.lidError {
                    Text(error).foregroundStyle(.red)
                }
                Toggle("闔蓋時自動斷線", isOn: Binding(
                    get: { model.isEnabled }, set: { model.setEnabled($0) }
                ))
                .disabled(!model.isEnabled && (model.selected.isEmpty || model.lidClosed == nil || model.authorization != .allowedAlways))
                Text("先測試耳機斷線及是否自行重連，再啟用自動功能。開蓋不會主動連線。")
                    .font(.caption).foregroundStyle(.secondary)

                Divider()
                HStack {
                    Text("所選裝置（\(model.selected.count)）").font(.headline)
                    Spacer()
                    Button("重新整理") { model.refresh() }
                        .disabled(model.isRefreshing || model.isDisconnecting)
                }
                Text(model.bluetoothStatus).font(.caption).foregroundStyle(.secondary)
                if model.authorization != .allowedAlways {
                    Button(model.authorization == .notDetermined ? "允許藍牙存取" : "開啟藍牙隱私設定") {
                        model.requestBluetooth()
                    }
                }
                ForEach(model.devices) { device in
                    Toggle(isOn: Binding(
                        get: { model.selected.contains(device.id) },
                        set: { model.setSelected(device.id, selected: $0) }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(device.name)
                            Text("\(device.id.address) · \(device.connected ? "已連線" : "未連線")")
                                .font(.caption.monospaced()).foregroundStyle(.secondary)
                        }
                    }
                    .toggleStyle(.checkbox)
                    .disabled(model.isDisconnecting)
                }
                ForEach(missingDevices) { id in
                    HStack {
                        Text("\(id.address) · 目前無法讀取").font(.caption.monospaced())
                        Spacer()
                        Button("移除") { model.setSelected(id, selected: false) }
                            .disabled(model.isDisconnecting)
                    }
                }
                HStack {
                    Button("測試斷線所選裝置") { model.disconnectSelected() }
                        .disabled(model.selected.isEmpty || model.isDisconnecting || model.authorization != .allowedAlways)
                    if model.isDisconnecting {
                        ProgressView().controlSize(.small)
                        Button("停止後續操作") { model.setEnabled(false) }
                    }
                }
                Text(model.lastResult).font(.caption).textSelection(.enabled)

                Divider()
                Toggle("登入時啟動", isOn: Binding(
                    get: { model.loginEnabled || model.loginNeedsApproval },
                    set: { model.setLoginEnabled($0) }
                ))
                .disabled(Bundle.main.bundleURL.pathExtension != "app")
                if model.loginNeedsApproval {
                    Button("核准登入項目…") { model.openLoginSettings() }
                }
                DisclosureGroup("最近操作紀錄") {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(model.events.prefix(15)) { event in
                            Text("\(event.date.formatted(date: .omitted, time: .standard)) \(event.message)")
                                .font(.caption).textSelection(.enabled)
                        }
                    }
                }
                HStack {
                    Button("複製診斷紀錄") { model.copyDiagnostics() }
                    Spacer()
                    Button("結束") {
                        model.stop()
                        NSApplication.shared.terminate(nil)
                    }
                    .keyboardShortcut("q")
                }
            }
            .padding(18)
        }
        .frame(width: 410, height: 610)
        .onAppear { model.refresh() }
    }

    private var lidText: String {
        switch model.lidClosed {
        case true: "已闔蓋"
        case false: "已開啟"
        case nil: "未知"
        }
    }

    private var missingDevices: [BluetoothDeviceIdentity] {
        let available = Set(model.devices.map(\.id))
        return model.selected.subtracting(available).sorted { $0.address < $1.address }
    }
}
