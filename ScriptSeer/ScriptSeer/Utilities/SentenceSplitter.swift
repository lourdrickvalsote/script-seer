import Foundation

/// Splits text into sentences for display purposes.
/// Does not modify the original script content.
func splitIntoSentences(_ text: String) -> [String] {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return [] }

    // Common abbreviations that end with a period but aren't sentence endings
    let abbreviations: Set<String> = [
        "mr", "mrs", "ms", "dr", "prof", "sr", "jr",
        "st", "ave", "blvd", "dept", "est", "govt",
        "inc", "ltd", "corp", "vs", "etc", "approx",
        "gen", "sgt", "cpl", "pvt", "capt", "col",
        "fig", "vol", "no", "op"
    ]

    // Split on sentence-ending punctuation followed by whitespace or end of string
    // Keeps the punctuation with the preceding sentence
    var sentences: [String] = []
    var current = ""
    let chars = Array(trimmed)
    var i = 0

    while i < chars.count {
        let char = chars[i]
        current.append(char)

        // Check for ellipsis — don't split on "..."
        if char == "." && i + 2 < chars.count && chars[i + 1] == "." && chars[i + 2] == "." {
            current.append(chars[i + 1])
            current.append(chars[i + 2])
            i += 3
            continue
        }

        // Check for sentence-ending punctuation
        if char == "." || char == "!" || char == "?" {
            // Look ahead: must be followed by whitespace (or end of string) to be a sentence break
            let isEnd = (i + 1 >= chars.count) || chars[i + 1].isWhitespace

            if isEnd && char == "." {
                // Check if this is an abbreviation
                let wordBeforeDot = current.dropLast()
                    .split(separator: " ")
                    .last
                    .map { String($0).lowercased().trimmingCharacters(in: .punctuationCharacters) } ?? ""
                if abbreviations.contains(wordBeforeDot) {
                    i += 1
                    continue
                }
            }

            if isEnd {
                let sentence = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !sentence.isEmpty {
                    sentences.append(sentence)
                }
                current = ""
                // Skip whitespace after punctuation
                i += 1
                while i < chars.count && chars[i].isWhitespace {
                    i += 1
                }
                continue
            }
        }

        i += 1
    }

    // Append any remaining text
    let remaining = current.trimmingCharacters(in: .whitespacesAndNewlines)
    if !remaining.isEmpty {
        sentences.append(remaining)
    }

    return sentences.isEmpty ? [trimmed] : sentences
}
