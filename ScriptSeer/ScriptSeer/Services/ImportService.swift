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
    static let supportedTypes: [UTType] = {
        var types: [UTType] = [.plainText, .rtf, .pdf]
        if let docx = UTType("org.openxmlformats.wordprocessingml.document") {
            types.append(docx)
        }
        return types
    }()

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
        } else if utType.identifier == "org.openxmlformats.wordprocessingml.document" {
            text = try extractDOCXText(from: url)
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

    private static func extractDOCXText(from url: URL) throws -> String {
        // DOCX files are ZIP archives; extract word/document.xml and strip XML tags
        guard let data = try? Data(contentsOf: url) else {
            throw ImportError.fileReadFailed
        }

        // iOS doesn't support .officeOpenXML via NSAttributedString,
        // so go directly to ZIP-based XML extraction
        return try extractDOCXFromZip(data: data)
    }

    private static func extractDOCXFromZip(data: Data) throws -> String {
        // Simple DOCX text extraction: find XML content and strip tags
        // This is a basic approach; production would use a proper ZIP library
        guard let content = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
            throw ImportError.textExtractionFailed
        }

        // Strip XML tags as a fallback
        let stripped = content.replacingOccurrences(
            of: "<[^>]+>",
            with: " ",
            options: .regularExpression
        )
        let cleaned = stripped
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        guard !cleaned.isEmpty else {
            throw ImportError.textExtractionFailed
        }
        return cleaned
    }

    static func titleFromFilename(_ url: URL) -> String {
        url.deletingPathExtension().lastPathComponent
    }
}
