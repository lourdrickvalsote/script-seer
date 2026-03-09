import SwiftUI
import SwiftData

struct PracticeView: View {
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
        Group {
                if scripts.isEmpty {
                    VStack {
                        Spacer()
                        SSEmptyState(
                            icon: "mic.badge.xmark",
                            title: "Practice Mode",
                            subtitle: "Create a script first, then come back to rehearse."
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
                    VStack(spacing: 0) {
                        SSSearchBar(text: $searchText, placeholder: "Search scripts")
                            .padding(.horizontal, SSSpacing.md)
                            .padding(.top, SSSpacing.xs)
                            .padding(.bottom, SSSpacing.xs)

                        ScrollView {
                        VStack(alignment: .leading, spacing: SSSpacing.md) {
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
                                            icon: "mic.fill"
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
            }
            .background(SSColors.background)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .preference(key: HideRecordButtonKey.self, value: true)
            .navigationDestination(item: $selectedScript) { script in
                PracticeSessionView(script: script)
            }
            .navigationDestination(item: $newScript) { script in
                ScriptEditorView(script: script)
            }
    }
}
