import SwiftUI
import SwiftData

struct ScriptEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var script: Script
    @State private var showFormattingBar = true
    @State private var showCueMenu = false
    @State private var showVariantSheet = false
    @State private var showAIActions = false
    @State private var showVariantBrowser = false
    @State private var showReflowConfirm = false
    @State private var showRevisionHistory = false
    @State private var showRenameAlert = false
    @State private var renameText = ""
    @FocusState private var editorFocused: Bool
    @State private var editorSelection: TextSelection?
    @State private var lastKnownCursorPosition: String.Index?
    @State private var initialWordCount: Int = 0
    @State private var isNewEmptyScript = false

    var body: some View {
        VStack(spacing: 0) {
            // Editor stats bar
            editorStatsBar

            // Main editor
            ScrollView {
                TextEditor(text: Binding(
                    get: { script.content },
                    set: { script.updateContent($0) }
                ), selection: $editorSelection)
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

            // Formatting toolbar
            if showFormattingBar {
                formattingToolbar
            }
        }
        .background(SSColors.background)
        .navigationTitle(script.title)
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
                            renameText = script.title
                            showRenameAlert = true
                        }) {
                            Label("Rename Script", systemImage: "pencil")
                        }
                        Divider()
                        Button(action: { showVariantSheet = true }) {
                            Label("Duplicate as Variant", systemImage: "doc.on.doc")
                        }
                        Button(action: { showAIActions = true }) {
                            Label("AI Actions", systemImage: "wand.and.stars")
                        }
                        Button(action: { showVariantBrowser = true }) {
                            Label("View Variants", systemImage: "list.bullet.rectangle")
                        }
                        Divider()
                        Button(action: { showReflowConfirm = true }) {
                            Label("Reflow for Prompter", systemImage: "text.line.first.and.arrowtriangle.forward")
                        }
                        Button(action: { showRevisionHistory = true }) {
                            Label("Version History", systemImage: "clock.arrow.circlepath")
                        }
                        Divider()
                        Button(action: { showFormattingBar.toggle() }) {
                            Label(
                                showFormattingBar ? "Hide Toolbar" : "Show Toolbar",
                                systemImage: "keyboard.chevron.compact.down"
                            )
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(SSColors.accent)
                    }
                }
            }
        }
        .sheet(isPresented: $showVariantSheet) {
            DuplicateVariantSheet(script: script)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showAIActions) {
            AIActionSheet(script: script)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showVariantBrowser) {
            VariantBrowser(script: script)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showRevisionHistory) {
            RevisionHistoryView(script: script)
                .presentationDetents([.large])
        }
        .alert("Reflow Script", isPresented: $showReflowConfirm) {
            Button("Reflow") {
                let reflowed = ReadabilityEngine.reflow(script.content)
                script.updateContent(reflowed)
                SSHaptics.success()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            let preview = ReadabilityEngine.previewReflow(script.content)
            Text("Reformat text into ~\(preview.lineCount) lines optimized for teleprompter reading. This modifies the script content.")
        }
        .alert("Rename Script", isPresented: $showRenameAlert) {
            TextField("Script title", text: $renameText)
            Button("Save") {
                let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    script.title = trimmed
                    SSHaptics.success()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear {
            editorFocused = true
            initialWordCount = script.wordCount
            isNewEmptyScript = script.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        .onDisappear {
            deleteIfStillEmpty()
            autoSaveRevisionIfNeeded()
        }
    }

    private var editorStatsBar: some View {
        HStack(spacing: SSSpacing.lg) {
            Label(script.formattedDuration, systemImage: "clock")
            Label("\(script.wordCount) words", systemImage: "text.word.spacing")
            Spacer()
            Text("Editing")
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
                // Speaker & Section markers
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

                // Teleprompter cues by category
                ForEach(CueCategory.allCases, id: \.self) { category in
                    Menu {
                        ForEach(TeleprompterCueType.allCases.filter { $0.category == category }, id: \.self) { cue in
                            Button {
                                insertCue(cue)
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

    private func insertAtCursor(_ text: String) {
        var content = script.content
        if let selection = editorSelection {
            switch selection.indices {
            case .selection(let range):
                content.replaceSubrange(range, with: text)
                script.updateContent(content)
                return
            case .multiSelection:
                break
            }
        }
        if let pos = lastKnownCursorPosition, pos <= content.endIndex {
            content.insert(contentsOf: text, at: pos)
            script.updateContent(content)
        } else {
            script.updateContent(content + text)
        }
    }

    private func insertCue(_ cue: TeleprompterCueType) {
        insertAtCursor(" " + cue.rawValue + " ")
        SSHaptics.light()
    }

    private func deleteIfStillEmpty() {
        guard isNewEmptyScript, !script.isDeleted else { return }
        let trimmed = script.content.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasDefaultTitle = script.title == "Untitled Script"
        if trimmed.isEmpty && hasDefaultTitle {
            modelContext.delete(script)
        }
    }

    private func autoSaveRevisionIfNeeded() {
        guard !script.isDeleted else { return }
        let delta = abs(script.wordCount - initialWordCount)
        // Save a revision if the word count changed by 10+ words
        guard delta >= 10 else { return }
        let revision = ScriptRevision(script: script, changeDescription: "Auto-saved")
        modelContext.insert(revision)
    }
}

struct FormatButton: View {
    let icon: String?
    var emoji: String? = nil
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if let emoji {
                    Text(emoji)
                        .font(.system(size: 16))
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                }
            }
            .frame(width: 36, height: 36)
            .background(SSColors.surfaceGlass)
            .clipShape(RoundedRectangle(cornerRadius: SSRadius.sm))
            .foregroundStyle(SSColors.textSecondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
