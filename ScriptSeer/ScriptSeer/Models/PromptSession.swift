import Foundation
import SwiftUI

enum PromptSessionState {
    case idle
    case countdown
    case prompting
    case paused
    case completed
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
        case .lightOnDark: .white
        case .darkOnLight: .black
        case .greenOnBlack: Color(red: 0.3, green: 1.0, blue: 0.3)
        case .yellowOnDark: Color(red: 1.0, green: 0.95, blue: 0.6)
        }
    }

    var backgroundColor: Color {
        switch self {
        case .lightOnDark: Color(red: 0.05, green: 0.05, blue: 0.06)
        case .darkOnLight: Color(white: 0.95)
        case .greenOnBlack: .black
        case .yellowOnDark: Color(red: 0.08, green: 0.08, blue: 0.10)
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

    let script: Script
    let totalContentHeight: CGFloat

    init(script: Script, totalContentHeight: CGFloat = 0) {
        self.script = script
        self.totalContentHeight = totalContentHeight
        self.isMirrored = script.isMirrorDefault
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

    func complete() {
        state = .completed
    }
}
