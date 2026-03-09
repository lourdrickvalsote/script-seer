import SwiftUI
import SwiftData

struct RevisionHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let script: Script
    @State private var showRestoreConfirm = false
    @State private var revisionToRestore: ScriptRevision?
    @State private var showSnapshotConfirmation = false

    private var sortedRevisions: [ScriptRevision] {
        script.revisions.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sortedRevisions.isEmpty {
                    emptyState
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
            .overlay {
                if showSnapshotConfirmation {
                    snapshotConfirmationBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
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

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: SSSpacing.lg) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(SSColors.accentSubtle)
                    .frame(width: 80, height: 80)

                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(SSColors.accent)
            }

            VStack(spacing: SSSpacing.xs) {
                Text("No Revisions Yet")
                    .font(SSTypography.title2)
                    .foregroundStyle(SSColors.textPrimary)

                Text("Revisions are saved automatically when you\nmake significant edits, or you can save a\nsnapshot manually using the camera icon above.")
                    .font(SSTypography.subheadline)
                    .foregroundStyle(SSColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Button {
                saveCurrentRevision()
            } label: {
                HStack(spacing: SSSpacing.xs) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 14))
                    Text("Save Snapshot Now")
                        .font(SSTypography.headline)
                }
                .foregroundStyle(SSColors.accent)
                .padding(.horizontal, SSSpacing.lg)
                .padding(.vertical, SSSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: SSRadius.md)
                        .fill(SSColors.accentSubtle)
                )
            }
            .buttonStyle(.plain)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, SSSpacing.xl)
    }

    // MARK: - Snapshot Confirmation

    private var snapshotConfirmationBanner: some View {
        VStack {
            HStack(spacing: SSSpacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.green)
                Text("Snapshot saved")
                    .font(SSTypography.subheadline)
                    .foregroundStyle(SSColors.textPrimary)
            }
            .padding(.horizontal, SSSpacing.lg)
            .padding(.vertical, SSSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: SSRadius.full)
                    .fill(SSColors.surfaceElevated)
                    .shadow(color: SSColors.shadow, radius: 12, x: 0, y: 4)
            )
            .padding(.top, SSSpacing.xs)

            Spacer()
        }
    }

    // MARK: - Actions

    private func saveCurrentRevision() {
        let revision = ScriptRevision(script: script, changeDescription: "Manual snapshot")
        modelContext.insert(revision)
        SSHaptics.success()

        withAnimation(SSAnimation.standard) {
            showSnapshotConfirmation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(SSAnimation.standard) {
                showSnapshotConfirmation = false
            }
        }
    }

    private func restoreRevision(_ revision: ScriptRevision) {
        let backup = ScriptRevision(script: script, changeDescription: "Auto-save before restore")
        modelContext.insert(backup)

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
