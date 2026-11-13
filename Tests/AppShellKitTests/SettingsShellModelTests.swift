import AppShellKit
import Preferences
import Testing

enum Pane: String, SettingsPaneIdentifier {
    case general, shortcuts, defaults, debug
}

@MainActor
private func makeModel(store: InMemoryKeyValueStore) -> SettingsShellModel<Pane> {
    SettingsShellModel(
        panes: [
            SettingsPane(.general, title: "General", systemImage: "gearshape", tint: .gray),
            SettingsPane(.shortcuts, title: "Shortcuts", subtitle: "Keys for every command.", systemImage: "keyboard"),
            SettingsPane(.defaults, title: "Defaults", systemImage: "star"),
        ],
        storageKey: "test.settings.pane", store: store)
}

@MainActor
@Suite("Settings shell")
struct SettingsShellModelTests {
    @Test("a first opening shows the first pane and stores nothing")
    func firstOpening() {
        let store = InMemoryKeyValueStore()
        let model = makeModel(store: store)
        #expect(model.selection == .general)
        #expect(model.current.title == "General")
        #expect(store.string(forKey: "test.settings.pane") == nil)
    }

    @Test("the window reopens on the pane stored under the app's key")
    func reopensStoredPane() {
        let store = InMemoryKeyValueStore()
        store.setString("shortcuts", forKey: "test.settings.pane")
        let model = makeModel(store: store)
        #expect(model.selection == .shortcuts)
        #expect(model.current.subtitle == "Keys for every command.")
    }

    @Test("a stored pane the window no longer has opens the first", arguments: ["debug", "removed", ""])
    func unknownStoredPane(stored: String) {
        let store = InMemoryKeyValueStore()
        store.setString(stored, forKey: "test.settings.pane")
        #expect(makeModel(store: store).selection == .general)
    }

    @Test("open(pane:) selects the pane and stores its raw value under the app's key only")
    func openPane() {
        let store = InMemoryKeyValueStore()
        let model = makeModel(store: store)
        #expect(model.open(pane: .defaults))
        #expect(model.selection == .defaults)
        #expect(model.current.title == "Defaults")
        #expect(store.string(forKey: "test.settings.pane") == "defaults")
        #expect(store.string(forKey: "settings.pane") == nil)
        #expect(makeModel(store: store).selection == .defaults)
    }

    @Test("open(pane:) with a pane the window does not have changes nothing")
    func openMissingPane() {
        let store = InMemoryKeyValueStore()
        let model = makeModel(store: store)
        model.open(pane: .shortcuts)
        #expect(!model.open(pane: .debug))
        #expect(model.selection == .shortcuts)
        #expect(store.string(forKey: "test.settings.pane") == "shortcuts")
    }

    @Test("stepping moves through the panes in sidebar order and stops at both ends")
    func step() {
        let store = InMemoryKeyValueStore()
        let model = makeModel(store: store)
        #expect(!model.open(step: -1))
        #expect(model.selection == .general)
        #expect(model.open(step: 1))
        #expect(model.selection == .shortcuts)
        #expect(model.open(step: 1))
        #expect(model.selection == .defaults)
        #expect(!model.open(step: 1))
        #expect(model.selection == .defaults)
        #expect(store.string(forKey: "test.settings.pane") == "defaults")
    }

    @Test("the panes keep the app's order, titles, symbols and tints")
    func panes() {
        let model = makeModel(store: InMemoryKeyValueStore())
        #expect(model.panes.map(\.id) == [.general, .shortcuts, .defaults])
        #expect(model.panes.map(\.systemImage) == ["gearshape", "keyboard", "star"])
        #expect(model.pane(.general)?.tint == .gray)
        #expect(model.pane(.shortcuts)?.tint == nil)
        #expect(model.pane(.debug) == nil)
    }
}
