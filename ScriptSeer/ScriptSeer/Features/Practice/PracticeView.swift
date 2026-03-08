import SwiftUI
import SwiftData

struct PracticeView: View {
    @Query(sort: \Script.updatedAt, order: .reverse) private var scripts: [Script]
    @State private var selectedScript: Script?

    var body: some View {
        NavigationStack {
            Group {
                if scripts.isEmpty {
                    VStack {
                        Spacer()
                        SSEmptyState(
                            icon: "mic.badge.xmark",
                            title: "Practice Mode",
                            subtitle: "Create a script first, then come back to rehearse.",
                            actionTitle: nil
                        )
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: SSSpacing.lg) {
                            SSSectionHeader("Select a Script to Practice")

                            ForEach(scripts) { script in
                                Button(action: { selectedScript = script }) {
                                    SSCard {
                                        HStack {
                                            VStack(alignment: .leading, spacing: SSSpacing.xxs) {
                                                Text(script.title)
                                                    .font(SSTypography.headline)
                                                    .foregroundStyle(SSColors.textPrimary)
                                                    .lineLimit(1)
                                                Text("\(script.wordCount) words · \(script.formattedDuration)")
                                                    .font(SSTypography.caption)
                                                    .foregroundStyle(SSColors.textTertiary)
                                            }
                                            Spacer()
                                            Image(systemName: "mic.fill")
                                                .foregroundStyle(SSColors.accent)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, SSSpacing.md)
                        .padding(.top, SSSpacing.sm)
                    }
                }
            }
            .background(SSColors.background)
            .navigationTitle("Practice")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(item: $selectedScript) { script in
                PracticeSessionView(script: script)
            }
        }
    }
}
