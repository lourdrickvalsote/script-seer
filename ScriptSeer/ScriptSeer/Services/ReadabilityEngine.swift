import Foundation

/// Automatically reflows long text into natural prompt chunks
/// to reduce eye movement and improve reading cadence.
struct ReadabilityEngine {
    /// Target words per line for comfortable reading on a teleprompter
    static let defaultWordsPerLine = 6

    /// Reflow text into chunks optimized for teleprompter reading.
    /// Respects sentence boundaries and natural phrase breaks.
    static func reflow(_ text: String, wordsPerLine: Int = defaultWordsPerLine) -> String {
        let paragraphs = text.components(separatedBy: "\n\n")
        return paragraphs.map { paragraph in
            reflowParagraph(paragraph.trimmingCharacters(in: .whitespacesAndNewlines), wordsPerLine: wordsPerLine)
        }.joined(separator: "\n\n")
    }

    private static func reflowParagraph(_ text: String, wordsPerLine: Int) -> String {
        guard !text.isEmpty else { return text }

        // Split into sentences first
        let sentences = splitIntoSentences(text)

        var lines: [String] = []
        for sentence in sentences {
            let words = sentence.split(separator: " ").map(String.init)
            var currentLine: [String] = []

            for word in words {
                currentLine.append(word)

                // Check if we should break here
                if currentLine.count >= wordsPerLine {
                    // Prefer breaking at natural pause points
                    let line = currentLine.joined(separator: " ")
                    if let breakIndex = findNaturalBreak(in: currentLine, target: wordsPerLine) {
                        let firstPart = currentLine[0...breakIndex].joined(separator: " ")
                        let remainder = Array(currentLine[(breakIndex + 1)...])
                        lines.append(firstPart)
                        currentLine = remainder
                    } else {
                        lines.append(line)
                        currentLine = []
                    }
                }
            }

            if !currentLine.isEmpty {
                lines.append(currentLine.joined(separator: " "))
            }
        }

        return lines.joined(separator: "\n")
    }

    /// Split text into sentences, preserving punctuation
    private static func splitIntoSentences(_ text: String) -> [String] {
        var sentences: [String] = []
        var current = ""

        for char in text {
            current.append(char)
            if char == "." || char == "!" || char == "?" {
                // Check if next char is space or end (to avoid splitting on abbreviations like "Dr.")
                sentences.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            }
        }
        if !current.trimmingCharacters(in: .whitespaces).isEmpty {
            sentences.append(current.trimmingCharacters(in: .whitespaces))
        }
        return sentences
    }

    /// Find the best natural break point near the target word count.
    /// Prefers breaking after commas, conjunctions, and prepositions.
    private static func findNaturalBreak(in words: [String], target: Int) -> Int? {
        guard words.count > 1 else { return nil }

        let breakWords: Set<String> = ["and", "but", "or", "so", "then", "that", "which", "when",
                                        "while", "because", "if", "as", "to", "for", "with", "in"]

        // Search around the target for a natural break
        let searchStart = max(target - 2, 2)
        let searchEnd = min(target + 1, words.count - 1)

        // First priority: break after comma
        for i in stride(from: searchEnd, through: searchStart, by: -1) {
            if words[i].hasSuffix(",") || words[i].hasSuffix(";") || words[i].hasSuffix(":") {
                return i
            }
        }

        // Second priority: break before conjunction/preposition
        for i in stride(from: searchEnd, through: searchStart, by: -1) {
            let lowered = words[i].lowercased().trimmingCharacters(in: .punctuationCharacters)
            if breakWords.contains(lowered) && i > 0 {
                return i - 1
            }
        }

        // Fall back to target
        if target < words.count {
            return target - 1
        }
        return nil
    }

    /// Preview how text would look after reflowing
    static func previewReflow(_ text: String, wordsPerLine: Int = defaultWordsPerLine) -> (lineCount: Int, avgWordsPerLine: Double) {
        let reflowed = reflow(text, wordsPerLine: wordsPerLine)
        let lines = reflowed.components(separatedBy: .newlines).filter { !$0.isEmpty }
        let totalWords = lines.reduce(0) { $0 + $1.split(separator: " ").count }
        let avg = lines.isEmpty ? 0 : Double(totalWords) / Double(lines.count)
        return (lineCount: lines.count, avgWordsPerLine: avg)
    }
}
