import Foundation
import Observation
import Preferences
import SwiftUI

/// An app's Settings pane identifiers, usually a `String` enum. The raw value is what the shell stores to reopen the
/// last pane, so it must not change between releases.
public protocol SettingsPaneIdentifier: RawRepresentable<String>, Hashable, Sendable {}

/// One pane of the Settings window, as the sidebar shows it: a title, an optional one-line subtitle under the title in
/// the detail, and a tile with an SF Symbol. The pane's content is the app's (`SettingsShell`'s `detail`).
public struct SettingsPane<ID: SettingsPaneIdentifier>: Identifiable, Sendable, Hashable {
    public let id: ID
    public var title: String
    public var subtitle: String?
    public var systemImage: String
    /// The tile's colour, as in System Settings: a fixed colour per pane that only helps recognise it, the symbol drawn
    /// in white (black where white stays under 3:1). Nil draws the symbol in the Theme's tint on the kit's tile fill.
    public var tint: Color?

    public init(_ id: ID, title: String, subtitle: String? = nil, systemImage: String, tint: Color? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tint = tint
    }
}

/// What the Settings window shows: the app's panes in sidebar order and the open one. The open pane is stored under the
/// app's key, so the window reopens on it; a stored pane the app no longer has opens the first. `open(pane:)` is what a
/// menu item calls before it opens the window (`openSettings()`), and what the sidebar calls when the user picks a pane.
@MainActor
@Observable
public final class SettingsShellModel<ID: SettingsPaneIdentifier> {
    public let panes: [SettingsPane<ID>]
    /// The open pane. Never none: deselecting in the sidebar keeps it.
    public private(set) var selection: ID
    @ObservationIgnored public let storageKey: String
    @ObservationIgnored private let store: any KeyValueStore

    /// `panes` in sidebar order, at least one, each id once. `storageKey` belongs to the app: the kit names none.
    public init(panes: [SettingsPane<ID>], storageKey: String, store: any KeyValueStore = UserDefaults.standard) {
        precondition(!panes.isEmpty, "A Settings window needs at least one pane")
        precondition(Set(panes.map(\.id)).count == panes.count, "Each Settings pane id appears once")
        self.panes = panes
        self.storageKey = storageKey
        self.store = store
        let stored = store.string(forKey: storageKey).flatMap(ID.init(rawValue:))
        selection = stored.flatMap { id in panes.contains { $0.id == id } ? id : nil } ?? panes[0].id
    }

    /// The open pane's description.
    public var current: SettingsPane<ID> { pane(selection) ?? panes[0] }

    public func pane(_ id: ID) -> SettingsPane<ID>? { panes.first { $0.id == id } }

    /// Opens `pane` and stores it as the pane to reopen. A pane the window does not have changes nothing and returns
    /// false.
    @discardableResult
    public func open(pane id: ID) -> Bool {
        guard pane(id) != nil else { return false }
        selection = id
        store.setString(id.rawValue, forKey: storageKey)
        return true
    }

    /// Opens the pane `step` places away in sidebar order (±1), stopping at both ends.
    @discardableResult
    public func open(step: Int) -> Bool {
        guard let index = panes.firstIndex(where: { $0.id == selection }) else { return false }
        let target = min(max(index + step, 0), panes.count - 1)
        guard target != index else { return false }
        return open(pane: panes[target].id)
    }
}
