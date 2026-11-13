# Plugging an app into the shells

Each shell draws the frame, the behaviour and the kit's own words. Everything about the app's domain stays in the app:
its panes' content, its Space type, its storage, its words for what a Space holds. The kit never stores anything except
the open Settings pane, under a key the app names.

## Settings window

1. Name the panes with a `String` enum conforming to `SettingsPaneIdentifier`. The raw value is stored: do not rename
   it between releases.
2. Make one `SettingsShellModel` for the app's life (in the app model), with the panes in sidebar order, the app's
   storage key and its `KeyValueStore` (`UserDefaults.standard` by default, `InMemoryKeyValueStore` in tests and
   demos). Titles and subtitles are the app's localized strings.
3. In the `Settings` scene, `SettingsShell(model) { pane in … }` draws each pane's content under its header. A pane
   that is a grouped `Form` takes `settingsPaneLayout()` so its sections line up with the header.
4. A menu item that opens a pane calls `model.open(pane:)`, then the `openSettings` environment action.
5. A pane's tile is white on its `tint` (a fixed system colour per pane), or the Theme's tint on the kit's tile fill
   when `tint` is nil (a pane about the current Space, say). Set the Theme with ThemeKit's `.theme(_:)` on the shell.

The window is 820 × 600 pt with a 240 pt sidebar by default; adjust a copy of `SettingsShellMetrics.standard`.

## Space editor

1. Map the app's Space to a `SpaceDraft`: its name, its icon as AppSupportKit's `SpaceGlyph` (stored as text with
   `encoded`, read back with `SpaceGlyph(encoded:)`), and the id of its ThemeKit Theme.
2. Make a `SpaceEditorModel` per sheet: `.create` or `.edit`, the names of the app's other Spaces (without the one
   edited), the `Palette` the app offers, and `canDelete` (false for a Space the app keeps, the last one say).
3. Present `SpaceEditor(model:onFinish:sections:)` in a sheet. `sections` holds the app's own `Section`s (which tabs or
   accounts the Space holds, notifications); their state is the app's. To preview the Theme in the window while the user
   picks, observe `model.draft.themeID`.
4. `onFinish` gets `.saved(draft)` (validated, name trimmed: store it), `.cancelled`, or `.deleteRequested` (show the
   deletion confirmation, below). The sheet closes itself.

## Space list

1. Map the app's Spaces to `SpaceListItem`s, in the app's order, with the app's `detail` ("3 tabs") and `note`
   ("Opens at launch") if any.
2. `SpaceList(items, selection:, palette:, deletion:, perform:)`. `deletion` returns the `SpaceDeletion` for a Space,
   or nil to refuse it ("−" and "Delete Space…" disabled). `SpaceDeletion(deleting:in:defaultSpace:contentCount:)`
   builds it with the default Space proposed first, and refuses the last Space. Pass `message` to say in the app's
   words what happens to the content.
3. `perform` receives `.create` and `.edit(id)` (present the editor), `.reorder(ids)` (store the new order) and
   `.delete(id, movingContentTo:)` (move the content, then delete; the app may still refuse).
4. Outside the list (the editor's "Delete Space…", a menu), attach `spaceDeletionConfirmation(_:palette:onDelete:)` to a
   view and set its binding to a `SpaceDeletion`.

## Strings

The kit's strings live in `AppShellKit.xcstrings` (English keys, French), looked up in the kit's bundle. The app's
strings (pane titles, Space details, its sections) live in the app's catalogs. Tests that assert the kit's words pin a
language with `OVERLABING_TEST_LANGUAGE=fr|en`.
