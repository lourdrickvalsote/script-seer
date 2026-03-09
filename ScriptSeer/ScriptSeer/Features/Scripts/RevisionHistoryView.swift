import SwiftUI
import SwiftData

struct RevisionHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let script: Script
    @State private var showRestoreConfirm = false
    @State private var revisionToRestore: ScriptRevision?

    private var sortedRevisions: [ScriptRevision] {
        script.revisions.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sortedRevisions.isEmpty {
                    VStack(spacing: SSSpacing.lg) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 48))
                            .foregroundStyle(SSColors.textTertiary)
                        Text("No Revisions Yet")
                            .font(SSTypography.headline)
                            .foregroundStyle(SSColors.textPrimary)
                        Text("Revisions are saved when you make significant edits.")
                            .font(SSTypography.subheadline)
                            .foregroundStyle(SSColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(SSSpacing.xl)
                } else {
                    List {
                        ForEach(sortedRevisions) { revision in
                            RevisionRow(revision: revision) {
                                revisionToRestore = revision
                                showRestoreConfirm = true
                            }
                            .listRowBackground(SSColors.surfaceElevated)
                        }
                        .onDelete { indexSet in
                            let snapshot = sortedRevisions
                            for index in indexSet {
                                modelContext.delete(snapshot[index])
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(SSColors.background)
            .navigationTitle("Version History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(SSColors.textSecondary)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: saveCurrentRevision) {
                        Label("Save Snapshot", systemImage: "camera.fill")
                    }
                    .foregroundStyle(SSColors.accent)
                }
            }
            .confirmationDialog(
                "Restore this version?",
                isPresented: $showRestoreConfirm,
                presenting: revisionToRestore
            ) { revision in
                Button("Restore") {
                    restoreRevision(revision)
                }
                Button("Cancel", role: .cancel) {}
            } message: { revision in
                Text("This will replace the current script content with the version from \(revision.createdAt.formatted(.dateTime.month().day().hour().minute())).")
            }
        }
    }

    private func saveCurrentRevision() {
        let revision = ScriptRevision(script: script, changeDescription: "Manual snapshot")
        modelContext.insert(revision)
        SSHaptics.success()
    }

    private func restoreRevision(_ revision: ScriptRevision) {
        // Save current as a revision first
        let backup = ScriptRevision(script: script, changeDescription: "Auto-save before restore")
        modelContext.insert(backup)

        // Restore
        script.updateContent(revision.content)
        script.updateTitle(revision.title)
        SSHaptics.success()
        dismiss()
    }
}

private struct RevisionRow: View {
    let revision: ScriptRevision
    let onRestore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: SSSpacing.xxs) {
            HStack {
                Text(revision.createdAt.formatted(.dateTime.month().day().hour().minute()))
                    .font(SSTypography.subheadline)
                    .foregroundStyle(SSColors.textPrimary)
                Spacer()
                Text("\(revision.wordCount) words")
                    .font(SSTypography.caption)
                    .foregroundStyle(SSColors.textTertiary)
            }

            Text(revision.changeDescription)
                .font(SSTypography.caption)
                .foregroundStyle(SSColors.textSecondary)

            Text(revision.content.prefix(100) + (revision.content.count > 100 ? "..." : ""))
                .font(SSTypography.caption)
                .foregroundStyle(SSColors.textTertiary)
                .lineLimit(2)
        }
        .padding(.vertical, SSSpacing.xxs)
        .contentShape(Rectangle())
        .onTapGesture { onRestore() }
    }
}
