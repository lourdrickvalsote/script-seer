import Foundation

enum RemoteAction: String, CaseIterable, Codable {
    case playPause
    case jumpBack
    case jumpForward
    case speedUp
    case speedDown
    case markStumble
    case nextLine
    case toggleRecording

    var displayName: String {
        switch self {
        case .playPause: "Play / Pause"
        case .jumpBack: "Jump Back"
        case .jumpForward: "Jump Forward"
        case .speedUp: "Speed Up"
        case .speedDown: "Speed Down"
        case .markStumble: "Mark Stumble"
        case .nextLine: "Next Line"
        case .toggleRecording: "Toggle Recording"
        }
    }

    var systemImage: String {
        switch self {
        case .playPause: "playpause.fill"
        case .jumpBack: "backward.fill"
        case .jumpForward: "forward.fill"
        case .speedUp: "gauge.with.dots.needle.100percent"
        case .speedDown: "gauge.with.dots.needle.33percent"
        case .markStumble: "exclamationmark.triangle"
        case .nextLine: "text.line.first.and.arrowtriangle.forward"
        case .toggleRecording: "record.circle"
        }
    }
}
