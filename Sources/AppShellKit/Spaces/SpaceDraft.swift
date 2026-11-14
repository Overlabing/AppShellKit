import Foundation
import Spaces

/// A Space as the editor shows and returns it: a name, an icon (the initial of the name, an SF Symbol or an emoji), and
/// the id of a Theme in a ThemeKit `Palette`. The app makes one from its own Space and stores the result its own way;
/// the kit stores nothing.
public struct SpaceDraft: Sendable, Hashable {
    public var name: String
    public var icon: SpaceGlyph
    /// A `Theme.id` of the editor's palette. An id the palette does not have draws as its first Theme.
    public var themeID: String

    public init(name: String = "", icon: SpaceGlyph = .initial, themeID: String) {
        self.name = name
        self.icon = icon
        self.themeID = themeID
    }

    /// The name with spaces and line breaks trimmed at both ends.
    public var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// The draft to save, its name trimmed, when the name is not empty and no other Space has it (case ignored), by
    /// AppSupportKit's `SpaceRules`. `otherNames`: the names of the app's other Spaces, without the one edited.
    public func validated(otherNames: [String]) throws(SpaceRuleError) -> SpaceDraft {
        var draft = self
        draft.name = try SpaceRules.validateName(name, among: otherNames.enumerated().map { (id: $0.offset, name: $0.element) })
        return draft
    }
}

/// The icon picker's choices: one picker for the three kinds of icon. `emoji` stands for whichever emoji the editor
/// holds, typed in the field under the picker.
public enum SpaceIconSelection: Sendable, Hashable {
    case initial
    case symbol(String)
    case emoji

    public init(_ glyph: SpaceGlyph) {
        switch glyph {
        case .initial: self = .initial
        case .symbol(let name): self = .symbol(name)
        case .emoji: self = .emoji
        }
    }
}

/// Emoji typed or pasted into the editor's field.
public enum EmojiInput {
    /// The last emoji in `text` (one character, skin tone, flag or family included), nil when there is none. Letters,
    /// digits and punctuation are not emoji, even those Unicode can draw as one (a bare "1" or "#").
    public static func lastEmoji(in text: String) -> String? {
        text.reversed().first(where: isEmoji).map(String.init)
    }

    static func isEmoji(_ character: Character) -> Bool {
        let scalars = character.unicodeScalars
        guard let first = scalars.first else { return false }
        if first.properties.isEmojiPresentation { return true }
        // A text-default emoji drawn as emoji: followed by the emoji variation selector (☀️, 1️⃣), or joined into a
        // sequence of several scalars that starts with an emoji (🏳️‍🌈).
        return first.properties.isEmoji && scalars.count > 1
            && scalars.contains { $0.value == 0xFE0F || $0.properties.isEmojiModifier || $0.value == 0x200D }
    }
}
