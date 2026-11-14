import AppKit
import AppShellKit
import ColorCore
import ColorUI
import DesignKit
import Preferences
import Spaces
import SwiftUI

// Renders the shells light and dark, in a borderless window far off every screen (`renderHosted`), never activated:
// `AppShellKitGallery <output directory>`. The images are not committed: run it to look at a change. Each render is
// checked (`InkCheck`): the sidebar's titles and the editor's buttons must show in the appearance's ink on an opaque
// background, else the run fails.

enum SamplePane: String, SettingsPaneIdentifier {
    case general, tabs, spaces, shortcuts, privacy, debug
}

let palette = Palette.standard
let spaces = [
    SpaceListItem(id: 1, name: "Home", icon: .emoji("🏡"), themeID: "teal-green", detail: "12 tabs", note: "Opens at launch"),
    SpaceListItem(id: 2, name: "Work", icon: .symbol("briefcase"), themeID: "orange-pink", detail: "8 tabs"),
    SpaceListItem(id: 3, name: "Study", themeID: "purple-pink", detail: "No tabs"),
]

@MainActor
func settingsModel() -> SettingsShellModel<SamplePane> {
    let store = InMemoryKeyValueStore()
    store.setString(SamplePane.spaces.rawValue, forKey: "gallery.settings.pane")
    return SettingsShellModel(
        panes: [
            SettingsPane(.general, title: "General", subtitle: "What opens at launch, and the default browser.",
                         systemImage: "gearshape", tint: .gray),
            SettingsPane(.tabs, title: "Tabs", subtitle: "How tabs open, close and sleep.", systemImage: "square.on.square",
                         tint: .blue),
            SettingsPane(.spaces, title: "Spaces", subtitle: "The name, colour and order of your Spaces.",
                         systemImage: "square.stack"),
            SettingsPane(.shortcuts, title: "Shortcuts", subtitle: "Keys for every command.", systemImage: "keyboard",
                         tint: .pink),
            SettingsPane(.privacy, title: "Privacy", subtitle: "What sites may use.", systemImage: "hand.raised.fill",
                         tint: .indigo),
            SettingsPane(.debug, title: "Debug", subtitle: "The log to attach to a report.", systemImage: "ladybug",
                         tint: .teal),
        ],
        storageKey: "gallery.settings.pane", store: store)
}

struct SampleSettings: View {
    let model: SettingsShellModel<SamplePane>
    @State private var selection: Int? = 2

    var body: some View {
        SettingsShell(model) { pane in
            switch pane {
            case .spaces:
                Form {
                    Section {
                        SpaceList(spaces, selection: $selection, palette: palette) { id in
                            SpaceDeletion(deleting: id, in: spaces, defaultSpace: 1, contentCount: 8)
                        } perform: { _ in }
                        .frame(height: 240)
                    } footer: {
                        Text("The order of the Spaces is the rail's, and ⌃1 to ⌃9. Drag to change it.")
                    }
                }
                .settingsPaneLayout()
            default:
                Form {
                    Section {
                        Toggle("Reopen the last windows", isOn: .constant(true))
                        Toggle("Ask before quitting", isOn: .constant(false))
                    }
                }
                .settingsPaneLayout()
            }
        }
    }
}

/// A region of a render that must hold text in the appearance's ink: light pixels in dark, dark pixels in light, on an
/// opaque background. In points, from the top left corner.
struct InkCheck {
    let label: String
    let rect: CGRect
}

struct Shot {
    let name: String
    let size: CGSize
    var checks: [InkCheck] = []
    let view: @MainActor () -> AnyView
}

/// The sidebar's row titles (right of the tiles) and the editor's button bar.
let sidebarTitles = InkCheck(label: "sidebar row titles", rect: CGRect(x: 54, y: 0, width: 170, height: 288))
func editorButtons(_ size: CGSize) -> InkCheck {
    InkCheck(label: "editor buttons", rect: CGRect(x: 0, y: size.height - 52, width: size.width, height: 52))
}

@MainActor
func shots() -> [Shot] {
    [
        Shot(name: "settings-spaces", size: CGSize(width: 820, height: 600), checks: [sidebarTitles]) {
            AnyView(SampleSettings(model: settingsModel()))
        },
        Shot(name: "settings-general", size: CGSize(width: 820, height: 600), checks: [sidebarTitles]) {
            let model = settingsModel()
            model.open(pane: .general)
            return AnyView(SampleSettings(model: model))
        },
        Shot(name: "space-editor-new", size: CGSize(width: 400, height: 520),
             checks: [editorButtons(CGSize(width: 400, height: 520))]) {
            let model = SpaceEditorModel(SpaceDraft(themeID: "teal-green"), purpose: .create, otherNames: ["Home"])
            return AnyView(SpaceEditor(model: model) { _ in })
        },
        Shot(name: "space-editor-edit-emoji", size: CGSize(width: 400, height: 520),
             checks: [editorButtons(CGSize(width: 400, height: 520))]) {
            let model = SpaceEditorModel(
                SpaceDraft(name: "Home", icon: .emoji("🏡"), themeID: "teal-green"), purpose: .edit,
                otherNames: ["Work", "Study"], canDelete: true)
            return AnyView(SpaceEditor(model: model) { _ in })
        },
        Shot(name: "space-editor-duplicate", size: CGSize(width: 400, height: 580),
             checks: [editorButtons(CGSize(width: 400, height: 580))]) {
            let model = SpaceEditorModel(
                SpaceDraft(name: "work", icon: .symbol("briefcase"), themeID: "orange-pink"), purpose: .create,
                otherNames: ["Home", "Work"])
            return AnyView(
                SpaceEditor(model: model) { _ in } sections: {
                    Section("Tabs") { Toggle("Keep pinned tabs when switching", isOn: .constant(true)) }
                })
        },
    ]
}

/// Draws `view` in a borderless window placed far off every screen (x −20000): a `List` or a `Form` is backed by an
/// AppKit table that `ImageRenderer` cannot draw, and draws only in a window that is ordered in. The window is ordered
/// in without the app ever activating or becoming key (the process runs with the `.prohibited` activation policy), so
/// nothing appears on screen; it is closed after each image.
@MainActor
func renderHosted(_ view: some View, size: CGSize, isDark: Bool, to url: URL) throws -> NSBitmapImageRep {
    // The window's background under the view, as a real window or sheet draws it: the capture draws the view alone.
    let hosting = NSHostingView(
        rootView: view.theme(palette.themes[2]).designTokens(.standard).environment(\.glassRendering, .material)
            .frame(width: size.width, height: size.height)
            .background(Color(nsColor: .windowBackgroundColor)))
    hosting.frame = CGRect(origin: .zero, size: size)
    let window = NSWindow(
        contentRect: CGRect(origin: CGPoint(x: -20000, y: -20000), size: size), styleMask: [.borderless],
        backing: .buffered, defer: false)
    window.isReleasedWhenClosed = false
    window.appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)
    window.contentView = hosting
    window.setFrameOrigin(CGPoint(x: -20000, y: -20000))
    window.orderFrontRegardless()
    defer {
        window.orderOut(nil)
        window.close()
    }
    func draw() throws -> NSBitmapImageRep {
        hosting.layoutSubtreeIfNeeded()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.6))
        hosting.layoutSubtreeIfNeeded()
        guard let rep = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds) else {
            throw CocoaError(.fileWriteUnknown, userInfo: [NSFilePathErrorKey: url.path])
        }
        hosting.cacheDisplay(in: hosting.bounds, to: rep)
        return rep
    }
    _ = try draw()
    let rep = try draw()
    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw CocoaError(.fileWriteUnknown, userInfo: [NSFilePathErrorKey: url.path])
    }
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try data.write(to: url)
    window.contentView = nil
    return rep
}

/// Problems found in `check`'s region of `rep`: a pixel that is not opaque, or no pixel in the appearance's ink.
func problems(_ check: InkCheck, in rep: NSBitmapImageRep, size: CGSize, isDark: Bool) -> [String] {
    let scale = CGFloat(rep.pixelsWide) / size.width
    var transparent = 0
    var ink = 0
    var y = Int(check.rect.minY * scale)
    while y < min(Int(check.rect.maxY * scale), rep.pixelsHigh) {
        var x = Int(check.rect.minX * scale)
        while x < min(Int(check.rect.maxX * scale), rep.pixelsWide) {
            if let color = rep.colorAt(x: x, y: y)?.usingColorSpace(.sRGB) {
                if color.alphaComponent < 0.99 { transparent += 1 }
                let luminance = 0.2126 * color.redComponent + 0.7152 * color.greenComponent + 0.0722 * color.blueComponent
                if isDark ? luminance > 0.7 : luminance < 0.3 { ink += 1 }
            }
            x += 2
        }
        y += 2
    }
    var found: [String] = []
    if transparent > 0 { found.append("\(check.label): \(transparent) transparent pixels") }
    if ink == 0 { found.append("\(check.label): no \(isDark ? "light" : "dark") text") }
    return found
}

let arguments = CommandLine.arguments.dropFirst()
guard let output = arguments.first else {
    FileHandle.standardError.write(Data("usage: AppShellKitGallery <output directory>\n".utf8))
    exit(2)
}
let directory = URL(fileURLWithPath: output, isDirectory: true)
// No Dock icon, no menu bar, never the active app: nothing of the run reaches the screen.
NSApplication.shared.setActivationPolicy(.prohibited)
MainActor.assumeIsolated {
    for shot in shots() {
        for isDark in [false, true] {
            let url = directory.appending(path: "\(shot.name)-\(isDark ? "dark" : "light").png")
            do {
                let rep = try renderHosted(shot.view(), size: shot.size, isDark: isDark, to: url)
                let found = shot.checks.flatMap { problems($0, in: rep, size: shot.size, isDark: isDark) }
                guard found.isEmpty else {
                    print("FAILED: \(url.lastPathComponent): \(found.joined(separator: "; "))")
                    exit(1)
                }
                print("OK: \(url.lastPathComponent)\(shot.checks.isEmpty ? "" : ", " + shot.checks.map(\.label).joined(separator: " and ") + " readable")")
            } catch {
                print("FAILED: \(url.lastPathComponent): \(error)")
                exit(1)
            }
        }
    }
}
