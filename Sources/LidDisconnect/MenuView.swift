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
                    Text("v\(model.version)").foregroundStyle(.secondary)
                }
                Text(model.t("status", model.t(model.isEnabled ? "state.enabled" : "state.paused"), lidText))
                    .font(.subheadline)
                if let error = model.lidError {
                    Text(model.t(error)).foregroundStyle(.red)
                }
                Toggle(model.t("auto.title"), isOn: Binding(
                    get: { model.isEnabled }, set: { model.setEnabled($0) }
                ))
                .disabled(!model.isEnabled && (model.selected.isEmpty || model.lidClosed == nil || model.authorization != .allowedAlways))
                Text(model.t("auto.help"))
                    .font(.caption).foregroundStyle(.secondary)

                Divider()
                HStack {
                    Text(model.t("devices.selected", String(model.selected.count))).font(.headline)
                    Spacer()
                    Button(model.t("refresh")) { model.refresh() }
                        .disabled(model.isRefreshing || model.isDisconnecting)
                }
                Text(model.t("refresh.hint")).font(.caption).foregroundStyle(.secondary)
                Text(model.t(model.bluetoothStatus)).font(.caption).foregroundStyle(.secondary)
                if model.authorization != .allowedAlways {
                    Button(model.t(model.authorization == .notDetermined ? "permission.allow" : "permission.settings")) {
                        model.requestBluetooth()
                    }
                }
                ForEach(model.devices) { device in
                    Toggle(isOn: Binding(
                        get: { model.selected.contains(device.id) },
                        set: { model.setSelected(device.id, selected: $0) }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(model.deviceName(device))
                            Text("\(device.id.address) · \(model.t(device.connected ? "state.connected" : "state.disconnected"))")
                                .font(.caption.monospaced()).foregroundStyle(.secondary)
                        }
                    }
                    .toggleStyle(.checkbox)
                    .disabled(model.isDisconnecting)
                }
                ForEach(missingDevices) { id in
                    HStack {
                        Text(model.t("device.unavailable", id.address)).font(.caption.monospaced())
                        Spacer()
                        Button(model.t("remove")) { model.setSelected(id, selected: false) }
                            .disabled(model.isDisconnecting)
                    }
                }
                HStack {
                    Button(model.t("disconnect.test")) { model.disconnectSelected() }
                        .disabled(model.selected.isEmpty || model.isDisconnecting || model.authorization != .allowedAlways)
                    if model.isDisconnecting {
                        ProgressView().controlSize(.small)
                        Button(model.t("disconnect.stop")) { model.setEnabled(false) }
                    }
                }
                Text(model.t(model.lastResult)).font(.caption).textSelection(.enabled)

                Divider()
                Toggle(model.t("login.title"), isOn: Binding(
                    get: { model.loginEnabled || model.loginNeedsApproval },
                    set: { model.setLoginEnabled($0) }
                ))
                .disabled(Bundle.main.bundleURL.pathExtension != "app")
                if model.loginNeedsApproval {
                    Button(model.t("login.approve")) { model.openLoginSettings() }
                }
                DisclosureGroup(model.t("history")) {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(model.events.prefix(15)) { event in
                            Text("\(event.date.formatted(Date.FormatStyle(date: .omitted, time: .standard).locale(Locale(identifier: model.localizer.language.rawValue)))) \(model.t(event.message))")
                                .font(.caption).textSelection(.enabled)
                        }
                    }
                }
                HStack {
                    Button(model.t("copy")) { model.copyDiagnostics() }
                    Spacer()
                    Picker(model.t("language"), selection: Binding(
                        get: { model.language }, set: { model.setLanguage($0) }
                    )) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language == .automatic ? model.t("language.system") : language.nativeName).tag(language)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(maxWidth: 140)
                    .accessibilityLabel(model.t("language"))
                    Button(model.t("quit")) {
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
        case true: model.t("state.closed")
        case false: model.t("state.open")
        case nil: model.t("state.unknown")
        }
    }

    private var missingDevices: [BluetoothDeviceIdentity] {
        let available = Set(model.devices.map(\.id))
        return model.selected.subtracting(available).sorted { $0.address < $1.address }
    }
}
