import SwiftUI

/// Builds a Text view with per-word karaoke-style highlighting using AttributedString.
func highlightedText(
    content: String,
    globalWordIndex: Int,
    globalWordOffset: Int,
    currentColor: Color = .white,
    pastColor: Color = .white.opacity(0.4),
    futureColor: Color = .white.opacity(0.7),
    fontSize: CGFloat = 24,
    fontWeight: Font.Weight = .medium
) -> Text {
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
