import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Script.updatedAt, order: .reverse) private var scripts: [Script]
    @State private var showFilePicker = false
    @State private var importError: String?
    @State private var showImportError = false
    @State private var newScript: Script?

    private var recentScripts: [Script] {
        Array(scripts.prefix(5))
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Branded header — sticky
                HStack(spacing: 0) {
                    Text("Script")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(SSColors.textSecondary)
                    Text("Seer")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(SSColors.accent)
                }
                .padding(.top, SSSpacing.xs)
                .padding(.bottom, SSSpacing.sm)
                .padding(.horizontal, SSSpacing.md)

                ScrollView {
                    VStack(alignment: .leading, spacing: SSSpacing.lg) {
                        // Quick Actions
                        SSSectionHeader("Quick Actions")

                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: SSSpacing.xs),
                                GridItem(.flexible(), spacing: SSSpacing.xs)
                            ],
                            spacing: SSSpacing.xs
                        ) {
                            QuickActionCard(icon: "plus", title: "New Script", subtitle: "Start writing") {
                                createNewScript()
                            }
                            QuickActionCard(icon: "doc.badge.arrow.up", title: "Import", subtitle: "From file") {
                                showFilePicker = true
                            }
                            NavigationLink(destination: ScriptsView()) {
                                QuickActionCardLabel(icon: "doc.text.fill", title: "Scripts", subtitle: "Your library")
                            }
                            .buttonStyle(.plain)
                            NavigationLink(destination: PracticeView()) {
                                QuickActionCardLabel(icon: "mic.fill", title: "Practice", subtitle: "Rehearse")
                            }
                            .buttonStyle(.plain)
                        }

                        // Recent Scripts
                        if recentScripts.isEmpty {
                            SSSectionHeader("Recent Scripts")
                            VStack {
                                Spacer().frame(minHeight: SSSpacing.lg)
                                SSEmptyState(
                                    icon: "doc.text",
                                    title: "No Scripts Yet",
                                    subtitle: "Create your first script to start prompting like a pro."
                                )
                                Spacer().frame(minHeight: SSSpacing.xxl)
                                SSButton("Create Script", icon: "plus", variant: .primary) {
                                    createNewScript()
                                }
                                .padding(.bottom, SSSpacing.md)
                            }
                            .frame(minHeight: 300)
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
                }
            }
            .background(SSColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: ImportService.supportedTypes,
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    Task {
                        do {
                            let text = try await ImportService.extractText(from: url)
                            await MainActor.run {
                                let title = ImportService.titleFromFilename(url)
                                let script = Script(title: title, content: text)
                                modelContext.insert(script)
                                SSHaptics.success()
                            }
                        } catch {
                            await MainActor.run {
                                importError = error.localizedDescription
                                showImportError = true
                            }
                        }
                    }
                }
            }
            .alert("Import Failed", isPresented: $showImportError) {
                Button("OK") {}
            } message: {
                Text(importError ?? "Could not import the file.")
            }
            .navigationDestination(item: $newScript) { script in
                ScriptEditorView(script: script)
            }
        }
    }

    private func createNewScript() {
        let script = Script()
        modelContext.insert(script)
        newScript = script
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
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(SSColors.accent)
                        .frame(width: 40, height: 40)
                        .background(SSColors.accentWarm)
                        .clipShape(RoundedRectangle(cornerRadius: SSRadius.sm))

                    Spacer().frame(height: SSSpacing.xxs)

                    Text(title)
                        .font(SSTypography.headline)
                        .fontWeight(.bold)
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

private struct QuickActionCardLabel: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        SSGlassPanel {
            VStack(alignment: .leading, spacing: SSSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(SSColors.accent)
                    .frame(width: 40, height: 40)
                    .background(SSColors.accentWarm)
                    .clipShape(RoundedRectangle(cornerRadius: SSRadius.sm))

                Spacer().frame(height: SSSpacing.xxs)

                Text(title)
                    .font(SSTypography.headline)
                    .fontWeight(.bold)
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

private struct RecentScriptCard: View {
    let script: Script

    var body: some View {
        SSCard {
            HStack {
                VStack(alignment: .leading, spacing: SSSpacing.xxs) {
                    Text(script.title)
                        .font(SSTypography.headline)
                        .fontWeight(.bold)
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
