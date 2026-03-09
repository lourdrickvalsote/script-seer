import SwiftUI
import SwiftData

enum ScriptSortOrder: String, CaseIterable {
    case recent = "Recent"
    case title = "Title"
}

struct ScriptsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Script.updatedAt, order: .reverse) private var scripts: [Script]
    @Query(sort: \ScriptFolder.name) private var folders: [ScriptFolder]
    @State private var searchText = ""
    @State private var sortOrder: ScriptSortOrder = .recent
    @State private var selectedFolder: ScriptFolder?
    @State private var showNewFolderAlert = false
    @State private var newFolderName = ""
    @State private var showMoveSheet = false
    @State private var scriptToMove: Script?
    @State private var showRenameFolderAlert = false
    @State private var renameFolderName = ""
    @State private var folderToRename: ScriptFolder?
    @State private var showDeleteConfirmation = false
    @State private var scriptToDelete: Script?
    @State private var showDeleteFolderConfirmation = false
    @State private var folderToDelete: ScriptFolder?

    private var filteredScripts: [Script] {
        var filtered: [Script]
        if let folder = selectedFolder {
            filtered = folder.scripts
        } else {
            filtered = Array(scripts)
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            filtered = filtered.filter {
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
                    VStack(spacing: 0) {
                        // Folder filter bar
                        if !folders.isEmpty {
                            folderFilterBar
                        }

                        if filteredScripts.isEmpty && !searchText.isEmpty {
                            VStack(spacing: SSSpacing.md) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 36, weight: .light))
                                    .foregroundStyle(SSColors.textTertiary)
                                Text("No results for \"\(searchText)\"")
                                    .font(SSTypography.subheadline)
                                    .foregroundStyle(SSColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, SSSpacing.xxl)
                        } else {
                            List {
                                ForEach(filteredScripts) { script in
                                    NavigationLink(destination: ScriptDetailView(script: script)) {
                                        ScriptRowView(script: script)
                                    }
                                    .listRowBackground(SSColors.surfaceElevated)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            scriptToDelete = script
                                            showDeleteConfirmation = true
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
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            scriptToMove = script
                                            showMoveSheet = true
                                        } label: {
                                            Label("Move", systemImage: "folder")
                                        }
                                        .tint(SSColors.slate)
                                    }
                                }
                            }
                            .listStyle(.plain)
                            .scrollContentBackground(.hidden)
                        }
                    }
                }
            }
            .background(SSColors.background)
            .navigationTitle("Scripts")
            .searchable(text: $searchText, prompt: "Search scripts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: { createNewScript() }) {
                            Label("New Script", systemImage: "plus")
                        }
                        ImportScriptButton()
                        Divider()
                        Button(action: {
                            newFolderName = ""
                            showNewFolderAlert = true
                        }) {
                            Label("New Folder", systemImage: "folder.badge.plus")
                        }
                        #if DEBUG
                        Divider()
                        Button(action: { seedDemoScripts() }) {
                            Label("Add Demo Scripts", systemImage: "text.badge.star")
                        }
                        #endif
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
            .alert("New Folder", isPresented: $showNewFolderAlert) {
                TextField("Folder name", text: $newFolderName)
                Button("Create") { createFolder() }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Rename Folder", isPresented: $showRenameFolderAlert) {
                TextField("Folder name", text: $renameFolderName)
                Button("Rename") { renameFolder() }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog(
                "Delete \"\(scriptToDelete?.title ?? "Script")\"?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let script = scriptToDelete {
                        deleteScript(script)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This script will be permanently deleted.")
            }
            .confirmationDialog(
                "Delete folder \"\(folderToDelete?.name ?? "")\"?",
                isPresented: $showDeleteFolderConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Folder", role: .destructive) {
                    if let folder = folderToDelete {
                        deleteFolder(folder)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Scripts in this folder will be moved out, not deleted.")
            }
            .sheet(isPresented: $showMoveSheet) {
                MoveToFolderSheet(
                    script: scriptToMove,
                    folders: folders,
                    onMove: { folder in
                        if let script = scriptToMove {
                            script.folder = folder
                            SSHaptics.light()
                        }
                        showMoveSheet = false
                    },
                    onDismiss: { showMoveSheet = false }
                )
                .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Folder Filter Bar

    private var folderFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SSSpacing.xs) {
                FolderChip(name: "All", isSelected: selectedFolder == nil) {
                    selectedFolder = nil
                }

                ForEach(folders) { folder in
                    FolderChip(
                        name: folder.name,
                        count: folder.scripts.count,
                        isSelected: selectedFolder?.id == folder.id
                    ) {
                        selectedFolder = (selectedFolder?.id == folder.id) ? nil : folder
                    }
                    .contextMenu {
                        Button {
                            folderToRename = folder
                            renameFolderName = folder.name
                            showRenameFolderAlert = true
                        } label: {
                            Label("Rename Folder", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            folderToDelete = folder
                            showDeleteFolderConfirmation = true
                        } label: {
                            Label("Delete Folder", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, SSSpacing.md)
            .padding(.vertical, SSSpacing.xs)
        }
        .background(SSColors.surface)
    }

    // MARK: - Actions

    private func createNewScript() {
        let script = Script()
        if let folder = selectedFolder {
            script.folder = folder
        }
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

    private func createFolder() {
        let trimmed = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let folder = ScriptFolder(name: trimmed)
        modelContext.insert(folder)
        SSHaptics.light()
    }

    private func renameFolder() {
        let trimmed = renameFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let folder = folderToRename else { return }
        folder.name = trimmed
        SSHaptics.light()
    }

    private func deleteFolder(_ folder: ScriptFolder) {
        // Move scripts out of the folder before deleting
        for script in folder.scripts {
            script.folder = nil
        }
        if selectedFolder?.id == folder.id {
            selectedFolder = nil
        }
        modelContext.delete(folder)
        SSHaptics.medium()
    }

    private func seedDemoScripts() {
        for script in Script.sampleScripts {
            modelContext.insert(script)
        }
        SSHaptics.success()
    }
}

// MARK: - Folder Chip

private struct FolderChip: View {
    let name: String
    var count: Int? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
            SSHaptics.selection()
        }) {
            HStack(spacing: SSSpacing.xxs) {
                Text(name)
                    .font(SSTypography.caption)
                if let count {
                    Text("\(count)")
                        .font(SSTypography.caption)
                        .foregroundStyle(isSelected ? SSColors.lavenderMist.opacity(0.7) : SSColors.textTertiary)
                }
            }
            .foregroundStyle(isSelected ? SSColors.lavenderMist : SSColors.textSecondary)
            .padding(.horizontal, SSSpacing.sm)
            .padding(.vertical, SSSpacing.xxs)
            .background(
                RoundedRectangle(cornerRadius: SSRadius.full)
                    .fill(isSelected ? SSColors.accent : SSColors.surfaceGlass)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Move to Folder Sheet

private struct MoveToFolderSheet: View {
    let script: Script?
    let folders: [ScriptFolder]
    let onMove: (ScriptFolder?) -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Button(action: { onMove(nil) }) {
                    HStack {
                        Label("No Folder", systemImage: "tray")
                            .foregroundStyle(SSColors.textPrimary)
                        Spacer()
                        if script?.folder == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(SSColors.accent)
                        }
                    }
                }
                .listRowBackground(SSColors.surfaceElevated)

                ForEach(folders) { folder in
                    Button(action: { onMove(folder) }) {
                        HStack {
                            Label(folder.name, systemImage: "folder")
                                .foregroundStyle(SSColors.textPrimary)
                            Spacer()
                            if script?.folder?.id == folder.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(SSColors.accent)
                            }
                        }
                    }
                    .listRowBackground(SSColors.surfaceElevated)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(SSColors.background)
            .navigationTitle("Move to Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                        .foregroundStyle(SSColors.textSecondary)
                }
            }
        }
    }
}
