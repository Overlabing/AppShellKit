import ColorCore
import Foundation
import Observation
import Spaces

/// What the Space editor sends back: the draft to save (validated, name trimmed), a cancel, or a request to delete the
/// Space (the app confirms it, `spaceDeletionConfirmation`).
public enum SpaceEditorResult: Sendable, Hashable {
    case saved(SpaceDraft)
    case cancelled
    case deleteRequested
}

/// The state of a Space editor: the draft being edited and the rules it is checked against. Nothing is written until
/// the app receives `.saved`; the app may observe `draft` meanwhile (to preview the Theme in the window, say).
@MainActor
@Observable
public final class SpaceEditorModel {
    public enum Purpose: Sendable, Hashable {
        case create, edit
    }

    public let purpose: Purpose
    public var draft: SpaceDraft
    public let palette: Palette
    /// The names of the app's other Spaces, without the one edited.
    public let otherNames: [String]
    /// Shows "Delete Space…" when editing. The app sets it false for a Space it will not delete (the last one, say).
    public let canDelete: Bool
    /// The symbols the icon picker offers: AppSupportKit's catalogue, plus the Space's own symbol when it is not in it.
    public let symbolChoices: [SpaceIconChoice]
    /// The emoji the picker's "Emoji" choice stands for: the Space's own, the last one typed, else 🙂. Switching to
    /// another kind of icon and back keeps it.
    public private(set) var emoji: String

    public static let defaultEmoji = "🙂"

    public init(
        _ draft: SpaceDraft, purpose: Purpose, otherNames: [String] = [], palette: Palette = .standard,
        canDelete: Bool = false
    ) {
        self.purpose = purpose
        self.draft = draft
        self.palette = palette
        self.otherNames = otherNames
        self.canDelete = canDelete
        symbolChoices = SpaceIconCatalog.choices(including: draft.icon)
        emoji = draft.icon.emoji ?? Self.defaultEmoji
    }

    /// The sheet's title.
    public var title: String {
        switch purpose {
        case .create: localized("New Space")
        case .edit: localized("Edit Space")
        }
    }

    /// Why the name cannot be saved: empty, or another Space's. Nil when it can.
    public var nameError: SpaceRuleError? {
        do {
            _ = try draft.validated(otherNames: otherNames)
            return nil
        } catch {
            return error
        }
    }

    /// The message shown under the name: only for a name another Space has. An empty name only disables the button.
    public var nameMessage: String? {
        guard case .duplicateName = nameError else { return nil }
        return nameError?.errorDescription
    }

    public var canSave: Bool { nameError == nil }

    /// The Theme the draft is drawn in: its own, else the palette's first.
    public var theme: Theme { palette.theme(id: draft.themeID) ?? palette.themes[0] }

    /// The icon picker's value. Choosing `.emoji` gives the draft `emoji`.
    public var iconSelection: SpaceIconSelection {
        get { SpaceIconSelection(draft.icon) }
        set {
            switch newValue {
            case .initial: draft.icon = .initial
            case .symbol(let name): draft.icon = .symbol(name)
            case .emoji: draft.icon = .emoji(emoji)
            }
        }
    }

    /// Takes the text of the emoji field: its last emoji becomes the icon. Text without an emoji changes nothing and
    /// returns false.
    @discardableResult
    public func enterEmoji(_ text: String) -> Bool {
        guard let typed = EmojiInput.lastEmoji(in: text) else { return false }
        emoji = typed
        draft.icon = .emoji(typed)
        return true
    }

    /// The draft to save, validated and trimmed; nil when the name is refused.
    public func save() -> SpaceDraft? {
        try? draft.validated(otherNames: otherNames)
    }
}
