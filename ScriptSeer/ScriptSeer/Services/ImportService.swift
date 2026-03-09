import Foundation
import UniformTypeIdentifiers
import PDFKit

enum ImportError: LocalizedError {
    case unsupportedFormat
    case fileReadFailed
    case textExtractionFailed
    case emptyContent

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat: "This file format isn't supported yet."
        case .fileReadFailed: "Couldn't read the file. It may be corrupted or inaccessible."
        case .textExtractionFailed: "Couldn't extract text from this file."
        case .emptyContent: "The file appears to be empty."
        }
    }
}

enum ImportService {
    static let supportedTypes: [UTType] = [.plainText, .rtf, .pdf]

    static func extractText(from url: URL) async throws -> String {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }

        guard let typeID = try? url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier,
              let utType = UTType(typeID) else {
            throw ImportError.unsupportedFormat
        }

        let text: String
        if utType.conforms(to: .plainText) {
            text = try extractPlainText(from: url)
        } else if utType.conforms(to: .rtf) {
            text = try extractRTFText(from: url)
        } else if utType.conforms(to: .pdf) {
            text = try extractPDFText(from: url)
        } else {
            throw ImportError.unsupportedFormat
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ImportError.emptyContent
        }
        return trimmed
    }

    private static func extractPlainText(from url: URL) throws -> String {
        guard let data = try? Data(contentsOf: url),
              let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
            throw ImportError.fileReadFailed
        }
        return text
    }

    private static func extractRTFText(from url: URL) throws -> String {
        guard let data = try? Data(contentsOf: url) else {
            throw ImportError.fileReadFailed
        }
        guard let attributed = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        ) else {
            throw ImportError.textExtractionFailed
        }
        return attributed.string
    }

    private static func extractPDFText(from url: URL) throws -> String {
        guard let document = PDFDocument(url: url) else {
            throw ImportError.fileReadFailed
        }
        var texts: [String] = []
        for i in 0..<document.pageCount {
            if let page = document.page(at: i), let pageText = page.string {
                texts.append(pageText)
            }
        }
        guard !texts.isEmpty else {
            throw ImportError.textExtractionFailed
        }
        return texts.joined(separator: "\n\n")
    }


    static func titleFromFilename(_ url: URL) -> String {
        url.deletingPathExtension().lastPathComponent
    }
}
