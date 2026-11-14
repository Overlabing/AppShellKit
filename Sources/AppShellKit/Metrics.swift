import DesignKit
import SwiftUI

/// The Settings window's dimensions, in points. ThemeKit's `DesignTokens` give the rows, tiles and spacing; these are
/// the window's own. An app adjusts a copy of `standard` rather than writing a number in a view.
public struct SettingsShellMetrics: Sendable, Equatable {
    /// The window: sidebar plus content. Panes scroll when they are taller.
    public var windowWidth: CGFloat = 820
    public var windowHeight: CGFloat = 600
    /// The sidebar of panes, fixed.
    public var sidebarWidth: CGFloat = 240
    /// The widest a pane's header and sections grow, centred in the detail.
    public var contentWidth: CGFloat = 580
    /// Around a pane's content: its header and the sections of `settingsPaneLayout()`.
    public var paneMargin: CGFloat = DesignTokens.Spacing.xl
    /// The horizontal margin a grouped `Form` keeps on its own on macOS; `settingsPaneLayout()` takes it off so that
    /// the sections line up with the header at `paneMargin`.
    public var groupedFormInset: CGFloat = 20
    /// Between a pane's header and its content.
    public var headerToContent: CGFloat = DesignTokens.Spacing.l
    /// Between a pane's title and its subtitle.
    public var headerLines: CGFloat = DesignTokens.Spacing.xxs
    /// The symbol in a coloured pane tile (the tile is ThemeKit's `Size.tile`).
    public var tileSymbol: CGFloat = 15

    public init() {}

    public static let standard = SettingsShellMetrics()
}

/// The Space editor's and the Space list's dimensions, in points.
public struct SpaceEditorMetrics: Sendable, Equatable {
    /// The editor sheet's width, and its least height.
    public var width: CGFloat = 400
    public var minHeight: CGFloat = 380
    /// Around the editor's buttons and the list's bar.
    public var buttonsPadding: CGFloat = DesignTokens.Spacing.l
    /// Between two palette swatches.
    public var swatchSpacing: CGFloat = DesignTokens.Spacing.s
    /// A palette swatch's side in the editor.
    public var swatchSize: CGFloat = 22

    public init() {}

    public static let standard = SpaceEditorMetrics()
}
