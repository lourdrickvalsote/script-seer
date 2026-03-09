import Foundation

@Observable
final class PracticeSession {
    var startTime: Date?
    var endTime: Date?
    var stumbles: [StumbleMarker] = []
    var isActive: Bool = false
    var currentLineIndex: Int = 0
    var usedSpeechFollow: Bool = false

    let script: Script
    let contentOverride: String?
    let lines: [String]

    var content: String { contentOverride ?? script.content }

    // Cumulative word counts for mapping word index → line index
    let lineWordRanges: [(start: Int, end: Int)]

    var totalWordCount: Int {
        lineWordRanges.last?.end ?? 0
    }

    init(script: Script, contentOverride: String? = nil) {
        self.script = script
        self.contentOverride = contentOverride
        self.lines = splitIntoSentences(contentOverride ?? script.content)

        // Build cumulative word ranges per line
        var ranges: [(start: Int, end: Int)] = []
        var cumulative = 0
        for line in self.lines {
            let wordCount = line.split(separator: " ").count
            ranges.append((start: cumulative, end: cumulative + wordCount))
            cumulative += wordCount
        }
        self.lineWordRanges = ranges
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

    func startFrom(line index: Int) {
        startTime = Date()
        endTime = nil
        stumbles = []
        currentLineIndex = max(0, min(index, lines.count - 1))
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
            timestamp: Date(),
            isAutoDetected: false
        )
        stumbles.append(marker)
    }

    /// Auto-mark stumble with dedup (won't re-mark same line within 5 seconds)
    func autoMarkStumble(atLine lineIndex: Int) {
        guard lineIndex < lines.count else { return }
        let now = Date()
        let recentOnSameLine = stumbles.contains { marker in
            marker.lineIndex == lineIndex && now.timeIntervalSince(marker.timestamp) < 5.0
        }
        guard !recentOnSameLine else { return }

        let marker = StumbleMarker(
            lineIndex: lineIndex,
            lineText: lines[lineIndex],
            timestamp: now,
            isAutoDetected: true
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

    /// Map a word index from SpeechFollowEngine to a line index
    func lineIndex(forWordIndex wordIndex: Int) -> Int? {
        for (i, range) in lineWordRanges.enumerated() {
            if wordIndex >= range.start && wordIndex < range.end {
                return i
            }
        }
        return nil
    }
}

struct StumbleMarker: Identifiable {
    let id = UUID()
    let lineIndex: Int
    let lineText: String
    let timestamp: Date
    var isAutoDetected: Bool = false
}
