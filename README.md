# AppShellKit

The shells Apple-platform apps share around their own content: a Settings window laid out like System Settings, and
the sheet and list that create, edit, reorder and delete Spaces. The app brings its panes, its Space type and its
storage; the kit brings the layout, the behaviour, the keyboard and VoiceOver operation, and the strings in English and
French.

The code is extracted from an existing app's shells and generalized: nothing in it knows what the app is about.

- macOS 26 and iOS 26, Swift 6 language mode. Built for the Mac first; it also builds for iOS.
- Depends on [ThemeKit](https://github.com/Overlabing/ThemeKit) (tokens, colours, rows, glyphs) and
  [AppSupportKit](https://github.com/Overlabing/AppSupportKit) (the Space icon and rules, the preference store), by patch
  range.
- MIT licensed.

## Install

```swift
.package(url: "https://github.com/Overlabing/AppShellKit", exact: "0.1.0")
```

## Use

```swift
import AppShellKit

enum Pane: String, SettingsPaneIdentifier { case general, shortcuts }

let settings = SettingsShellModel(
    panes: [
        SettingsPane(.general, title: "General", systemImage: "gearshape", tint: .gray),
        SettingsPane(.shortcuts, title: "Shortcuts", systemImage: "keyboard", tint: .pink),
    ],
    storageKey: "myapp.settings.pane")

Settings {
    SettingsShell(settings) { pane in
        switch pane {
        case .general: GeneralPane()
        case .shortcuts: ShortcutsPane()
        }
    }
}
```

A menu item opens its pane: `settings.open(pane: .shortcuts); openSettings()`.

The Space editor takes a `SpaceDraft` and gives one back:

```swift
let model = SpaceEditorModel(SpaceDraft(name: space.name, icon: space.icon, themeID: space.themeID),
                             purpose: .edit, otherNames: otherSpaceNames, canDelete: spaces.count > 1)
SpaceEditor(model: model) { result in
    if case .saved(let draft) = result { store.update(space.id, with: draft) }
}
```

How each shell plugs in the app's content: [docs/shells.md](docs/shells.md). Changes per release:
[CHANGELOG.md](CHANGELOG.md).

## Gallery

`swift run --package-path Gallery AppShellKitGallery <output directory>` renders the Settings window and the Space
editor, light and dark, as PNG files. It draws in a borderless window placed far off every screen, never activated: a
`List` or a `Form` draws only in a window. Nothing appears on screen. Each render is checked: the sidebar's titles and
the editor's buttons must show light on dark and dark on light, on an opaque background, or the run fails.

## Tests

`./check.sh` on macOS runs the gate CI runs: the build, the tests with French then English pinned
(`OVERLABING_TEST_LANGUAGE`), the build for the iOS simulator, and the leak scan. The tests drive the public models
(`SettingsShellModel`, `SpaceEditorModel`, `SpaceDeletion`) and the string catalog; none opens a window.

## Contributing

Once per clone, `scripts/tools.sh install-hooks` installs the commit hooks of [AppTooling](https://github.com/Overlabing/AppTooling)
(a leak scan of what you commit, and Claude attribution stripped from commit messages). The `hygiene` workflow checks the
same on every pull request: no private shape in the tree or the history, no Claude attribution and no personal email
address in the commits, the title or the description. `scripts/check-attribution.sh <base> <head>` runs the last check
locally.

## License

MIT, see [LICENSE](LICENSE).
