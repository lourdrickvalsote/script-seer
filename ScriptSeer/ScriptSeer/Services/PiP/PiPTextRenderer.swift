import UIKit
import AVFoundation
import CoreMedia
import CoreVideo

struct PiPTextRenderer {

    private var cachedAttributedString: NSAttributedString?
    private var cachedContent: String = ""
    private var cachedTextSize: CGFloat = 0
    private var cachedLineSpacing: CGFloat = 0
    private var cachedFrameWidth: CGFloat = 0
    private var cachedHorizontalMargin: CGFloat = 0
    private var cachedTextColor: UIColor = .white
    private var cachedIsMirrored: Bool = false
    private var cachedWordIndex: Int? = nil
    private var cachedMeasuredHeight: CGFloat = 0

    private var bufferPool: CVPixelBufferPool?
    private var poolWidth: Int = 0
    private var poolHeight: Int = 0

    mutating func renderFrame(
        content: String,
        scrollOffset: CGFloat,
        frameSize: CGSize,
        textSize: CGFloat,
        lineSpacing: CGFloat,
        horizontalMargin: CGFloat,
        textColor: UIColor,
        backgroundColor: UIColor,
        isMirrored: Bool,
        currentWordIndex: Int?
    ) -> CMSampleBuffer? {
        let width = Int(frameSize.width)
        let height = Int(frameSize.height)
        guard width > 0, height > 0 else { return nil }

        // Rebuild attributed string cache if inputs changed
        let needsRebuild = content != cachedContent
            || textSize != cachedTextSize
            || lineSpacing != cachedLineSpacing
            || frameSize.width != cachedFrameWidth
            || horizontalMargin != cachedHorizontalMargin
            || textColor != cachedTextColor
            || isMirrored != cachedIsMirrored
            || currentWordIndex != cachedWordIndex

        if needsRebuild {
            cachedContent = content
            cachedTextSize = textSize
            cachedLineSpacing = lineSpacing
            cachedFrameWidth = frameSize.width
            cachedHorizontalMargin = horizontalMargin
            cachedTextColor = textColor
            cachedIsMirrored = isMirrored
            cachedWordIndex = currentWordIndex
            cachedAttributedString = buildAttributedString(
                content: content,
                textSize: textSize,
                lineSpacing: lineSpacing,
                frameWidth: frameSize.width,
                horizontalMargin: horizontalMargin,
                textColor: textColor,
                currentWordIndex: currentWordIndex
            )
            // Measure full height
            if let attrStr = cachedAttributedString {
                let drawWidth = frameSize.width - horizontalMargin * 2
                let boundingRect = attrStr.boundingRect(
                    with: CGSize(width: drawWidth, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    context: nil
                )
                cachedMeasuredHeight = boundingRect.height
            }
        }

        guard let attributedString = cachedAttributedString else { return nil }

        // Ensure pixel buffer pool matches current size
        if bufferPool == nil || poolWidth != width || poolHeight != height {
            bufferPool = createPool(width: width, height: height)
            poolWidth = width
            poolHeight = height
        }

        guard let pool = bufferPool else { return nil }

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else { return nil }

        // Fill background
        context.setFillColor(backgroundColor.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Mirror if needed
        if isMirrored {
            context.translateBy(x: CGFloat(width), y: 0)
            context.scaleBy(x: -1, y: 1)
        }

        // Flip coordinate system for text drawing (Core Graphics is bottom-up)
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)

        // Draw text at scroll offset
        let drawWidth = frameSize.width - horizontalMargin * 2
        let topPadding = frameSize.height / 2 // Match TeleprompterView's center start
        let yOffset = topPadding - scrollOffset

        UIGraphicsPushContext(context)
        attributedString.draw(in: CGRect(
            x: horizontalMargin,
            y: yOffset,
            width: drawWidth,
            height: cachedMeasuredHeight + frameSize.height
        ))
        UIGraphicsPopContext()

        return createSampleBuffer(from: buffer)
    }

    var measuredContentHeight: CGFloat { cachedMeasuredHeight }

    // MARK: - Attributed String

    private func buildAttributedString(
        content: String,
        textSize: CGFloat,
        lineSpacing: CGFloat,
        frameWidth: CGFloat,
        horizontalMargin: CGFloat,
        textColor: UIColor,
        currentWordIndex: Int?
    ) -> NSAttributedString {
        let pipTextSize = max(18, textSize)
        let font = UIFont.systemFont(ofSize: pipTextSize, weight: .medium)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing

        // If speech follow highlighting is active, color words individually
        if let wordIdx = currentWordIndex {
            return buildHighlightedString(
                content: content,
                font: font,
                paragraphStyle: paragraphStyle,
                textColor: textColor,
                currentWordIndex: wordIdx
            )
        }

        return NSAttributedString(string: content, attributes: [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle
        ])
    }

    private func buildHighlightedString(
        content: String,
        font: UIFont,
        paragraphStyle: NSParagraphStyle,
        textColor: UIColor,
        currentWordIndex: Int
    ) -> NSAttributedString {
        let boldFont = UIFont.systemFont(ofSize: font.pointSize, weight: .bold)
        let pastColor = textColor.withAlphaComponent(0.4)
        let futureColor = textColor.withAlphaComponent(0.7)

        let result = NSMutableAttributedString()
        let words = content.components(separatedBy: .whitespacesAndNewlines)
        var wordCounter = 0

        for (i, word) in words.enumerated() {
            if i > 0 {
                result.append(NSAttributedString(string: " "))
            }
            guard !word.trimmingCharacters(in: .whitespaces).isEmpty else {
                result.append(NSAttributedString(string: word))
                continue
            }

            let color: UIColor
            let wordFont: UIFont
            if wordCounter < currentWordIndex {
                color = pastColor
                wordFont = font
            } else if wordCounter == currentWordIndex {
                color = textColor
                wordFont = boldFont
            } else {
                color = futureColor
                wordFont = font
            }

            result.append(NSAttributedString(string: word, attributes: [
                .font: wordFont,
                .foregroundColor: color,
                .paragraphStyle: paragraphStyle
            ]))
            wordCounter += 1
        }

        return result
    }

    // MARK: - Pixel Buffer Pool

    private func createPool(width: Int, height: Int) -> CVPixelBufferPool? {
        let attrs: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:] as [String: Any]
        ]
        let poolAttrs: [String: Any] = [
            kCVPixelBufferPoolMinimumBufferCountKey as String: 4
        ]
        var pool: CVPixelBufferPool?
        CVPixelBufferPoolCreate(nil, poolAttrs as CFDictionary, attrs as CFDictionary, &pool)
        return pool
    }

    // MARK: - Sample Buffer

    private func createSampleBuffer(from pixelBuffer: CVPixelBuffer) -> CMSampleBuffer? {
        var formatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: nil,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDescription
        )
        guard let format = formatDescription else { return nil }

        var timingInfo = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: 30),
            presentationTimeStamp: CMClockGetTime(CMClockGetHostTimeClock()),
            decodeTimeStamp: .invalid
        )

        var sampleBuffer: CMSampleBuffer?
        CMSampleBufferCreateReadyWithImageBuffer(
            allocator: nil,
            imageBuffer: pixelBuffer,
            formatDescription: format,
            sampleTiming: &timingInfo,
            sampleBufferOut: &sampleBuffer
        )
        return sampleBuffer
    }
}
