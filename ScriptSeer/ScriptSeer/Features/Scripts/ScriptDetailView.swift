import SwiftUI

struct ScriptDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var script: Script
    @State private var editingTitle = false
    @FocusState private var titleFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SSSpacing.lg) {
                // Title
                if editingTitle {
                    TextField("Script Title", text: $script.title)
                        .font(SSTypography.title)
                        .foregroundStyle(SSColors.textPrimary)
                        .focused($titleFocused)
                        .onSubmit {
                            editingTitle = false
                            script.updateTitle(script.title)
                        }
                        .padding(.horizontal, SSSpacing.md)
                } else {
                    Text(script.title)
                        .font(SSTypography.title)
                        .foregroundStyle(SSColors.textPrimary)
                        .padding(.horizontal, SSSpacing.md)
                        .onTapGesture {
                            editingTitle = true
                            titleFocused = true
                        }
                }

                // Metadata
                SSGlassPanel {
                    HStack(spacing: SSSpacing.lg) {
                        MetadataItem(icon: "clock", label: "Duration", value: script.formattedDuration)
                        MetadataItem(icon: "text.word.spacing", label: "Words", value: "\(script.wordCount)")
                        MetadataItem(icon: "calendar", label: "Updated", value: script.updatedAt.formatted(.relative(presentation: .named)))
                    }
                }
                .padding(.horizontal, SSSpacing.md)

                // Content preview
                SSCard {
                    VStack(alignment: .leading, spacing: SSSpacing.sm) {
                        Text("Script Content")
                            .font(SSTypography.footnote)
                            .foregroundStyle(SSColors.textTertiary)
                            .textCase(.uppercase)
                            .tracking(0.5)

                        Text(script.content.isEmpty ? "No content yet. Tap edit to start writing." : script.content)
                            .font(SSTypography.body)
                            .foregroundStyle(script.content.isEmpty ? SSColors.textTertiary : SSColors.textPrimary)
                            .lineSpacing(6)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, SSSpacing.md)

                // Actions
                VStack(spacing: SSSpacing.sm) {
                    SSButton("Start Prompting", icon: "play.fill", variant: .primary) {}
                    SSButton("Edit Script", icon: "pencil", variant: .secondary) {}
                }
                .padding(.horizontal, SSSpacing.md)
            }
            .padding(.top, SSSpacing.sm)
        }
        .background(SSColors.background)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

private struct MetadataItem: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: SSSpacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(SSColors.accent)

            Text(value)
                .font(SSTypography.headline)
                .foregroundStyle(SSColors.textPrimary)

            Text(label)
                .font(SSTypography.caption)
                .foregroundStyle(SSColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}
