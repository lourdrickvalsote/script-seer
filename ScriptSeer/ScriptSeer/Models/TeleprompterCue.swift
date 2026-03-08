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
    struct Segment: Identifiable {
        let id = UUID()
        let content: String
        let cue: TeleprompterCueType?

        var isText: Bool { cue == nil }
    }

    static func parse(_ text: String) -> [Segment] {
        var segments: [Segment] = []
        var remaining = text

        while !remaining.isEmpty {
            // Find the next cue marker
            var earliestRange: Range<String.Index>?
            var earliestCue: TeleprompterCueType?

            for cueType in TeleprompterCueType.allCases {
                if let range = remaining.range(of: cueType.rawValue) {
                    if earliestRange == nil || range.lowerBound < earliestRange!.lowerBound {
                        earliestRange = range
                        earliestCue = cueType
                    }
                }
            }

            if let range = earliestRange, let cue = earliestCue {
                // Add text before the cue
                let textBefore = String(remaining[remaining.startIndex..<range.lowerBound])
                if !textBefore.trimmingCharacters(in: .whitespaces).isEmpty {
                    segments.append(Segment(content: textBefore, cue: nil))
                }
                // Add the cue
                segments.append(Segment(content: cue.displaySymbol, cue: cue))
                remaining = String(remaining[range.upperBound...])
            } else {
                // No more cues, add remaining text
                if !remaining.trimmingCharacters(in: .whitespaces).isEmpty {
                    segments.append(Segment(content: remaining, cue: nil))
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
        // Clean up extra spaces
        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
