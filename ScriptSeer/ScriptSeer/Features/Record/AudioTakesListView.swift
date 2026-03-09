import SwiftUI
import SwiftData

struct AudioTakesListView: View {
    @Environment(\.modelContext) private var modelContext
    let script: Script
    @State private var shareURL: URL?
    @State private var showShareSheet = false

    private var sortedTakes: [AudioTake] {
        script.audioTakes.sorted { $0.date > $1.date }
    }

    var body: some View {
        Group {
            if sortedTakes.isEmpty {
                VStack {
                    Spacer()
                    SSEmptyState(
                        icon: "waveform",
                        title: "No Audio Takes",
                        subtitle: "Record audio to see your takes here."
                    )
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: SSSpacing.sm) {
                        ForEach(sortedTakes) { take in
                            AudioTakeRow(take: take)
                                .contextMenu {
                                    if take.fileURL != nil {
                                        Button {
                                            shareURL = take.fileURL
                                            showShareSheet = true
                                        } label: {
                                            Label("Share", systemImage: "square.and.arrow.up")
                                        }
                                    }

                                    Button(role: .destructive) {
                                        deleteTake(take)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, SSSpacing.md)
                    .padding(.top, SSSpacing.xs)
                }
            }
        }
        .background(SSColors.background)
        .navigationTitle("Audio Takes")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            if let url = shareURL {
                ShareSheet(items: [url])
            }
        }
    }

    private func deleteTake(_ take: AudioTake) {
        AudioFileManager.deleteFile(fileName: take.fileName)
        modelContext.delete(take)
    }
}
