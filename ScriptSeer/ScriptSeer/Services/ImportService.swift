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
        // DOCX files are ZIP archives containing word/document.xml
        // Locate the local file header for word/document.xml inside the ZIP
        guard let xmlData = findFileInZip(data: data, name: "word/document.xml") else {
            throw ImportError.textExtractionFailed
        }

        guard let xmlString = String(data: xmlData, encoding: .utf8) else {
            throw ImportError.textExtractionFailed
        }

        // Strip XML tags to extract text content
        let stripped = xmlString.replacingOccurrences(
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

    /// Minimal ZIP parser that finds a named file entry and returns its uncompressed data.
    /// Only supports stored (uncompressed) entries — compressed DOCX files will fail gracefully.
    private static func findFileInZip(data: Data, name: String) -> Data? {
        let bytes = [UInt8](data)
        let nameBytes = [UInt8](name.utf8)
        let signature: [UInt8] = [0x50, 0x4B, 0x03, 0x04] // PK local file header

        var offset = 0
        while offset + 30 < bytes.count {
            // Find next local file header
            guard bytes[offset] == signature[0],
                  bytes[offset + 1] == signature[1],
                  bytes[offset + 2] == signature[2],
                  bytes[offset + 3] == signature[3] else {
                offset += 1
                continue
            }

            let compressionMethod = UInt16(bytes[offset + 8]) | (UInt16(bytes[offset + 9]) << 8)
            let compressedSize = Int(UInt32(bytes[offset + 18]) | (UInt32(bytes[offset + 19]) << 8) |
                                     (UInt32(bytes[offset + 20]) << 16) | (UInt32(bytes[offset + 21]) << 24))
            let nameLength = Int(UInt16(bytes[offset + 26]) | (UInt16(bytes[offset + 27]) << 8))
            let extraLength = Int(UInt16(bytes[offset + 28]) | (UInt16(bytes[offset + 29]) << 8))

            let nameStart = offset + 30
            let nameEnd = nameStart + nameLength
            guard nameEnd <= bytes.count else { return nil }

            let entryName = Array(bytes[nameStart..<nameEnd])
            let dataStart = nameEnd + extraLength

            if entryName == nameBytes {
                // Only support stored (uncompressed) entries
                guard compressionMethod == 0 else { return nil }
                let dataEnd = dataStart + compressedSize
                guard dataEnd <= bytes.count else { return nil }
                return Data(bytes[dataStart..<dataEnd])
            }

            // Skip to next entry
            offset = dataStart + compressedSize
        }
        return nil
    }

    static func titleFromFilename(_ url: URL) -> String {
        url.deletingPathExtension().lastPathComponent
    }
}
