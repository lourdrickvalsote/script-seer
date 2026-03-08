import SwiftUI

struct HomeView: View {
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
                        QuickActionCard(icon: "plus", title: "New Script", subtitle: "Start writing")
                        QuickActionCard(icon: "doc.badge.arrow.up", title: "Import", subtitle: "From file")
                        QuickActionCard(icon: "play.fill", title: "Quick Prompt", subtitle: "Paste & go")
                        QuickActionCard(icon: "video.fill", title: "Record", subtitle: "Camera mode")
                    }

                    SSSectionHeader("Recent Scripts")

                    SSEmptyState(
                        icon: "doc.text",
                        title: "No Scripts Yet",
                        subtitle: "Create your first script to start prompting like a pro.",
                        actionTitle: "Create Script"
                    ) {}
                }
                .padding(.horizontal, SSSpacing.md)
                .padding(.top, SSSpacing.sm)
            }
            .background(SSColors.background)
            .navigationTitle("ScriptSeer")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

private struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
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
}
