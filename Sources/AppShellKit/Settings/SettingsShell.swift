import ColorUI
import DesignKit
import SwiftUI

/// A Settings window laid out like System Settings: the app's panes in a sidebar, each a row with its tile, and the open
/// pane on the right under its title and subtitle. The window's title follows the pane, and the window reopens on the
/// last pane (`SettingsShellModel`). The window is drawn in ThemeKit's tokens and colours: the Theme's gradient under
/// everything (`WindowBackground`), rows with the kit's hover and selection fills.
///
/// Keyboard: ↑ and ↓ in the sidebar move between panes (⌘[ and ⌘] from anywhere in the window), Tab moves into the
/// pane. VoiceOver reads each row as a button with its title, "selected" on the open one, and the pane's title as a
/// header.
///
/// ```swift
/// Settings {
///     SettingsShell(model.settings) { pane in
///         switch pane {
///         case .general: GeneralPane()
///         case .shortcuts: ShortcutsPane()
///         }
///     }
///     .theme(model.theme)
/// }
/// ```
public struct SettingsShell<ID: SettingsPaneIdentifier, Detail: View>: View {
    private let model: SettingsShellModel<ID>
    private let metrics: SettingsShellMetrics
    private let detail: (ID) -> Detail
    @State private var hover = ListHover()

    /// `detail` draws a pane's content under its header; a grouped `Form` with `settingsPaneLayout()` lines up with it.
    public init(
        _ model: SettingsShellModel<ID>, metrics: SettingsShellMetrics = .standard,
        @ViewBuilder detail: @escaping (ID) -> Detail
    ) {
        self.model = model
        self.metrics = metrics
        self.detail = detail
    }

    public var body: some View {
        NavigationSplitView {
            List(selection: selection) {
                ForEach(model.panes) { pane in
                    let state = RowState(isSelected: pane.id == model.selection)
                    ListRowContent(pane.title, state: state) { SettingsPaneTile(pane: pane, metrics: metrics) }
                        .listRowCell(state: state, hoverID: pane.id)
                        .tag(pane.id)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .listSelectionPlatterOff()
            .listHover(hover)
            .onChange(of: model.selection) { hover.move(to: nil) }
            .accessibilityLabel(localized("Settings"))
            // As in System Settings, the sidebar of panes stays.
            .toolbar(removing: .sidebarToggle)
            .navigationSplitViewColumnWidth(metrics.sidebarWidth)
        } detail: {
            VStack(alignment: .leading, spacing: metrics.headerToContent) {
                SettingsPaneHeader(pane: model.current, metrics: metrics)
                detail(model.selection)
            }
            .frame(maxWidth: metrics.contentWidth)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .navigationTitle(model.current.title)
        }
        .background { WindowBackground().ignoresSafeArea(.all) }
        .background { PaneStepShortcuts(model: model) }
        #if os(macOS)
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .frame(width: metrics.windowWidth, height: metrics.windowHeight)
        #endif
    }

    /// The sidebar never leaves the window without a pane: deselecting keeps the open one.
    private var selection: Binding<ID?> {
        Binding(get: { model.selection }, set: { if let id = $0 { model.open(pane: id) } })
    }
}

/// ⌘[ and ⌘] step through the panes, wherever the focus is in the window. Hidden buttons: nothing is drawn.
private struct PaneStepShortcuts<ID: SettingsPaneIdentifier>: View {
    let model: SettingsShellModel<ID>

    var body: some View {
        Group {
            Button(localized("Previous Pane")) { model.open(step: -1) }
                .keyboardShortcut("[", modifiers: .command)
            Button(localized("Next Pane")) { model.open(step: 1) }
                .keyboardShortcut("]", modifiers: .command)
        }
        .opacity(0)
        .accessibilityHidden(true)
    }
}

/// A pane's tile: its symbol in white on its colour's gradient, as in System Settings, or in the Theme's tint on the
/// kit's tile fill. The coloured tile is a gradient background rather than ThemeKit's `Tile(.symbol(_:_:))`: in the
/// sidebar column AppKit draws a solid system colour fill vibrant, which washes it out to white.
private struct SettingsPaneTile<ID: SettingsPaneIdentifier>: View {
    let pane: SettingsPane<ID>
    let metrics: SettingsShellMetrics
    @Environment(\.designTokens) private var tokens

    var body: some View {
        if let tint = pane.tint {
            Image(systemName: pane.systemImage)
                .font(.system(size: metrics.tileSymbol, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: tokens.size.tile, height: tokens.size.tile)
                .background(tint.gradient, in: RoundedRectangle(cornerRadius: tokens.radius.tile, style: .continuous))
                .accessibilityHidden(true)
        } else {
            Tile(.tintedSymbol(pane.systemImage))
        }
    }
}

/// A pane's header: the title, a header for VoiceOver, and the subtitle on one line in the secondary style.
private struct SettingsPaneHeader<ID: SettingsPaneIdentifier>: View {
    let pane: SettingsPane<ID>
    let metrics: SettingsShellMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: metrics.headerLines) {
            Text(pane.title)
                .font(.title2.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
            if let subtitle = pane.subtitle {
                Text(subtitle)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding([.horizontal, .top], metrics.paneMargin)
    }
}

extension View {
    /// The layout of a pane that is a grouped `Form`: it fills the detail and scrolls when needed, on the window's
    /// gradient (no scroll background; the sections keep the system's), its sections on the header's margin.
    public func settingsPaneLayout(_ metrics: SettingsShellMetrics = .standard) -> some View {
        formStyle(.grouped)
            .scrollContentBackground(.hidden)
            #if os(macOS)
            .contentMargins(.horizontal, metrics.paneMargin - metrics.groupedFormInset, for: .scrollContent)
            #endif
            .contentMargins(.bottom, metrics.paneMargin, for: .scrollContent)
    }
}
