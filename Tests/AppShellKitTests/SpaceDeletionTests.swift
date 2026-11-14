import AppShellKit
import Spaces
import Testing

private let home = SpaceListItem(id: 1, name: "Home", icon: .emoji("🏡"), themeID: "teal-green", note: "Opens at launch")
private let work = SpaceListItem(id: 2, name: "Work", icon: .symbol("briefcase"), themeID: "orange-pink", detail: "3 tabs")
private let study = SpaceListItem(id: 3, name: "Study", themeID: "purple-pink")
private let games = SpaceListItem(id: 4, name: "Games", themeID: "red-orange")

@Suite("Space deletion")
struct SpaceDeletionTests {
    @Test("the last Space cannot be deleted, nor one the list does not have")
    func refused() {
        #expect(SpaceDeletion(deleting: 1, in: [home], defaultSpace: 1, contentCount: 0) == nil)
        #expect(SpaceDeletion(deleting: 9, in: [home, work], defaultSpace: 1, contentCount: 0) == nil)
    }

    @Test("the default Space is the proposed destination, the others follow in order")
    func destinations() throws {
        let deletion = try #require(SpaceDeletion(deleting: 3, in: [home, work, study, games], defaultSpace: 2, contentCount: 4))
        #expect(deletion.id == 3)
        #expect(deletion.space.name == "Study")
        #expect(deletion.destinations.map(\.id) == [2, 1, 4])
    }

    @Test("an empty Space asks one destructive question")
    func empty() throws {
        let deletion = try #require(SpaceDeletion(deleting: 2, in: [home, work], defaultSpace: 1, contentCount: 0))
        #expect(deletion.choices == .deleteEmpty)
        #expect(deletion.choices.buttonCount == 2)
    }

    @Test("up to two destinations get a button each; beyond, the proposed one and Choose…")
    func choices() throws {
        let two = try #require(SpaceDeletion(deleting: 2, in: [home, work, study], defaultSpace: 1, contentCount: 3))
        #expect(two.choices == .moveTo([1, 3]))
        let three = try #require(SpaceDeletion(deleting: 2, in: [home, work, study, games], defaultSpace: 4, contentCount: 1))
        #expect(three.choices == .proposedOrChoose(proposed: 4, all: [4, 1, 3]))
        #expect(three.choices.buttonCount == 3)
    }

    @Test("the app's message replaces the kit's")
    func appMessage() throws {
        let deletion = try #require(
            SpaceDeletion(deleting: 2, in: [home, work], defaultSpace: 1, contentCount: 3, message: "Its 3 tabs move."))
        #expect(deletion.messageText == "Its 3 tabs move.")
    }

    @Test("the confirmation's words", arguments: [0, 2])
    func words(contentCount: Int) throws {
        let deletion = try #require(SpaceDeletion(deleting: 2, in: [home, work], defaultSpace: 1, contentCount: contentCount))
        switch pinnedLanguage {
        case "fr":
            #expect(deletion.title == "Supprimer l'espace « Work » ?")
            #expect(deletion.moveTitle(to: home) == "Déplacer vers « Home » et supprimer")
            #expect(deletion.messageText == (contentCount == 0
                ? "L'espace est vide. Sa couleur et ses réglages seront perdus."
                : "Rien de ce qu'il contient n'est supprimé : tout rejoint l'espace choisi. Sa couleur et ses réglages seront perdus."))
        case "en":
            #expect(deletion.title == "Delete the Space “Work”?")
            #expect(deletion.moveTitle(to: home) == "Move to “Home” and Delete")
            #expect(deletion.messageText == (contentCount == 0
                ? "The Space is empty. Its color and settings will be lost."
                : "Nothing it holds is deleted: it moves to the Space you choose. Its color and settings will be lost."))
        default:
            #expect(!deletion.title.isEmpty)
        }
    }

    @Test("list actions carry the ids the app acts on")
    func actions() {
        let order: SpaceListAction<Int> = .reorder([2, 1, 3])
        #expect(order == .reorder([2, 1, 3]))
        #expect(SpaceListAction<Int>.delete(2, movingContentTo: nil) != .delete(2, movingContentTo: 1))
        #expect(work.detail == "3 tabs")
        #expect(home.note == "Opens at launch")
    }
}
