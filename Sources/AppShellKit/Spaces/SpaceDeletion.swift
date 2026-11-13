import ColorCore
import Spaces
import SwiftUI

/// A Space the app agrees to delete, and where what it holds can go. The app builds it when the user asks to delete a
/// Space (the list's "−", Delete, its menu, the editor's "Delete Space…"); returning none instead refuses the deletion.
/// The confirmation (`spaceDeletionConfirmation`) offers the buttons of AppSupportKit's `SpaceDeletionChoices`.
public struct SpaceDeletion<ID: Hashable & Sendable>: Sendable, Hashable, Identifiable {
    public var space: SpaceListItem<ID>
    /// Where what the Space holds can move, the proposed one first.
    public var destinations: [SpaceListItem<ID>]
    /// What the Space holds that must move (tabs, accounts): 0 for an empty Space.
    public var contentCount: Int
    /// The confirmation's message in the app's words; nil uses the kit's.
    public var message: String?

    public var id: ID { space.id }

    public init(space: SpaceListItem<ID>, destinations: [SpaceListItem<ID>], contentCount: Int, message: String? = nil) {
        self.space = space
        self.destinations = destinations
        self.contentCount = contentCount
        self.message = message
    }

    /// The deletion of `id` among `spaces`, the default Space proposed first (`SpaceRules.deletionDestinations`). Nil
    /// when `id` is not among them or is the only Space: the last Space is never deleted.
    public init?(
        deleting id: ID, in spaces: [SpaceListItem<ID>], defaultSpace: ID?, contentCount: Int, message: String? = nil
    ) {
        guard spaces.count > 1, let space = spaces.first(where: { $0.id == id }) else { return nil }
        let order = SpaceRules.deletionDestinations(deleting: id, in: spaces.map(\.id), defaultSpace: defaultSpace)
        let destinations = order.compactMap { destination in spaces.first { $0.id == destination } }
        self.init(space: space, destinations: destinations, contentCount: contentCount, message: message)
    }

    /// The confirmation's buttons, Cancel aside.
    public var choices: SpaceDeletionChoices<ID> {
        SpaceDeletionChoices(contentCount: contentCount, destinations: destinations.map(\.id))
    }

    public var title: String { localized("Delete the Space “\(space.name)”?") }

    public var messageText: String {
        if let message { return message }
        return contentCount == 0
            ? localized("The Space is empty. Its color and settings will be lost.")
            : localized("Nothing it holds is deleted: it moves to the Space you choose. Its color and settings will be lost.")
    }

    /// The button that moves what the Space holds to `destination`, then deletes it.
    public func moveTitle(to destination: SpaceListItem<ID>) -> String {
        localized("Move to “\(destination.name)” and Delete")
    }

    func destination(_ id: ID) -> SpaceListItem<ID>? { destinations.first { $0.id == id } }
}

extension View {
    /// Asks to confirm `deletion` while it is set: one destructive button for an empty Space, else one button per
    /// destination (the proposed one on Return), or the proposed one and "Choose…" for the whole list in a sheet.
    /// Cancel on Escape. `onDelete` receives the Space and where its content goes (nil for an empty Space); the app
    /// deletes it, or still refuses.
    public func spaceDeletionConfirmation<ID: Hashable & Sendable>(
        _ deletion: Binding<SpaceDeletion<ID>?>, palette: Palette = .standard,
        onDelete: @escaping (_ space: ID, _ movingContentTo: ID?) -> Void
    ) -> some View {
        modifier(SpaceDeletionConfirmation(deletion: deletion, palette: palette, onDelete: onDelete))
    }
}

private struct SpaceDeletionConfirmation<ID: Hashable & Sendable>: ViewModifier {
    @Binding var deletion: SpaceDeletion<ID>?
    let palette: Palette
    let onDelete: (ID, ID?) -> Void
    @State private var choosing: SpaceDeletion<ID>?

    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                deletion?.title ?? "", isPresented: isPresented, titleVisibility: .visible, presenting: deletion
            ) { deletion in
                switch deletion.choices {
                case .deleteEmpty:
                    Button(localized("Delete"), role: .destructive) { onDelete(deletion.id, nil) }
                case .moveTo(let destinations):
                    ForEach(Array(destinations.enumerated()), id: \.element) { index, id in
                        if let destination = deletion.destination(id) {
                            Button(deletion.moveTitle(to: destination)) { onDelete(deletion.id, id) }
                                .keyboardShortcut(index == 0 ? .defaultAction : nil)
                        }
                    }
                case .proposedOrChoose(let proposed, _):
                    if let destination = deletion.destination(proposed) {
                        Button(deletion.moveTitle(to: destination)) { onDelete(deletion.id, proposed) }
                            .keyboardShortcut(.defaultAction)
                    }
                    Button(localized("Choose…")) { choosing = deletion }
                }
                Button(localized("Cancel"), role: .cancel) {}
            } message: { deletion in
                Text(deletion.messageText)
            }
            .sheet(item: $choosing) { deletion in
                SpaceDestinationChooser(deletion: deletion, palette: palette) { destination in
                    onDelete(deletion.id, destination)
                }
            }
    }

    private var isPresented: Binding<Bool> {
        Binding(get: { deletion != nil }, set: { if !$0 { deletion = nil } })
    }
}

/// "Choose…": every destination in a list, the proposed one chosen; Return moves and deletes, Escape cancels.
private struct SpaceDestinationChooser<ID: Hashable & Sendable>: View {
    let deletion: SpaceDeletion<ID>
    let palette: Palette
    let confirm: (ID) -> Void
    @State private var selection: ID?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    Picker(selection: $selection) {
                        ForEach(deletion.destinations) { destination in
                            Label {
                                Text(destination.name)
                            } icon: {
                                SpaceListGlyph(space: destination, palette: palette)
                            }
                            .tag(Optional(destination.id))
                        }
                    } label: {
                        Text(localized("Move To"))
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text(deletion.title)
                } footer: {
                    Text(deletion.messageText)
                }
            }
            .formStyle(.grouped)
            .fixedSize(horizontal: false, vertical: true)
            HStack {
                Spacer()
                Button(localized("Cancel"), role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(confirmTitle, role: .destructive) {
                    guard let selection else { return }
                    dismiss()
                    confirm(selection)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selection == nil)
            }
            .padding(SpaceEditorMetrics.standard.buttonsPadding)
        }
        #if os(macOS)
        .frame(width: SpaceEditorMetrics.standard.width)
        #endif
        .onAppear { selection = deletion.destinations.first?.id }
    }

    private var confirmTitle: String {
        guard let selection, let destination = deletion.destination(selection) else { return localized("Delete") }
        return deletion.moveTitle(to: destination)
    }
}
