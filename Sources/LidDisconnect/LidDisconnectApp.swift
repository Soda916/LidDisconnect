import AppKit
import SwiftUI
import LidDisconnectCore

@main
enum EntryPoint {
    @MainActor static func main() {
        if CommandLine.arguments.contains("--probe-lid") {
            LidDiagnostics.run()
        } else if CommandLine.arguments.contains("--check-localizations") {
            for language in AppLanguage.allCases where language != .automatic {
                let localizer = Localizer(language: language)
                let value = localizer.text("quit")
                guard localizer.resourcesAreValid else { print("Missing localization: \(language.rawValue)"); exit(1) }
                print("\(language.rawValue): \(value)")
            }
        } else {
            LidDisconnectApp.main()
        }
    }
}

struct LidDisconnectApp: App {
    @StateObject private var model: AppModel

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
        let model = AppModel()
        _model = StateObject(wrappedValue: model)
        model.start()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuView(model: model)
        } label: {
            Image(systemName: model.isEnabled ? "laptopcomputer" : "pause.circle")
                .accessibilityLabel("LidDisconnect")
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
private enum LidDiagnostics {
    static func run() {
        let arguments = CommandLine.arguments
        let index = arguments.firstIndex(of: "--probe-lid")!
        let seconds = arguments.indices.contains(index + 1) ? Double(arguments[index + 1]) ?? 5 : 5
        let duration = min(max(seconds, 1), 3600)
        let monitor = LidStateMonitor()
        var failed = false
        monitor.onStateChange = { closed in
            print("\(Date().ISO8601Format()) physical_lid=\(closed ? "closed" : "open")")
            fflush(stdout)
        }
        monitor.onError = { message in
            failed = true
            print("ERROR: \(Localizer().render(message))")
        }
        print("Lid-only probe (\(Int(duration)) seconds). No Bluetooth calls or sleep assertions.")
        monitor.start()
        if !failed { RunLoop.main.run(until: Date().addingTimeInterval(duration)) }
        monitor.stop()
        print("Probe finished.")
        if failed { exit(1) }
    }
}
