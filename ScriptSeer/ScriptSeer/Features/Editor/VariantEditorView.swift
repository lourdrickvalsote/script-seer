import SwiftUI
import SwiftData

struct VariantEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var variant: ScriptVariant
    @FocusState private var editorFocused: Bool
    @State private var editorSelection: TextSelection?
    @State private var lastKnownCursorPosition: String.Index?
    @State private var showRenameAlert = false
    @State private var renameText = ""

    private var wordCount: Int {
        variant.content.split(omittingEmptySubsequences: true, whereSeparator: { $0.isWhitespace }).count
    }

    private var estimatedDuration: String {
        let seconds = Double(wordCount) / 2.5 // ~150 wpm
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    var body: some View {
        VStack(spacing: 0) {
            statsBar

            ScrollView {
                TextEditor(text: $variant.content, selection: $editorSelection)
                    .font(SSTypography.body)
                    .foregroundStyle(SSColors.textPrimary)
                    .scrollContentBackground(.hidden)
                    .focused($editorFocused)
                    .frame(minHeight: 400)
                    .padding(.horizontal, SSSpacing.md)
                    .padding(.top, SSSpacing.sm)
                    .onChange(of: editorSelection) {
                        if let selection = editorSelection {
                            switch selection.indices {
                            case .selection(let range):
                                lastKnownCursorPosition = range.lowerBound
                            case .multiSelection:
                                break
                            }
                        }
                    }
            }
            .background(SSColors.background)

            formattingToolbar

            bottomBar
        }
        .background(SSColors.background)
        .navigationTitle(variant.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: SSSpacing.sm) {
                    if editorFocused {
                        Button("Done") {
                            editorFocused = false
                            SSHaptics.light()
                        }
                        .font(SSTypography.callout.weight(.semibold))
                        .foregroundStyle(SSColors.accent)
                    }
                    Menu {
                        Button(action: {
                            renameText = variant.title
                            showRenameAlert = true
                        }) {
                            Label("Rename Variant", systemImage: "pencil")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(SSColors.accent)
                    }
                }
            }
        }
        .alert("Rename Variant", isPresented: $showRenameAlert) {
            TextField("Variant title", text: $renameText)
            Button("Save") {
                let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    variant.title = trimmed
                    variant.updatedAt = Date()
                    SSHaptics.success()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear { editorFocused = true }
        .onChange(of: variant.content) {
            variant.updatedAt = Date()
        }
    }

    private var statsBar: some View {
        HStack(spacing: SSSpacing.lg) {
            Label(estimatedDuration, systemImage: "clock")
            Label("\(wordCount) words", systemImage: "text.word.spacing")
            Spacer()
            Text(variant.sourceType.displayName)
                .foregroundStyle(SSColors.accent)
        }
        .font(SSTypography.caption)
        .foregroundStyle(SSColors.textTertiary)
        .padding(.horizontal, SSSpacing.md)
        .padding(.vertical, SSSpacing.xs)
        .background(SSColors.surface)
    }

    private var formattingToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SSSpacing.xs) {
                FormatButton(icon: "person.fill", label: "Speaker") {
                    insertAtCursor("\n[SPEAKER: Name] ")
                    SSHaptics.light()
                }
                FormatButton(icon: "text.line.first.and.arrowtriangle.forward", label: "Section") {
                    insertAtCursor("\n[SECTION: Title]\n")
                    SSHaptics.light()
                }

                Divider()
                    .frame(height: 24)
                    .background(SSColors.divider)

                ForEach(CueCategory.allCases, id: \.self) { category in
                    Menu {
                        ForEach(TeleprompterCueType.allCases.filter { $0.category == category }, id: \.self) { cue in
                            Button {
                                insertAtCursor(" " + cue.rawValue + " ")
                                SSHaptics.light()
                            } label: {
                                Label(cue.displayName, systemImage: cue.systemImage)
                            }
                        }
                    } label: {
                        Text(category.rawValue)
                            .font(SSTypography.caption)
                            .foregroundStyle(SSColors.accent)
                            .padding(.horizontal, SSSpacing.xs)
                            .padding(.vertical, SSSpacing.xxs)
                            .background(SSColors.surfaceGlass)
                            .clipShape(RoundedRectangle(cornerRadius: SSRadius.sm))
                    }
                }
            }
            .padding(.horizontal, SSSpacing.md)
            .padding(.vertical, SSSpacing.xs)
        }
        .background(SSColors.surface)
        .overlay(
            Rectangle()
                .fill(SSColors.divider)
                .frame(height: 0.5),
            alignment: .top
        )
    }

    private var bottomBar: some View {
        HStack(spacing: SSSpacing.sm) {
            if let parentScript = variant.parentScript {
                NavigationLink(destination: TeleprompterView(script: parentScript, contentOverride: variant.content)) {
                    HStack(spacing: SSSpacing.xs) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Use in Teleprompter")
                            .font(SSTypography.callout.weight(.semibold))
                    }
                    .foregroundStyle(SSColors.lavenderMist)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: SSRadius.md)
                            .fill(SSColors.accent)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, SSSpacing.md)
        .padding(.vertical, SSSpacing.sm)
        .background(SSColors.surface)
    }

    private func insertAtCursor(_ text: String) {
        var content = variant.content
        if let selection = editorSelection {
            switch selection.indices {
            case .selection(let range):
                content.replaceSubrange(range, with: text)
                variant.content = content
                return
            case .multiSelection:
                break
            }
        }
        if let pos = lastKnownCursorPosition, pos <= content.endIndex {
            content.insert(contentsOf: text, at: pos)
            variant.content = content
        } else {
            variant.content = content + text
        }
    }
}
