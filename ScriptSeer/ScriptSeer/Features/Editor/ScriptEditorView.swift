import SwiftUI

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
    @FocusState private var editorFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Editor stats bar
            editorStatsBar

            // Main editor
            ScrollView {
                TextEditor(text: Binding(
                    get: { script.content },
                    set: { script.updateContent($0) }
                ))
                .font(SSTypography.body)
                .foregroundStyle(SSColors.textPrimary)
                .scrollContentBackground(.hidden)
                .focused($editorFocused)
                .frame(minHeight: 400)
                .padding(.horizontal, SSSpacing.md)
                .padding(.top, SSSpacing.sm)
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
                Menu {
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
        .onAppear {
            editorFocused = true
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
                // Text formatting
                FormatButton(icon: "bold", label: "Bold") {
                    wrapSelection(with: "**")
                }
                FormatButton(icon: "italic", label: "Italic") {
                    wrapSelection(with: "_")
                }
                FormatButton(icon: "underline", label: "Underline") {
                    wrapSelection(with: "__")
                }

                Divider()
                    .frame(height: 24)
                    .background(SSColors.divider)

                // Headings
                FormatButton(icon: "number", label: "Heading") {
                    insertAtLineStart("# ")
                }

                Divider()
                    .frame(height: 24)
                    .background(SSColors.divider)

                // Speaker & Section markers
                FormatButton(icon: "person.fill", label: "Speaker") {
                    script.updateContent(script.content + "\n[SPEAKER: Name] ")
                    SSHaptics.light()
                }
                FormatButton(icon: "text.line.first.and.arrowtriangle.forward", label: "Section") {
                    script.updateContent(script.content + "\n[SECTION: Title]\n")
                    SSHaptics.light()
                }

                Divider()
                    .frame(height: 24)
                    .background(SSColors.divider)

                // Teleprompter cues by category
                ForEach(CueCategory.allCases, id: \.self) { category in
                    Menu {
                        ForEach(TeleprompterCueType.allCases.filter { $0.category == category }, id: \.self) { cue in
                            Button("\(cue.displaySymbol) \(cue.displayName)") {
                                insertCue(cue)
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

    private func wrapSelection(with marker: String) {
        script.updateContent(script.content + marker + marker)
    }

    private func insertAtLineStart(_ prefix: String) {
        script.updateContent(script.content + "\n" + prefix)
    }

    private func insertCue(_ cue: TeleprompterCueType) {
        script.updateContent(script.content + " " + cue.rawValue + " ")
        SSHaptics.light()
    }
}

private struct FormatButton: View {
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
