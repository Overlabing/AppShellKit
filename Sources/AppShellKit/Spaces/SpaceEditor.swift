import ColorCore
import ColorUI
import DesignKit
import Spaces
import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

/// The sheet that creates or edits a Space: its name, its Theme from the palette, its icon (the initial, an SF Symbol or
/// an emoji, in one picker) and a preview, then the app's own sections (`sections`). Nothing is written before Create
/// or Save (Return); Cancel (Escape) drops the draft. An empty name keeps Create disabled; a name another Space has
/// says so under the field. The sheet closes itself after calling `onFinish`.
///
/// ```swift
/// .sheet(item: $editing) { target in
///     SpaceEditor(model: target.model) { result in
///         if case .saved(let draft) = result { store.save(draft, for: target.id) }
///     } sections: {
///         Section("Tabs") { Toggle("Keep pinned tabs", isOn: $keepPinned) }
///     }
/// }
/// ```
public struct SpaceEditor<Sections: View>: View {
    @Bindable private var model: SpaceEditorModel
    private let metrics: SpaceEditorMetrics
    private let onFinish: (SpaceEditorResult) -> Void
    private let sections: Sections
    @FocusState private var nameFocused: Bool
    @Environment(\.dismiss) private var dismiss

    public init(
        model: SpaceEditorModel, metrics: SpaceEditorMetrics = .standard,
        onFinish: @escaping (SpaceEditorResult) -> Void, @ViewBuilder sections: () -> Sections
    ) {
        self.model = model
        self.metrics = metrics
        self.onFinish = onFinish
        self.sections = sections()
    }

    public var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    TextField(localized("Name"), text: $model.draft.name, prompt: Text(localized("Personal, Work…")))
                        .focused($nameFocused)
                    if let message = model.nameMessage { InlineError(message: message) }
                }
                Section(localized("Appearance")) {
                    SpaceThemePicker(selection: $model.draft.themeID, palette: model.palette, metrics: metrics)
                    SpaceIconPicker(model: model)
                    LabeledContent(localized("Preview")) {
                        ThemeGlyph(
                            name: model.draft.trimmedName, symbol: model.draft.icon.symbolName,
                            emoji: model.draft.icon.emoji, theme: model.theme)
                    }
                }
                sections
            }
            .formStyle(.grouped)
            Divider()
            buttons
        }
        .navigationTitle(model.title)
        #if os(macOS)
        .frame(width: metrics.width)
        .frame(minHeight: metrics.minHeight)
        #endif
        .onAppear { nameFocused = model.purpose == .create }
    }

    private var buttons: some View {
        HStack {
            if model.purpose == .edit && model.canDelete {
                Button(localized("Delete Space…"), role: .destructive) { finish(.deleteRequested) }
            }
            Spacer()
            Button(localized("Cancel"), role: .cancel) { finish(.cancelled) }
                .keyboardShortcut(.cancelAction)
            Button(model.purpose == .create ? localized("Create") : localized("Save")) {
                if let draft = model.save() { finish(.saved(draft)) }
            }
            .keyboardShortcut(.defaultAction)
            .disabled(!model.canSave)
        }
        .padding(metrics.buttonsPadding)
    }

    private func finish(_ result: SpaceEditorResult) {
        onFinish(result)
        dismiss()
    }
}

extension SpaceEditor where Sections == EmptyView {
    /// The editor without sections of the app's.
    public init(
        model: SpaceEditorModel, metrics: SpaceEditorMetrics = .standard,
        onFinish: @escaping (SpaceEditorResult) -> Void
    ) {
        self.init(model: model, metrics: metrics, onFinish: onFinish) { EmptyView() }
    }
}

/// The palette's Themes as round swatches, one button each: the Theme's name is its VoiceOver label and its help, the
/// chosen one is marked by a ring and read as selected, never by colour alone.
struct SpaceThemePicker: View {
    @Binding var selection: String
    let palette: Palette
    let metrics: SpaceEditorMetrics

    var body: some View {
        LabeledContent(localized("Color")) {
            HStack(spacing: metrics.swatchSpacing) {
                ForEach(palette.themes) { theme in
                    let isSelected = theme.id == selection
                    Button {
                        selection = theme.id
                    } label: {
                        ThemeSwatch(theme, isSelected: isSelected, size: metrics.swatchSize)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(theme.displayName))
                    .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
                }
            }
        }
    }
}

/// One picker for the icon: the initial of the name, an emoji, or a symbol of the catalogue. With "Emoji" chosen, a
/// field under it takes the emoji, typed or pasted (on the Mac, "Emoji & Symbols" opens the system's viewer).
struct SpaceIconPicker: View {
    @Bindable var model: SpaceEditorModel
    @FocusState private var emojiFocused: Bool

    var body: some View {
        Picker(localized("Icon"), selection: $model.iconSelection) {
            Label(localized("Initial of the Name"), systemImage: "character").tag(SpaceIconSelection.initial)
            Label(localized("Emoji"), systemImage: "face.smiling").tag(SpaceIconSelection.emoji)
            Divider()
            ForEach(model.symbolChoices) { choice in
                Label(choice.name, systemImage: choice.symbol).tag(SpaceIconSelection.symbol(choice.symbol))
            }
        }
        if model.iconSelection == .emoji {
            HStack {
                TextField(localized("Emoji"), text: emojiText, prompt: Text(localized("Type or paste an emoji")))
                    .focused($emojiFocused)
                #if os(macOS)
                Button(localized("Emoji & Symbols")) {
                    emojiFocused = true
                    NSApp.orderFrontCharacterPalette(nil)
                }
                #endif
            }
        }
    }

    /// The field shows the chosen emoji; what it is given goes through `enterEmoji(_:)`, so only an emoji stays.
    private var emojiText: Binding<String> {
        Binding(get: { model.emoji }, set: { model.enterEmoji($0) })
    }
}

/// An error under the field it is about: a triangle and the text in red, in `.caption`, never the colour alone.
struct InlineError: View {
    let message: String

    var body: some View {
        Label {
            Text(message)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
        }
        .font(.caption)
        .foregroundStyle(.red)
        .fixedSize(horizontal: false, vertical: true)
    }
}
