import ColorCore
import DesignKit
import Spaces
import SwiftUI

/// A Space as the management list shows it. `detail` (what it holds: "3 tabs") and `note` ("Opens at launch") are the
/// app's words.
public struct SpaceListItem<ID: Hashable & Sendable>: Identifiable, Sendable, Hashable {
    public var id: ID
    public var name: String
    public var icon: SpaceGlyph
    public var themeID: String
    public var detail: String?
    public var note: String?

    public init(
        id: ID, name: String, icon: SpaceGlyph = .initial, themeID: String, detail: String? = nil, note: String? = nil
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.themeID = themeID
        self.detail = detail
        self.note = note
    }
}

/// What the user asked the list for. The app performs it: it opens the editor (`SpaceEditor`) to create a Space or to
/// edit (rename, recolour) one, stores a new order, deletes a Space.
public enum SpaceListAction<ID: Hashable & Sendable>: Sendable, Hashable {
    case create
    case edit(ID)
    /// Every Space in its new order, after a drag.
    case reorder([ID])
    /// Confirmed by the user: delete the Space, moving what it holds to the second one (nil for an empty Space).
    case delete(ID, movingContentTo: ID?)
}

/// The management list of Spaces, for a Settings pane: drag to reorder, "+" and "−" under the list, double-click,
/// Return or "Edit…" to edit, a context menu, and Delete to delete with a confirmation. The order is the app's (its
/// rail, its ⌃1…⌃9). `deletion` builds the confirmation for a Space, or returns nil to refuse it: "−" and "Delete
/// Space…" are then disabled for that Space.
public struct SpaceList<ID: Hashable & Sendable>: View {
    private let spaces: [SpaceListItem<ID>]
    @Binding private var selection: ID?
    private let palette: Palette
    private let deletion: (ID) -> SpaceDeletion<ID>?
    private let perform: (SpaceListAction<ID>) -> Void
    @State private var pendingDeletion: SpaceDeletion<ID>?
    @Environment(\.designTokens) private var tokens

    public init(
        _ spaces: [SpaceListItem<ID>], selection: Binding<ID?>, palette: Palette = .standard,
        deletion: @escaping (ID) -> SpaceDeletion<ID>?, perform: @escaping (SpaceListAction<ID>) -> Void
    ) {
        self.spaces = spaces
        _selection = selection
        self.palette = palette
        self.deletion = deletion
        self.perform = perform
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            List(selection: $selection) {
                ForEach(spaces) { space in
                    SpaceListRow(space: space, palette: palette)
                        .tag(space.id)
                }
                .onMove { offsets, destination in
                    if let order = try? SpaceRules.moved(spaces.map(\.id), fromOffsets: offsets, toOffset: destination) {
                        perform(.reorder(order))
                    }
                }
            }
            #if os(macOS)
            .listStyle(.bordered)
            .onDeleteCommand { if let selection { askToDelete(selection) } }
            #endif
            .contextMenu(forSelectionType: ID.self) { ids in
                if let id = ids.first {
                    Button(localized("Edit…")) { perform(.edit(id)) }
                    Button(localized("Delete Space…"), role: .destructive) { askToDelete(id) }
                        .disabled(deletion(id) == nil)
                }
            } primaryAction: { ids in
                if let id = ids.first { perform(.edit(id)) }
            }
            bar
        }
        .spaceDeletionConfirmation($pendingDeletion, palette: palette) { id, destination in
            perform(.delete(id, movingContentTo: destination))
        }
    }

    private var bar: some View {
        HStack(spacing: 0) {
            IconButton(localized("New Space"), systemImage: "plus") { perform(.create) }
            IconButton(localized("Delete Space…"), systemImage: "minus") {
                if let selection { askToDelete(selection) }
            }
            .disabled(selection.flatMap(deletion) == nil)
            Spacer()
            IconButton(localized("Edit…")) {
                if let selection { perform(.edit(selection)) }
            }
            .disabled(selection == nil)
        }
        .padding(.vertical, DesignTokens.Spacing.xs)
    }

    private func askToDelete(_ id: ID) {
        pendingDeletion = deletion(id)
    }
}

/// A Space's row: its glyph, its name, the app's detail under it and its note at the end, read as one element.
private struct SpaceListRow<ID: Hashable & Sendable>: View {
    let space: SpaceListItem<ID>
    let palette: Palette
    @Environment(\.designTokens) private var tokens

    var body: some View {
        HStack(spacing: tokens.spacing.tileToText) {
            SpaceListGlyph(space: space, palette: palette)
            VStack(alignment: .leading, spacing: tokens.spacing.textLines) {
                Text(space.name)
                if let detail = space.detail {
                    Text(detail).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let note = space.note {
                Text(note).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.xxs)
        .accessibilityElement(children: .combine)
    }
}

/// A Space's circle: ThemeKit's `ThemeGlyph` in its Theme, with its emoji, its symbol or its initial.
struct SpaceListGlyph<ID: Hashable & Sendable>: View {
    let space: SpaceListItem<ID>
    let palette: Palette

    var body: some View {
        ThemeGlyph(
            name: space.name, symbol: space.icon.symbolName, emoji: space.icon.emoji,
            theme: palette.theme(id: space.themeID) ?? palette.themes[0])
    }
}
