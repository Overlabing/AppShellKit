# Changelog

## 0.1.0

The first release: the Settings window and the Space editor, extracted from the first adopting app and generalized.

### Added

- **`SettingsShell`**: a Settings window laid out like System Settings. The app gives its panes (`SettingsPane`: an
  id, a title, an optional subtitle, an SF Symbol, an optional tile colour) and draws each pane's content; the shell
  draws the sidebar of rows with ThemeKit's row, hover and selection fills, the pane's header, the window's title and
  the Theme's gradient. `SettingsShellModel` holds the open pane, stores it under the app's key in a `KeyValueStore`
  (`UserDefaults` by default) and reopens it; a stored pane the app no longer has opens the first. `open(pane:)` opens
  a pane from a menu item; `open(step:)` and ⌘[ / ⌘] step through them. ↑ and ↓ move in the sidebar; VoiceOver reads
  each row as a button, the open one selected, and the pane's title as a header. `settingsPaneLayout()` lines a grouped
  `Form` up with the header. Dimensions in `SettingsShellMetrics`.
- **`SpaceEditor`**: the sheet that creates or edits a Space, on a `SpaceEditorModel`. Name, colour from a ThemeKit
  `Palette` (swatches, read by name, the chosen one marked by a ring), icon from one picker (the initial of the name, an
  emoji typed or pasted, or a symbol of AppSupportKit's `SpaceIconCatalog`), and a preview with ThemeKit's
  `ThemeGlyph`. The app adds its own sections. An empty name keeps Create disabled; a name another Space has, case
  ignored, says so under the field (AppSupportKit's `SpaceRules`). The app gets a `SpaceEditorResult`: `.saved` with the
  validated `SpaceDraft` (name trimmed), `.cancelled`, or `.deleteRequested`. Nothing is stored by the kit.
- **`SpaceList`**: the management list for a Settings pane. Drag to reorder, "+" and "−", "Edit…", a context menu,
  double-click or Return to edit, Delete to delete. It reports `SpaceListAction`s (`create`, `edit`, `reorder` with the
  whole new order, `delete` with where the content goes) and the app performs them.
- **`SpaceDeletion`** and `spaceDeletionConfirmation(_:palette:onDelete:)`: the confirmation before a Space is deleted,
  with AppSupportKit's `SpaceDeletionChoices` (one button for an empty Space, a button per destination up to two, else
  the proposed one and "Choose…"). The app vetoes a deletion by building no `SpaceDeletion`; the last Space is never
  offered.
- **`EmojiInput.lastEmoji(in:)`**: the last emoji of a text, for the editor's field.
- Strings in English and French (`AppShellKit.xcstrings`).
- `Gallery/`: renders the Settings window and the editor offscreen, light and dark.
