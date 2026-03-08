import Foundation

enum TeleprompterCueType: String, CaseIterable {
    case pause = "[PAUSE]"
    case emphasis = "[EMPHASIS]"
    case sectionBreak = "[BREAK]"
    case breathe = "[BREATHE]"
    case slowDown = "[SLOW]"

    var displaySymbol: String {
        switch self {
        case .pause: "⏸"
        case .emphasis: "⚡"
        case .sectionBreak: "—"
        case .breathe: "💨"
        case .slowDown: "🐢"
        }
    }

    var displayName: String {
        switch self {
        case .pause: "Pause"
        case .emphasis: "Emphasis"
        case .sectionBreak: "Section Break"
        case .breathe: "Breathe"
        case .slowDown: "Slow Down"
        }
    }
}
