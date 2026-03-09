import SwiftUI
import SwiftData

struct RecentlyDeletedView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Script.updatedAt, order: .reverse) private var allScripts: [Script]
    @State private var showDeleteAllConfirmation = false

    private var trashedScripts: [Script] {
        allScripts.filter { $0.isInTrash }
    }

    var body: some View {
        Group {
            if trashedScripts.isEmpty {
                VStack {
                    Spacer()
                    SSEmptyState(
                        icon: "trash",
                        title: "No Deleted Scripts",
                        subtitle: "Scripts you delete will appear here for 30 days before being permanently removed."
                    )
                    .padding(.horizontal, SSSpacing.md)
                    Spacer()
                }
            } else {
                List {
                    ForEach(trashedScripts) { script in
                        deletedScriptRow(script)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(
                                top: SSSpacing.xs,
                                leading: SSSpacing.md,
                                bottom: SSSpacing.xs,
                                trailing: SSSpacing.md
                            ))
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    withAnimation(SSAnimation.standard) {
                                        modelContext.delete(script)
                                        SSHaptics.medium()
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash.fill")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    withAnimation(SSAnimation.standard) {
                                        script.restore()
                                        SSHaptics.success()
                                    }
                                } label: {
                                    Label("Restore", systemImage: "arrow.uturn.backward")
                                }
                                .tint(.green)
                            }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(SSColors.background)
        .navigationTitle("Recently Deleted")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !trashedScripts.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(role: .destructive) {
                            showDeleteAllConfirmation = true
                        } label: {
                            Label("Delete All", systemImage: "trash.fill")
                        }

                        Button {
                            withAnimation(SSAnimation.standard) {
                                for script in trashedScripts {
                                    script.restore()
                                }
                                SSHaptics.success()
                            }
                        } label: {
                            Label("Restore All", systemImage: "arrow.uturn.backward")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(SSColors.accent)
                    }
                }
            }
        }
        .alert("Delete All Scripts?", isPresented: $showDeleteAllConfirmation) {
            Button("Delete All", role: .destructive) {
                withAnimation(SSAnimation.standard) {
                    for script in trashedScripts {
                        modelContext.delete(script)
                    }
                    SSHaptics.medium()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\(trashedScripts.count) script\(trashedScripts.count == 1 ? "" : "s") will be permanently deleted. This cannot be undone.")
        }
        .onAppear {
            purgeExpiredScripts()
        }
    }

    private func deletedScriptRow(_ script: Script) -> some View {
        VStack(alignment: .leading, spacing: SSSpacing.xs) {
            Text(script.title)
                .font(SSTypography.headline)
                .foregroundStyle(SSColors.textPrimary)

            HStack(spacing: SSSpacing.md) {
                Label("\(script.wordCount) words", systemImage: "text.word.spacing")

                if let days = script.daysUntilPermanentDeletion {
                    Label(
                        days == 0 ? "Deleting today" : "\(days) day\(days == 1 ? "" : "s") left",
                        systemImage: "clock"
                    )
                }
            }
            .font(SSTypography.caption)
            .foregroundStyle(SSColors.textTertiary)
        }
        .padding(SSSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: SSRadius.lg)
                .fill(SSColors.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: SSRadius.lg)
                        .stroke(SSColors.divider, lineWidth: 1)
                )
        )
    }

    private func purgeExpiredScripts() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        for script in allScripts where script.isInTrash {
            if let deletedAt = script.deletedAt, deletedAt < cutoff {
                modelContext.delete(script)
            }
        }
    }
}
