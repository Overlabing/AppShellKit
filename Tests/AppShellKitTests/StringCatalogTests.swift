import Foundation
import Testing

/// The kit's catalog: every string has a French translation, and every string the code asks for is in it.
@Suite("String catalog")
struct StringCatalogTests {
    private static let sources = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appending(path: "Sources/AppShellKit")

    private static func catalog() throws -> [String: Any] {
        let data = try Data(contentsOf: sources.appending(path: "Resources/AppShellKit.xcstrings"))
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["sourceLanguage"] as? String == "en")
        return try #require(json["strings"] as? [String: Any])
    }

    @Test("every key has a translated French value with the same placeholders")
    func french() throws {
        let strings = try Self.catalog()
        #expect(strings.count == 27)
        for (key, entry) in strings {
            let unit = ((entry as? [String: Any])?["localizations"] as? [String: Any])?["fr"] as? [String: Any]
            let value = (unit?["stringUnit"] as? [String: Any])
            #expect(value?["state"] as? String == "translated", "\(key)")
            let french = value?["value"] as? String ?? ""
            #expect(!french.isEmpty, "\(key)")
            #expect(key.components(separatedBy: "%@").count == french.components(separatedBy: "%@").count, "\(key)")
        }
    }

    @Test("every string the code looks up is in the catalog")
    func complete() throws {
        let keys = Set(try Self.catalog().keys)
        let files = try #require(FileManager.default.enumerator(at: Self.sources, includingPropertiesForKeys: nil))
        var used: Set<String> = []
        let pattern = /localized\("((?:[^"\\]|\\.)*)"\)/
        for case let file as URL in files where file.pathExtension == "swift" {
            let text = try String(contentsOf: file, encoding: .utf8)
            for match in text.matches(of: pattern) {
                used.insert(String(match.1).replacing(/\\\([^)]*\)/, with: "%@"))
            }
        }
        #expect(used.count == keys.count)
        #expect(used.subtracting(keys).isEmpty, "missing: \(used.subtracting(keys).sorted())")
        #expect(keys.subtracting(used).isEmpty, "unused: \(keys.subtracting(used).sorted())")
    }
}
