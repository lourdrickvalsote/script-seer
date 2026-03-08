import Foundation
import SwiftUI

enum TeleprompterCueType: String, CaseIterable {
    case pause = "[PAUSE]"
    case emphasis = "[EMPHASIS]"
    case sectionBreak = "[BREAK]"
    case breathe = "[BREATHE]"
    case slowDown = "[SLOW]"
    case smile = "[SMILE]"
    case punchline = "[PUNCHLINE]"
    case sincerity = "[SINCERE]"
    case speedUp = "[FAST]"
    case lookUp = "[LOOK UP]"

    var displaySymbol: String {
        switch self {
        case .pause: "⏸"
        case .emphasis: "⚡"
        case .sectionBreak: "—"
        case .breathe: "💨"
        case .slowDown: "🐢"
        case .smile: "😊"
        case .punchline: "🎯"
        case .sincerity: "❤️"
        case .speedUp: "⚡️"
        case .lookUp: "👁️"
        }
    }

    var displayName: String {
        switch self {
        case .pause: "Pause"
        case .emphasis: "Emphasis"
        case .sectionBreak: "Section Break"
        case .breathe: "Breathe"
        case .slowDown: "Slow Down"
        case .smile: "Smile"
        case .punchline: "Punchline"
        case .sincerity: "Sincerity"
        case .speedUp: "Speed Up"
        case .lookUp: "Look Up"
        }
    }

    var promptColor: Color {
        switch self {
        case .pause, .breathe, .slowDown: SSColors.silverSage
        case .emphasis, .punchline, .speedUp: SSColors.crimson
        case .sectionBreak: SSColors.slate
        case .smile, .sincerity: SSColors.accent
        case .lookUp: SSColors.lavenderMist
        }
    }

    /// Category for grouping in the editor toolbar
    var category: CueCategory {
        switch self {
        case .pause, .breathe, .slowDown, .speedUp: .pacing
        case .emphasis, .punchline, .sincerity: .energy
        case .smile, .lookUp: .direction
        case .sectionBreak: .structure
        }
    }
}

enum CueCategory: String, CaseIterable {
    case pacing = "Pacing"
    case energy = "Energy"
    case direction = "Direction"
    case structure = "Structure"
}

/// Parses script content into segments of text and cues for rich rendering
struct CueParser {
    enum SegmentKind {
        case text
        case cue(TeleprompterCueType)
        case speaker(String)
        case section(String)
    }

    struct Segment: Identifiable {
        let id = UUID()
        let content: String
        let kind: SegmentKind

        var isText: Bool {
            if case .text = kind { return true }
            return false
        }

        // Backward compat
        var cue: TeleprompterCueType? {
            if case .cue(let c) = kind { return c }
            return nil
        }
    }

    static func parse(_ text: String) -> [Segment] {
        var segments: [Segment] = []
        var remaining = text

        while !remaining.isEmpty {
            // Find the next marker (cue, speaker label, or section divider)
            var earliestRange: Range<String.Index>?
            var earliestKind: SegmentKind?
            var earliestDisplay: String?

            // Check cue markers
            for cueType in TeleprompterCueType.allCases {
                if let range = remaining.range(of: cueType.rawValue) {
                    if earliestRange == nil || range.lowerBound < earliestRange!.lowerBound {
                        earliestRange = range
                        earliestKind = .cue(cueType)
                        earliestDisplay = cueType.displaySymbol
                    }
                }
            }

            // Check speaker labels
            let speakers = SpeakerLabel.extract(from: remaining)
            if let first = speakers.first {
                if earliestRange == nil || first.range.lowerBound < earliestRange!.lowerBound {
                    earliestRange = first.range
                    earliestKind = .speaker(first.name)
                    earliestDisplay = first.name
                }
            }

            // Check section dividers
            let sections = SectionDivider.extract(from: remaining)
            if let first = sections.first {
                if earliestRange == nil || first.range.lowerBound < earliestRange!.lowerBound {
                    earliestRange = first.range
                    earliestKind = .section(first.title)
                    earliestDisplay = first.title
                }
            }

            if let range = earliestRange, let kind = earliestKind, let display = earliestDisplay {
                let textBefore = String(remaining[remaining.startIndex..<range.lowerBound])
                if !textBefore.trimmingCharacters(in: .whitespaces).isEmpty {
                    segments.append(Segment(content: textBefore, kind: .text))
                }
                segments.append(Segment(content: display, kind: kind))
                remaining = String(remaining[range.upperBound...])
            } else {
                if !remaining.trimmingCharacters(in: .whitespaces).isEmpty {
                    segments.append(Segment(content: remaining, kind: .text))
                }
                break
            }
        }

        return segments
    }

    /// Strip all cue markers from text (for export/plain text)
    static func stripCues(_ text: String) -> String {
        var result = text
        for cueType in TeleprompterCueType.allCases {
            result = result.replacingOccurrences(of: cueType.rawValue, with: "")
        }
        // Strip speaker labels and section dividers
        result = result.replacingOccurrences(
            of: "\\[SPEAKER:\\s*[^\\]]+\\]",
            with: "",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: "\\[SECTION:\\s*[^\\]]+\\]",
            with: "",
            options: .regularExpression
        )
        // Clean up extra spaces
        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Speaker Labels & Section Dividers

struct SpeakerLabel {
    let name: String
    static let pattern = "\\[SPEAKER:\\s*([^\\]]+)\\]"
    private static let regex = try! NSRegularExpression(pattern: pattern)

    static func extract(from text: String) -> [(range: Range<String.Index>, name: String)] {
        let nsRange = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: nsRange).compactMap { match in
            guard let wholeRange = Range(match.range, in: text),
                  let nameRange = Range(match.range(at: 1), in: text) else { return nil }
            return (range: wholeRange, name: String(text[nameRange]).trimmingCharacters(in: .whitespaces))
        }
    }
}

struct SectionDivider {
    let title: String
    static let pattern = "\\[SECTION:\\s*([^\\]]+)\\]"
    private static let regex = try! NSRegularExpression(pattern: pattern)

    static func extract(from text: String) -> [(range: Range<String.Index>, title: String)] {
        let nsRange = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: nsRange).compactMap { match in
            guard let wholeRange = Range(match.range, in: text),
                  let titleRange = Range(match.range(at: 1), in: text) else { return nil }
            return (range: wholeRange, title: String(text[titleRange]).trimmingCharacters(in: .whitespaces))
        }
    }
}
