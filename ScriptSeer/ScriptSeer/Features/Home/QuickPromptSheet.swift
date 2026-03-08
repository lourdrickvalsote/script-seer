import SwiftUI
import SwiftData

struct QuickPromptSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var scriptText = ""
    @State private var navigateToPrompt = false
    @State private var createdScript: Script?

    var body: some View {
        NavigationStack {
            VStack(spacing: SSSpacing.md) {
                Text("Paste or type your script, then start prompting immediately.")
                    .font(SSTypography.subheadline)
                    .foregroundStyle(SSColors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextEditor(text: $scriptText)
                    .font(SSTypography.body)
                    .foregroundStyle(SSColors.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(SSSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: SSRadius.md)
                            .fill(SSColors.surfaceElevated)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: SSRadius.md)
                            .stroke(SSColors.divider, lineWidth: 0.5)
                    )
                    .frame(minHeight: 200)

                HStack(spacing: SSSpacing.sm) {
                    SSButton("Paste from Clipboard", icon: "doc.on.clipboard", variant: .secondary) {
                        if let clipboardText = UIPasteboard.general.string, !clipboardText.isEmpty {
                            scriptText = clipboardText
                            SSHaptics.light()
                        }
                    }
                }

                Spacer()

                SSButton("Start Prompting", icon: "play.fill", variant: .primary) {
                    let trimmed = scriptText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    let script = Script(title: "Quick Prompt", content: trimmed)
                    modelContext.insert(script)
                    createdScript = script
                    SSHaptics.medium()
                }
                .disabled(scriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(scriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
            }
            .padding(SSSpacing.lg)
            .background(SSColors.background)
            .navigationTitle("Quick Prompt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(SSColors.textSecondary)
                }
            }
            .navigationDestination(item: $createdScript) { script in
                TeleprompterView(script: script)
            }
        }
    }
}
