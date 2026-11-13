import Foundation
import Localization

/// A string of the kit's own catalog, `AppShellKit.xcstrings`. It follows the user's languages, unless a test run pins
/// one with `OVERLABING_TEST_LANGUAGE` (`PinnedLanguage.kitVariable`), as every Overlabing kit does.
func localized(_ keyAndValue: String.LocalizationValue) -> String {
    guard let pinnedLanguage else { return String(localized: keyAndValue, table: table, bundle: .module) }
    // A resource's locale picks the language for the lookup, which `String(localized:table:bundle:locale:)` does not.
    return String(
        localized: LocalizedStringResource(
            keyAndValue, table: table, locale: pinnedLanguage, bundle: .atURL(Bundle.module.bundleURL)))
}

private let table = "AppShellKit"

let pinnedLanguage = PinnedLanguage.read(PinnedLanguage.kitVariable)
