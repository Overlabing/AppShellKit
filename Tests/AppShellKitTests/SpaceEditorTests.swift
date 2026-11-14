import AppShellKit
import ColorCore
import Foundation
import Spaces
import Testing

/// The language a run pins (`check.sh` runs the suite in French, then in English); nil when none is pinned.
let pinnedLanguage = ProcessInfo.processInfo.environment["OVERLABING_TEST_LANGUAGE"].flatMap { $0.isEmpty ? nil : $0 }

@MainActor
@Suite("Space editor")
struct SpaceEditorTests {
    @Test("an empty name is refused: no save, no message, the button disabled", arguments: ["", "   ", "\n\t "])
    func emptyName(name: String) {
        let model = SpaceEditorModel(SpaceDraft(name: name, themeID: "teal-green"), purpose: .create)
        #expect(model.nameError == .emptyName)
        #expect(model.nameMessage == nil)
        #expect(!model.canSave)
        #expect(model.save() == nil)
    }

    @Test("a valid name is saved trimmed, with the icon and the Theme as drafted")
    func savesTrimmed() {
        let model = SpaceEditorModel(
            SpaceDraft(name: "  Work \n", icon: .symbol("briefcase"), themeID: "orange-pink"), purpose: .create,
            otherNames: ["Personal"])
        #expect(model.nameError == nil)
        #expect(model.canSave)
        #expect(model.save() == SpaceDraft(name: "Work", icon: .symbol("briefcase"), themeID: "orange-pink"))
    }

    @Test("a name another Space has, case ignored, is refused with a message")
    func duplicateName() {
        let model = SpaceEditorModel(SpaceDraft(name: " work", themeID: "teal-green"), purpose: .create, otherNames: ["Work"])
        #expect(model.nameError == .duplicateName("work"))
        #expect(!model.canSave)
        #expect(model.save() == nil)
        switch pinnedLanguage {
        case "fr": #expect(model.nameMessage == "Un espace s'appelle déjà « work ».")
        case "en": #expect(model.nameMessage == "A space named “work” already exists.")
        default: #expect(model.nameMessage != nil)
        }
    }

    @Test("editing keeps the Space's own name: the app leaves it out of the other names")
    func editKeepsOwnName() {
        let model = SpaceEditorModel(SpaceDraft(name: "Work", themeID: "teal-green"), purpose: .edit, otherNames: ["Home"])
        #expect(model.save()?.name == "Work")
        model.draft.name = "home"
        #expect(model.nameError == .duplicateName("home"))
    }

    @Test("the icon picker's kinds round-trip: an emoji survives a symbol and the initial")
    func iconKindRoundTrip() {
        let model = SpaceEditorModel(SpaceDraft(name: "Garden", icon: .emoji("🌿"), themeID: "teal-green"), purpose: .edit)
        #expect(model.iconSelection == .emoji)
        model.iconSelection = .symbol("leaf")
        #expect(model.draft.icon == .symbol("leaf"))
        #expect(model.iconSelection == .symbol("leaf"))
        model.iconSelection = .initial
        #expect(model.draft.icon == .initial)
        #expect(model.iconSelection == .initial)
        model.iconSelection = .emoji
        #expect(model.draft.icon == .emoji("🌿"))
        #expect(model.save()?.icon == .emoji("🌿"))
    }

    @Test("each kind of icon comes back from the text the app stores", arguments: [
        SpaceGlyph.initial, .symbol("house"), .emoji("🌿"), .emoji("👩🏽‍💻"),
    ])
    func iconStoredRoundTrip(icon: SpaceGlyph) {
        let model = SpaceEditorModel(SpaceDraft(name: "A", icon: icon, themeID: "teal-green"), purpose: .edit)
        let saved = model.save()?.icon
        #expect(saved.map { SpaceGlyph(encoded: $0.encoded) } == icon)
        #expect(saved.map { SpaceIconSelection(SpaceGlyph(encoded: $0.encoded)) } == SpaceIconSelection(icon))
    }

    @Test("choosing Emoji without one gives 🙂; a typed emoji replaces it, other text is ignored")
    func emojiEntry() {
        let model = SpaceEditorModel(SpaceDraft(name: "Home", themeID: "teal-green"), purpose: .create)
        model.iconSelection = .emoji
        #expect(model.draft.icon == .emoji("🙂"))
        #expect(!model.enterEmoji("abc"))
        #expect(model.draft.icon == .emoji("🙂"))
        #expect(model.enterEmoji("🙂🏡"))
        #expect(model.draft.icon == .emoji("🏡"))
        #expect(model.emoji == "🏡")
        model.iconSelection = .symbol("house")
        model.iconSelection = .emoji
        #expect(model.draft.icon == .emoji("🏡"))
    }

    @Test("the emoji field keeps the last emoji of what it is given", arguments: [
        ("🌿", "🌿"), ("a🌿b", "🌿"), ("🌿🔥", "🔥"), ("👍🏽", "👍🏽"), ("🇫🇷", "🇫🇷"), ("1️⃣", "1️⃣"), ("☀️", "☀️"),
        ("👩🏽‍💻", "👩🏽‍💻"),
    ])
    func lastEmoji(text: String, expected: String) {
        #expect(EmojiInput.lastEmoji(in: text) == expected)
    }

    @Test("letters, digits and punctuation are not emoji", arguments: ["", "a", "1", "#", "©", "Work", "é"])
    func notEmoji(text: String) {
        #expect(EmojiInput.lastEmoji(in: text) == nil)
    }

    @Test("the draft is drawn in its Theme from the palette, else in the palette's first")
    func theme() {
        let model = SpaceEditorModel(SpaceDraft(name: "A", themeID: "mint-cyan"), purpose: .create)
        #expect(model.theme == Theme(id: "mint-cyan", primary: .mint, secondary: .cyan))
        model.draft.themeID = "gone"
        #expect(model.theme == Theme(id: "indigo-blue", primary: .indigo, secondary: .blue))
        let custom = Palette(themes: [Theme(id: "red-orange", primary: .red, secondary: .orange)])
        let other = SpaceEditorModel(SpaceDraft(name: "A", themeID: "teal-green"), purpose: .create, palette: custom)
        #expect(other.theme.id == "red-orange")
    }

    @Test("the symbol choices are AppSupportKit's catalogue, plus the Space's own symbol")
    func symbolChoices() {
        let standard = SpaceEditorModel(SpaceDraft(name: "A", themeID: "teal-green"), purpose: .create)
        #expect(standard.symbolChoices.map(\.symbol) == SpaceIconCatalog.choices.map(\.symbol))
        #expect(standard.symbolChoices.first?.symbol == "house")
        let own = SpaceEditorModel(SpaceDraft(name: "A", icon: .symbol("tram"), themeID: "teal-green"), purpose: .edit)
        #expect(own.symbolChoices.last?.symbol == "tram")
        #expect(own.symbolChoices.count == SpaceIconCatalog.choices.count + 1)
    }

    @Test("the sheet's title says whether it creates or edits")
    func title() {
        let create = SpaceEditorModel(SpaceDraft(themeID: "teal-green"), purpose: .create)
        let edit = SpaceEditorModel(SpaceDraft(name: "A", themeID: "teal-green"), purpose: .edit, canDelete: true)
        #expect(!create.canDelete)
        #expect(edit.canDelete)
        switch pinnedLanguage {
        case "fr":
            #expect(create.title == "Nouvel espace")
            #expect(edit.title == "Modifier l'espace")
        case "en":
            #expect(create.title == "New Space")
            #expect(edit.title == "Edit Space")
        default: break
        }
    }
}
