import SwiftUI

enum GlancePreset: String, CaseIterable {
    case selfie = "Selfie"
    case webinar = "Webinar"
    case speech = "Speech"
    case audition = "Audition"

    var description: String {
        switch self {
        case .selfie: "Compact text near front camera"
        case .webinar: "Wider text, moderate offset"
        case .speech: "Large text, centered"
        case .audition: "Minimal text, tight focus"
        }
    }

    var textSize: CGFloat {
        switch self {
        case .selfie: 24
        case .webinar: 28
        case .speech: 36
        case .audition: 22
        }
    }

    var verticalOffset: CGFloat {
        switch self {
        case .selfie: 0.1
        case .webinar: 0.25
        case .speech: 0.35
        case .audition: 0.15
        }
    }

    var horizontalMargin: CGFloat {
        switch self {
        case .selfie: 40
        case .webinar: 32
        case .speech: 24
        case .audition: 48
        }
    }

    var wordsPerChunk: Int {
        switch self {
        case .selfie: 5
        case .webinar: 8
        case .speech: 12
        case .audition: 4
        }
    }

    var lineSpacing: CGFloat {
        switch self {
        case .selfie: 12
        case .webinar: 16
        case .speech: 20
        case .audition: 10
        }
    }
}

@Observable
final class FocusWindowConfig {
    var isEnabled: Bool = false
    var verticalOffset: CGFloat = 0.2 // 0 = top, 1 = bottom
    var contextLinesBefore: Int = 1
    var contextLinesAfter: Int = 2
    var preset: GlancePreset = .selfie
    var highlightCurrent: Bool = true
    var deemphasizePastFuture: Bool = true

    func applyPreset(_ preset: GlancePreset) {
        self.preset = preset
    }
}
