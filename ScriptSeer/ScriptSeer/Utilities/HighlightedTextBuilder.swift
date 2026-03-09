import SwiftUI

/// A view that renders per-word karaoke-style highlighting, only recomputing
/// the AttributedString when its inputs actually change.
struct HighlightedTextView: View, Equatable {
    let content: String
    let globalWordIndex: Int
    let globalWordOffset: Int
    var currentColor: Color = .white
    var pastColor: Color = .white.opacity(0.4)
    var futureColor: Color = .white.opacity(0.7)
    var fontSize: CGFloat = 24
    var fontWeight: Font.Weight = .medium

    var body: some View {
        buildText()
    }

    private func buildText() -> Text {
        let words = content.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        guard !words.isEmpty else {
            return Text(content)
                .font(.system(size: fontSize, weight: fontWeight))
                .foregroundColor(futureColor)
        }

        var attributed = AttributedString()
        for (i, word) in words.enumerated() {
            if i > 0 {
                attributed.append(AttributedString(" "))
            }
            let globalIdx = globalWordOffset + i
            var wordAttr = AttributedString(word)
            let isCurrent = globalIdx == globalWordIndex

            if globalIdx < globalWordIndex {
                wordAttr.foregroundColor = pastColor
            } else if isCurrent {
                wordAttr.foregroundColor = currentColor
            } else {
                wordAttr.foregroundColor = futureColor
            }

            wordAttr.font = .system(size: fontSize, weight: isCurrent ? .bold : fontWeight)
            attributed.append(wordAttr)
        }

        return Text(attributed)
    }

    static func == (lhs: HighlightedTextView, rhs: HighlightedTextView) -> Bool {
        lhs.content == rhs.content &&
        lhs.globalWordIndex == rhs.globalWordIndex &&
        lhs.globalWordOffset == rhs.globalWordOffset &&
        lhs.fontSize == rhs.fontSize
    }
}

/// Convenience wrapper that returns the equatable view for drop-in replacement.
func highlightedText(
    content: String,
    globalWordIndex: Int,
    globalWordOffset: Int,
    currentColor: Color = .white,
    pastColor: Color = .white.opacity(0.4),
    futureColor: Color = .white.opacity(0.7),
    fontSize: CGFloat = 24,
    fontWeight: Font.Weight = .medium
) -> some View {
    HighlightedTextView(
        content: content,
        globalWordIndex: globalWordIndex,
        globalWordOffset: globalWordOffset,
        currentColor: currentColor,
        pastColor: pastColor,
        futureColor: futureColor,
        fontSize: fontSize,
        fontWeight: fontWeight
    )
    .equatable()
}
