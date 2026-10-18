import Foundation
import Testing
@testable import LidDisconnectCore

@Test func languageDetection() {
    #expect(AppLanguage.detect(["zh-TW"]) == .traditionalChinese)
    #expect(AppLanguage.detect(["zh-HK"]) == .traditionalChinese)
    #expect(AppLanguage.detect(["zh-Hans-TW"]) == .simplifiedChinese)
    #expect(AppLanguage.detect(["zh-CN"]) == .simplifiedChinese)
    #expect(AppLanguage.detect(["ja-JP"]) == .japanese)
    #expect(AppLanguage.detect(["xx", "fr-CA"]) == .french)
    #expect(AppLanguage.detect(["ko_KR"]) == .korean)
    #expect(AppLanguage.detect(["xx"]) == .english)
    #expect(Localizer(language: .german, preferredLanguages: ["en"]).language == .german)
}

@Test func allTranslationsHaveMatchingKeysAndPlaceholders() throws {
    let english = try Localizer.entries(.english)
    #expect(english.count == 66)
    for language in AppLanguage.allCases where language != .automatic {
        let entries = try Localizer.entries(language)
        #expect(Set(entries.keys) == Set(english.keys))
        for (key, value) in entries {
            #expect(!value.isEmpty)
            #expect(value.components(separatedBy: "%@").count == english[key]!.components(separatedBy: "%@").count)
            #expect(Localizer(language: language).text(key) != key)
        }
    }
}

@Test func storedMessagesRerenderAfterLanguageSwitch() {
    let message = AppText.key("result.device", .literal("Test Headphones"), .key("disconnect.skip"))
    let en = Localizer(language: .english).render(message)
    let zh = Localizer(language: .traditionalChinese).render(message)
    #expect(en.contains("Already disconnected"))
    #expect(zh.contains("已斷線"))
    #expect(en.contains("Test Headphones"))
    #expect(zh.contains("Test Headphones"))
}
