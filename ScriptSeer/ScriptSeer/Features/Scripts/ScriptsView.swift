import SwiftUI
import SwiftData

enum ScriptSortOrder: String, CaseIterable {
    case recent = "Recent"
    case title = "Title"
}

struct ScriptsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Script.updatedAt, order: .reverse) private var scripts: [Script]
    @State private var searchText = ""
    @State private var sortOrder: ScriptSortOrder = .recent
    @State private var showingNewScript = false

    private var filteredScripts: [Script] {
        let filtered: [Script]
        if searchText.isEmpty {
            filtered = scripts
        } else {
            let query = searchText.lowercased()
            filtered = scripts.filter {
                $0.title.lowercased().contains(query) ||
                $0.content.lowercased().contains(query)
            }
        }
        switch sortOrder {
        case .recent:
            return filtered.sorted { $0.updatedAt > $1.updatedAt }
        case .title:
            return filtered.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if scripts.isEmpty {
                    ScrollView {
                        SSEmptyState(
                            icon: "doc.text.magnifyingglass",
                            title: "Your Script Library",
                            subtitle: "Scripts you create or import will appear here.",
                            actionTitle: "Create Script"
                        ) {
                            createNewScript()
                        }
                        .padding(.top, SSSpacing.xxl)
                    }
                } else {
                    List {
                        ForEach(filteredScripts) { script in
                            NavigationLink(destination: ScriptDetailView(script: script)) {
                                ScriptRowView(script: script)
                            }
                            .listRowBackground(SSColors.surfaceElevated)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteScript(script)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    duplicateScript(script)
                                } label: {
                                    Label("Duplicate", systemImage: "doc.on.doc")
                                }
                                .tint(SSColors.accent)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(SSColors.background)
            .navigationTitle("Scripts")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search scripts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: { createNewScript() }) {
                            Label("New Script", systemImage: "plus")
                        }
                        Button(action: { seedDemoScripts() }) {
                            Label("Add Demo Scripts", systemImage: "text.badge.star")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(SSColors.accent)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Sort", selection: $sortOrder) {
                            ForEach(ScriptSortOrder.allCases, id: \.self) { order in
                                Text(order.rawValue).tag(order)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundStyle(SSColors.accent)
                    }
                }
            }
        }
    }

    private func createNewScript() {
        let script = Script()
        modelContext.insert(script)
        SSHaptics.light()
    }

    private func duplicateScript(_ script: Script) {
        let copy = script.duplicate()
        modelContext.insert(copy)
        SSHaptics.light()
    }

    private func deleteScript(_ script: Script) {
        modelContext.delete(script)
        SSHaptics.medium()
    }

    private func seedDemoScripts() {
        for script in Script.sampleScripts {
            modelContext.insert(script)
        }
        SSHaptics.success()
    }
}
