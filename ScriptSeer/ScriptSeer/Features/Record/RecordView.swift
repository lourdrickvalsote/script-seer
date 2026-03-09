import SwiftUI
import SwiftData

private enum RecordingType: String, CaseIterable {
    case video = "Video"
    case audio = "Audio"

    var icon: String {
        switch self {
        case .video: "video.fill"
        case .audio: "waveform"
        }
    }

    var emptyTitle: String {
        switch self {
        case .video: "Camera Recording"
        case .audio: "Audio Recording"
        }
    }

    var emptySubtitle: String {
        switch self {
        case .video: "Create a script first, then come back to record with it."
        case .audio: "Create a script first, then come back to record audio."
        }
    }
}

struct RecordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Script.updatedAt, order: .reverse) private var scripts: [Script]
    @State private var selectedScript: Script?
    @State private var newScript: Script?
    @State private var searchText = ""
    @State private var recordingType: RecordingType = .video

    private var activeScripts: [Script] {
        scripts.filter { !$0.isInTrash }
    }

    private var filteredScripts: [Script] {
        if searchText.isEmpty { return activeScripts }
        let query = searchText.lowercased()
        return activeScripts.filter {
            $0.title.lowercased().contains(query) ||
            $0.content.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if activeScripts.isEmpty {
                    VStack {
                        Spacer()
                        SSEmptyState(
                            icon: recordingType.icon,
                            title: recordingType.emptyTitle,
                            subtitle: recordingType.emptySubtitle
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
                            // Mode picker
                            Picker("Recording Type", selection: $recordingType) {
                                ForEach(RecordingType.allCases, id: \.self) { type in
                                    Label(type.rawValue, systemImage: type.icon)
                                        .tag(type)
                                }
                            }
                            .pickerStyle(.segmented)

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
                                            icon: recordingType.icon
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
                switch recordingType {
                case .video:
                    CameraRecordView(script: script)
                case .audio:
                    AudioRecordView(script: script)
                }
            }
            .navigationDestination(item: $newScript) { script in
                ScriptEditorView(script: script)
            }
        }
    }
}
