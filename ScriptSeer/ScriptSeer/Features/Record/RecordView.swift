import SwiftUI
import SwiftData

struct RecordView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Script.updatedAt, order: .reverse) private var scripts: [Script]
    @State private var selectedScript: Script?
    @State private var newScript: Script?

    var body: some View {
        NavigationStack {
            Group {
                if scripts.isEmpty {
                    VStack {
                        Spacer()
                        SSEmptyState(
                            icon: "video.badge.waveform",
                            title: "Camera Recording",
                            subtitle: "Create a script first, then come back to record with it.",
                            actionTitle: "Create Script"
                        ) {
                            let script = Script(title: "Untitled Script", content: "")
                            modelContext.insert(script)
                            newScript = script
                        }
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: SSSpacing.lg) {
                            SSSectionHeader("Select a Script to Record")

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
                                            Image(systemName: "video.fill")
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
            .navigationTitle("Record")
            .navigationDestination(item: $selectedScript) { script in
                CameraRecordView(script: script)
            }
            .navigationDestination(item: $newScript) { script in
                ScriptEditorView(script: script)
            }
        }
    }
}
