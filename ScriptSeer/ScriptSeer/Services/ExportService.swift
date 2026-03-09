import Foundation
import UIKit

/// Handles script export in various formats
struct ExportService {
    enum ExportFormat: String, CaseIterable {
        case plainText = "Plain Text"
        case withCues = "With Cues"
        case pdf = "PDF"

        var fileExtension: String {
            switch self {
            case .plainText, .withCues: "txt"
            case .pdf: "pdf"
            }
        }
    }

    /// Export script content in the specified format
    static func export(script: Script, format: ExportFormat) -> Data? {
        switch format {
        case .plainText:
            let clean = CueParser.stripCues(script.content)
            return clean.data(using: .utf8)
        case .withCues:
            return script.content.data(using: .utf8)
        case .pdf:
            return generatePDF(title: script.title, content: script.content)
        }
    }

    /// Generate a simple PDF from script content
    static func generatePDF(title: String, content: String) -> Data {
        let pageWidth: CGFloat = 612 // US Letter
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 72

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        return renderer.pdfData { context in
            let textWidth = pageWidth - margin * 2

            // Title attributes
            let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ]

            // Body attributes
            let bodyFont = UIFont.systemFont(ofSize: 14)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 6
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle
            ]

            let cleanContent = CueParser.stripCues(content)

            // Calculate how content fits on pages
            let titleRect = CGRect(x: margin, y: margin, width: textWidth, height: 40)
            let bodyStartY: CGFloat = margin + 60

            let bodyString = NSAttributedString(string: cleanContent, attributes: bodyAttributes)
            let frameSetter = CTFramesetterCreateWithAttributedString(bodyString)

            var currentOffset: CFIndex = 0
            let totalLength = bodyString.length
            var isFirstPage = true

            while currentOffset < totalLength {
                context.beginPage()

                let startY: CGFloat
                if isFirstPage {
                    // Draw title
                    let titleString = NSAttributedString(string: title, attributes: titleAttributes)
                    titleString.draw(in: titleRect)
                    startY = bodyStartY
                    isFirstPage = false
                } else {
                    startY = margin
                }
                let frameRect = CGRect(x: margin, y: startY, width: textWidth, height: pageHeight - startY - margin)

                // Use CoreText for proper pagination
                let path = CGPath(rect: frameRect, transform: nil)
                let frame = CTFramesetterCreateFrame(frameSetter, CFRange(location: currentOffset, length: 0), path, nil)
                let visibleRange = CTFrameGetVisibleStringRange(frame)

                // Draw text
                let ctx = context.cgContext
                ctx.saveGState()
                ctx.translateBy(x: 0, y: pageHeight)
                ctx.scaleBy(x: 1, y: -1)
                let flippedRect = CGRect(x: margin, y: margin, width: textWidth, height: pageHeight - startY - margin)
                let flippedPath = CGPath(rect: flippedRect, transform: nil)
                let flippedFrame = CTFramesetterCreateFrame(frameSetter, CFRange(location: currentOffset, length: 0), flippedPath, nil)
                CTFrameDraw(flippedFrame, ctx)
                ctx.restoreGState()

                currentOffset += visibleRange.length
                if visibleRange.length == 0 { break } // Safety
            }
        }
    }

    /// Create a temporary file URL for sharing
    static func createTempFile(script: Script, format: ExportFormat) throws -> URL {
        guard let data = export(script: script, format: format) else {
            throw ExportError.exportFailed
        }

        let sanitizedTitle = script.title
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        let fileName = "\(sanitizedTitle).\(format.fileExtension)"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        try data.write(to: url)
        return url
    }

    enum ExportError: LocalizedError {
        case exportFailed

        var errorDescription: String? {
            "Failed to generate the export file."
        }
    }
}
