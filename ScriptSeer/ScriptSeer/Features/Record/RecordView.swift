import SwiftUI
import SwiftData

struct RecordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Script.updatedAt, order: .reverse) private var scripts: [Script]
    @State private var selectedScript: Script?
    @State private var newScript: Script?
    @State private var searchText = ""

    private var filteredScripts: [Script] {
        if searchText.isEmpty { return Array(scripts) }
        let query = searchText.lowercased()
        return scripts.filter {
            $0.title.lowercased().contains(query) ||
            $0.content.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if scripts.isEmpty {
                    VStack {
                        Spacer()
                        SSEmptyState(
                            icon: "video.badge.waveform",
                            title: "Camera Recording",
                            subtitle: "Create a script first, then come back to record with it."
                        )
                        .padding(.horizontal, SSSpacing.md)
                        Spacer()
                        Spacer()
                        SSButton("Create Script", icon: "plus", variant: .primary) {
                            let script = Script(title: "Untitled Script", content: "")
                            modelContext.insert(script)
                            newScript = script
                            SSHaptics.light()
                        }
                        .padding(.horizontal, SSSpacing.md)
                        .padding(.bottom, SSSpacing.lg)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: SSSpacing.md) {
                            SSSearchBar(text: $searchText, placeholder: "Search scripts")

                            if filteredScripts.isEmpty {
                                VStack(spacing: SSSpacing.md) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 36, weight: .light))
                                        .foregroundStyle(SSColors.textTertiary)
                                    Text("No results for \"\(searchText)\"")
                                        .font(SSTypography.subheadline)
                                        .foregroundStyle(SSColors.textSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, SSSpacing.xxl)
                            } else {
                                ForEach(filteredScripts) { script in
                                    Button {
                                        selectedScript = script
                                        SSHaptics.light()
                                    } label: {
                                        ScriptSelectCard(
                                            script: script,
                                            icon: "video.fill"
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, SSSpacing.md)
                        .padding(.top, SSSpacing.xs)
                    }
                }
            }
            .background(SSColors.background)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(SSColors.textSecondary)
                    }
                }
            }
            .navigationDestination(item: $selectedScript) { script in
                CameraRecordView(script: script)
            }
            .navigationDestination(item: $newScript) { script in
                ScriptEditorView(script: script)
            }
        }
    }
}
