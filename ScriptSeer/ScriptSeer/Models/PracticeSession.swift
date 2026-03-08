import Foundation

@Observable
final class PracticeSession {
    var startTime: Date?
    var endTime: Date?
    var stumbles: [StumbleMarker] = []
    var isActive: Bool = false
    var currentLineIndex: Int = 0

    let script: Script
    let lines: [String]

    init(script: Script) {
        self.script = script
        self.lines = script.content
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    var elapsedTime: TimeInterval {
        guard let start = startTime else { return 0 }
        let end = endTime ?? Date()
        return end.timeIntervalSince(start)
    }

    var formattedElapsedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var wordsPerMinute: Double {
        guard elapsedTime > 0 else { return 0 }
        return Double(script.wordCount) / (elapsedTime / 60.0)
    }

    var paceDescription: String {
        let wpm = wordsPerMinute
        if wpm < 120 { return "Slow — take your time" }
        if wpm < 160 { return "Natural pace" }
        if wpm < 200 { return "Brisk — consider slowing down" }
        return "Very fast"
    }

    func start() {
        startTime = Date()
        endTime = nil
        stumbles = []
        currentLineIndex = 0
        isActive = true
    }

    func finish() {
        endTime = Date()
        isActive = false
    }

    func markStumble() {
        guard currentLineIndex < lines.count else { return }
        let marker = StumbleMarker(
            lineIndex: currentLineIndex,
            lineText: lines[currentLineIndex],
            timestamp: Date()
        )
        stumbles.append(marker)
    }

    func advanceLine() {
        if currentLineIndex < lines.count - 1 {
            currentLineIndex += 1
        }
    }

    func goToLine(_ index: Int) {
        guard index >= 0, index < lines.count else { return }
        currentLineIndex = index
    }
}

struct StumbleMarker: Identifiable {
    let id = UUID()
    let lineIndex: Int
    let lineText: String
    let timestamp: Date
}
