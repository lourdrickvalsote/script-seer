import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportScriptButton: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showFilePicker = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isImporting = false

    let onImported: ((Script) -> Void)?

    init(onImported: ((Script) -> Void)? = nil) {
        self.onImported = onImported
    }

    var body: some View {
        Button(action: { showFilePicker = true }) {
            Label("Import from File", systemImage: "doc.badge.arrow.up")
        }
        .disabled(isImporting)
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: ImportService.supportedTypes,
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .alert("Import Failed", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            isImporting = true
            Task {
                do {
                    let text = try await ImportService.extractText(from: url)
                    let title = ImportService.titleFromFilename(url)
                    await MainActor.run {
                        let script = Script(title: title, content: text)
                        modelContext.insert(script)
                        isImporting = false
                        SSHaptics.success()
                        onImported?(script)
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                        showError = true
                        isImporting = false
                        SSHaptics.error()
                    }
                }
            }
        case .failure(_):
            errorMessage = "Could not access the file. Please try again."
            showError = true
            SSHaptics.error()
        }
    }
}
