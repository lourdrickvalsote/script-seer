import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Script.updatedAt, order: .reverse) private var scripts: [Script]

    private var recentScripts: [Script] {
        Array(scripts.prefix(5))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: SSSpacing.lg) {
                    SSSectionHeader("Quick Actions")

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: SSSpacing.sm),
                            GridItem(.flexible(), spacing: SSSpacing.sm)
                        ],
                        spacing: SSSpacing.sm
                    ) {
                        QuickActionCard(icon: "plus", title: "New Script", subtitle: "Start writing") {
                            createNewScript()
                        }
                        QuickActionCard(icon: "doc.badge.arrow.up", title: "Import", subtitle: "From file") {}
                        QuickActionCard(icon: "play.fill", title: "Quick Prompt", subtitle: "Paste & go") {}
                        QuickActionCard(icon: "video.fill", title: "Record", subtitle: "Camera mode") {}
                    }

                    // Recent Scripts
                    if recentScripts.isEmpty {
                        SSSectionHeader("Recent Scripts")
                        SSEmptyState(
                            icon: "doc.text",
                            title: "No Scripts Yet",
                            subtitle: "Create your first script to start prompting like a pro.",
                            actionTitle: "Create Script"
                        ) {
                            createNewScript()
                        }
                    } else {
                        SSSectionHeader("Recent Scripts")
                        VStack(spacing: SSSpacing.sm) {
                            ForEach(recentScripts) { script in
                                NavigationLink(destination: ScriptDetailView(script: script)) {
                                    RecentScriptCard(script: script)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, SSSpacing.md)
                .padding(.top, SSSpacing.sm)
            }
            .background(SSColors.background)
            .navigationTitle("ScriptSeer")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func createNewScript() {
        let script = Script()
        modelContext.insert(script)
        SSHaptics.light()
    }
}

private struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SSGlassPanel {
                VStack(alignment: .leading, spacing: SSSpacing.xs) {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(SSColors.accent)

                    Spacer().frame(height: SSSpacing.xs)

                    Text(title)
                        .font(SSTypography.headline)
                        .foregroundStyle(SSColors.textPrimary)

                    Text(subtitle)
                        .font(SSTypography.caption)
                        .foregroundStyle(SSColors.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, SSSpacing.xs)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct RecentScriptCard: View {
    let script: Script

    var body: some View {
        SSCard {
            HStack {
                VStack(alignment: .leading, spacing: SSSpacing.xxs) {
                    Text(script.title)
                        .font(SSTypography.headline)
                        .foregroundStyle(SSColors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: SSSpacing.sm) {
                        Text(script.formattedDuration)
                        Text("·")
                        Text("\(script.wordCount) words")
                    }
                    .font(SSTypography.caption)
                    .foregroundStyle(SSColors.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SSColors.textTertiary)
            }
        }
    }
}
