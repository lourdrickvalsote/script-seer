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
    static let supportedTypes: [UTType] = [.plainText, .rtf, .pdf, UTType("org.openxmlformats.wordprocessingml.document")].compactMap { $0 }

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
        } else if let docxType = UTType("org.openxmlformats.wordprocessingml.document"),
                  utType.conforms(to: docxType) {
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
        // DOCX is a ZIP archive; extract word/document.xml and strip XML tags
        guard let data = try? Data(contentsOf: url) else {
            throw ImportError.fileReadFailed
        }

        // Find word/document.xml in the ZIP archive
        guard let xmlString = extractFileFromZIP(data: data, filename: "word/document.xml") else {
            throw ImportError.textExtractionFailed
        }

        // Convert XML paragraph boundaries to newlines, then strip all tags
        let text = xmlString
            .replacingOccurrences(of: "</w:p>", with: "\n")
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&apos;", with: "'")
        return text
    }

    private static func extractFileFromZIP(data: Data, filename: String) -> String? {
        // Minimal ZIP local file header parser
        var offset = 0
        let bytes = [UInt8](data)
        while offset + 30 < bytes.count {
            // Local file header signature: 0x04034b50
            guard bytes[offset] == 0x50, bytes[offset+1] == 0x4b,
                  bytes[offset+2] == 0x03, bytes[offset+3] == 0x04 else { break }

            let compressedSize = Int(bytes[offset+18]) | (Int(bytes[offset+19]) << 8) |
                                 (Int(bytes[offset+20]) << 16) | (Int(bytes[offset+21]) << 24)
            let uncompressedSize = Int(bytes[offset+22]) | (Int(bytes[offset+23]) << 8) |
                                   (Int(bytes[offset+24]) << 16) | (Int(bytes[offset+25]) << 24)
            let nameLen = Int(bytes[offset+26]) | (Int(bytes[offset+27]) << 8)
            let extraLen = Int(bytes[offset+28]) | (Int(bytes[offset+29]) << 8)
            let compressionMethod = Int(bytes[offset+8]) | (Int(bytes[offset+9]) << 8)

            let nameStart = offset + 30
            let nameEnd = nameStart + nameLen
            guard nameEnd <= bytes.count else { break }
            let name = String(bytes: bytes[nameStart..<nameEnd], encoding: .utf8) ?? ""

            let dataStart = nameEnd + extraLen
            let dataEnd = dataStart + compressedSize

            if name == filename {
                guard dataEnd <= bytes.count else { return nil }
                let fileData = Data(bytes[dataStart..<dataEnd])
                if compressionMethod == 0 {
                    // Stored (uncompressed)
                    return String(data: fileData, encoding: .utf8)
                } else if compressionMethod == 8 {
                    // Deflated — use Foundation's decompression
                    let decompressed = try? (fileData as NSData).decompressed(using: .zlib) as Data
                    return decompressed.flatMap { String(data: $0, encoding: .utf8) }
                }
                return nil
            }

            offset = dataEnd
        }
        return nil
    }

    static func titleFromFilename(_ url: URL) -> String {
        url.deletingPathExtension().lastPathComponent
    }
}
