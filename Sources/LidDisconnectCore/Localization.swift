import Foundation

public enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case automatic = "system"
    case english = "en"
    case traditionalChinese = "zh-Hant"
    case simplifiedChinese = "zh-Hans"
    case japanese = "ja"
    case korean = "ko"
    case german = "de"
    case french = "fr"
    case spanish = "es"

    public var id: String { rawValue }
    public var nativeName: String {
        switch self {
        case .automatic: "System"
        case .english: "English"
        case .traditionalChinese: "繁體中文"
        case .simplifiedChinese: "简体中文"
        case .japanese: "日本語"
        case .korean: "한국어"
        case .german: "Deutsch"
        case .french: "Français"
        case .spanish: "Español"
        }
    }

    public static func detect(_ preferredLanguages: [String]) -> Self {
        for preference in preferredLanguages {
            let tag = preference.replacingOccurrences(of: "_", with: "-").lowercased()
            if tag == "zh" || tag.hasPrefix("zh-") {
                let parts = Set(tag.split(separator: "-").map(String.init))
                if parts.contains("hant") { return .traditionalChinese }
                if parts.contains("hans") { return .simplifiedChinese }
                return !parts.isDisjoint(with: ["tw", "hk", "mo"]) ? .traditionalChinese : .simplifiedChinese
            }
            if let match = allCases.first(where: { $0 != .automatic && (tag == $0.rawValue || tag.hasPrefix($0.rawValue + "-")) }) {
                return match
            }
        }
        return .english
    }
}

/// Store semantic messages so existing status/results also change language live.
public indirect enum AppText: Sendable {
    case localized(String, [AppText])
    case literal(String)

    public static func key(_ key: String, _ arguments: AppText...) -> Self { .localized(key, arguments) }
}

public struct Localizer: Sendable {
    public let language: AppLanguage
    public init(language: AppLanguage = .automatic, preferredLanguages: [String] = Locale.preferredLanguages) {
        self.language = language == .automatic ? AppLanguage.detect(preferredLanguages) : language
    }

    public func text(_ key: String, _ arguments: String...) -> String {
        render(.localized(key, arguments.map(AppText.literal)))
    }

    public func render(_ message: AppText) -> String {
        switch message {
        case .literal(let value): return value
        case .localized(let key, let arguments):
            let translated = bundle.localizedString(forKey: key, value: nil, table: nil)
            let parts = translated.components(separatedBy: "%@")
            guard parts.count == arguments.count + 1 else { return translated }
            var value = parts[0]
            for (index, argument) in arguments.enumerated() {
                value += render(argument) + parts[index + 1]
            }
            return value
        }
    }

    private var bundle: Bundle {
        guard let path = Self.resources.path(forResource: language.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return Self.resources }
        return bundle
    }

    private static var resources: Bundle {
        if Bundle.main.bundleURL.pathExtension == "app" {
            if let url = Bundle.main.url(forResource: "LidDisconnect_LidDisconnectCore", withExtension: "bundle"),
               let bundle = Bundle(url: url) { return bundle }
            // Never depend on the developer's absolute SwiftPM build path in a shipped app.
            return Bundle.main
        }
        return Bundle.module
    }

    // Internal access for completeness/placeholder tests against every translation.
    static func entries(_ language: AppLanguage) throws -> [String: String] {
        let url = resources.url(forResource: "Localizable", withExtension: "strings", subdirectory: nil, localization: language.rawValue)!
        return try PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil) as! [String: String]
    }
}
