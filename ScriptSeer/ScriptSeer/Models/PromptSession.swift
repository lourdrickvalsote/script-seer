import Foundation
import SwiftUI

enum PromptSessionState {
    case idle
    case countdown
    case prompting
    case paused
    case completed
}

enum ScrollMode: String, CaseIterable {
    case manual = "Manual"
    case timed = "Timed"
}

enum PromptDisplayMode: String, CaseIterable {
    case paragraph = "Paragraph"
    case twoLine = "Two Line"
    case oneLine = "One Line"
    case chunk = "Chunk"
}

enum PromptTheme: String, CaseIterable {
    case lightOnDark = "Light on Dark"
    case darkOnLight = "Dark on Light"
    case greenOnBlack = "Green on Black"
    case yellowOnDark = "Yellow on Dark"

    var textColor: Color {
        switch self {
        case .lightOnDark: SSColors.lavenderMist
        case .darkOnLight: SSColors.darkForest
        case .greenOnBlack: Color(red: 0.3, green: 1.0, blue: 0.3)
        case .yellowOnDark: Color(red: 1.0, green: 0.95, blue: 0.6)
        }
    }

    var backgroundColor: Color {
        switch self {
        case .lightOnDark: SSColors.darkForest
        case .darkOnLight: SSColors.lavenderMist
        case .greenOnBlack: .black
        case .yellowOnDark: Color(red: 20/255, green: 26/255, blue: 20/255)
        }
    }
}

@Observable
final class PromptSession {
    var state: PromptSessionState = .idle
    var scrollSpeed: Double = 40 // points per second
    var textSize: CGFloat = 32
    var lineSpacing: CGFloat = 16
    var horizontalMargin: CGFloat = 24
    var isMirrored: Bool = false
    var displayMode: PromptDisplayMode = .paragraph
    var theme: PromptTheme = .lightOnDark
    var countdownSeconds: Int = 3
    var scrollOffset: CGFloat = 0
    var showTuneControls: Bool = false
    var scrollMode: ScrollMode = .manual
    var targetDurationMinutes: Double = 2.0 // for timed mode
    var measuredContentHeight: CGFloat = 0 // set by view after layout
    var hookModeEnabled: Bool = false
    var hookLineCount: Int = 3

    let script: Script
    let totalContentHeight: CGFloat

    init(script: Script, totalContentHeight: CGFloat = 0) {
        self.script = script
        self.totalContentHeight = totalContentHeight
        self.isMirrored = script.isMirrorDefault
        // Default target duration from estimated reading time
        self.targetDurationMinutes = max(0.5, script.estimatedDuration / 60.0)
    }

    /// Calculated speed for timed mode (points per second to finish in target duration)
    var timedScrollSpeed: Double {
        guard measuredContentHeight > 0, targetDurationMinutes > 0 else {
            return scrollSpeed
        }
        let targetSeconds = targetDurationMinutes * 60.0
        return Double(measuredContentHeight) / targetSeconds
    }

    /// The effective scroll speed considering the current mode
    var effectiveScrollSpeed: Double {
        scrollMode == .timed ? timedScrollSpeed : scrollSpeed
    }

    func start() {
        state = .countdown
    }

    func play() {
        state = .prompting
    }

    func pause() {
        state = .paused
    }

    func togglePlayPause() {
        if state == .prompting {
            pause()
        } else if state == .paused || state == .idle {
            play()
        }
    }

    func jumpBack(points: CGFloat = 200) {
        scrollOffset = max(0, scrollOffset - points)
    }

    func jumpForward(points: CGFloat = 200) {
        scrollOffset += points
    }

    /// Scrub progress (0.0 to 1.0)
    var scrollProgress: Double {
        get {
            guard measuredContentHeight > 0 else { return 0 }
            return min(1.0, Double(scrollOffset) / Double(measuredContentHeight))
        }
        set {
            guard measuredContentHeight > 0 else { return }
            scrollOffset = CGFloat(newValue) * measuredContentHeight
        }
    }

    /// Section titles (paragraphs) with their approximate scroll offsets
    var sections: [(title: String, progress: Double)] {
        let paragraphs = script.content
            .components(separatedBy: "\n\n")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard paragraphs.count > 1 else { return [] }

        let totalChars = Double(script.content.count)
        var charOffset: Double = 0

        return paragraphs.enumerated().map { index, paragraph in
            let progress = charOffset / totalChars
            charOffset += Double(paragraph.count) + 2 // +2 for \n\n
            let preview = String(paragraph.trimmingCharacters(in: .whitespacesAndNewlines).prefix(40))
            return (title: "§\(index + 1): \(preview)…", progress: progress)
        }
    }

    func complete() {
        state = .completed
    }
}
