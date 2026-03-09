import Foundation
import Speech
import AVFoundation

enum SpeechFollowMode: String, CaseIterable {
    case strict = "Strict"
    case smart = "Smart"

    var description: String {
        switch self {
        case .strict: "Advances word-by-word. Best for precise reading."
        case .smart: "Tolerates filler words, pauses, and minor paraphrasing."
        }
    }
}

enum SpeechFollowState {
    case idle
    case listening
    case following
    case lowConfidence
    case manualAssist
    case stopped
}

@Observable
final class SpeechFollowEngine {
    var state: SpeechFollowState = .idle
    var mode: SpeechFollowMode = .smart
    var currentWordIndex: Int = 0
    var confidence: Float = 1.0
    var isAvailable: Bool = false
    var debugLog: [String] = []
    var showDebugOverlay: Bool = false

    // Confidence Scroll — adaptive speed from speaking pace
    var adaptiveSpeed: Double = 40.0 // current smoothed speed in pt/s
    var speakingWPM: Double = 0.0 // current estimated words per minute
    var isConfidenceScrollEnabled: Bool = false

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var scriptWords: [String] = []
    private let confidenceThreshold: Float = 0.4
    private let maxJumpDistance = 5 // max words to skip on weak confidence
    private var tapInstalled = false

    // Pace tracking
    private var wordTimestamps: [(index: Int, time: Date)] = []
    private var lastAdaptiveUpdate: Date = .distantPast
    private let paceWindowSize = 10 // words to average over
    private let speedDampingFactor = 0.15 // how quickly speed adjusts (0-1, lower = smoother)

    func prepare(scriptContent: String) {
        scriptWords = scriptContent
            .components(separatedBy: .whitespacesAndNewlines)
            .map { $0.lowercased().trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }
        currentWordIndex = 0
        confidence = 1.0
        debugLog(message: "Prepared with \(scriptWords.count) words")
    }

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                let authorized = status == .authorized
                DispatchQueue.main.async {
                    self.isAvailable = authorized
                }
                continuation.resume(returning: authorized)
            }
        }
    }

    func start() {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            state = .manualAssist
            debugLog(message: "Speech recognizer not available")
            return
        }

        do {
            try startRecognition()
            state = .listening
            debugLog(message: "Started listening in \(mode.rawValue) mode")
        } catch {
            state = .manualAssist
            debugLog(message: "Failed to start: \(error.localizedDescription)")
        }
    }

    func stop() {
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        if tapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        // Deactivate audio session so other audio can resume
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        state = .stopped
        debugLog(message: "Stopped")
    }

    private func startRecognition() throws {
        recognitionTask?.cancel()
        recognitionTask = nil

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = speechRecognizer?.supportsOnDeviceRecognition ?? false
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        tapInstalled = true

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let result {
                    self.processResult(result)
                }
                if error != nil || (result?.isFinal ?? false) {
                    // Guard against double-stop race with stop()
                    if self.recognitionRequest != nil {
                        self.recognitionRequest = nil
                        self.recognitionTask = nil
                        if self.tapInstalled {
                            inputNode.removeTap(onBus: 0)
                            self.tapInstalled = false
                        }
                        if self.audioEngine.isRunning {
                            self.audioEngine.stop()
                        }
                    }
                    if self.state == .listening || self.state == .following {
                        self.state = .lowConfidence
                        self.debugLog(message: "Recognition ended, falling back")
                    }
                }
            }
        }
    }

    private func processResult(_ result: SFSpeechRecognitionResult) {
        let spokenWords = result.bestTranscription.formattedString
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }

        guard !spokenWords.isEmpty else { return }

        // Update confidence from segments
        if let lastSegment = result.bestTranscription.segments.last {
            confidence = Float(lastSegment.confidence)
        }

        // Check confidence threshold
        if confidence < confidenceThreshold && confidence > 0 {
            if state != .lowConfidence {
                state = .lowConfidence
                debugLog(message: "Low confidence: \(String(format: "%.2f", confidence))")
            }
            return
        }

        state = .following

        switch mode {
        case .strict:
            advanceStrict(spokenWords: spokenWords)
        case .smart:
            advanceSmart(spokenWords: spokenWords)
        }
    }

    private func advanceStrict(spokenWords: [String]) {
        // Word-by-word matching
        for spoken in spokenWords.suffix(3) {
            let searchEnd = min(currentWordIndex + maxJumpDistance, scriptWords.count)
            for i in currentWordIndex..<searchEnd {
                if scriptWords[i] == spoken {
                    let newIndex = i + 1
                    if newIndex > currentWordIndex {
                        currentWordIndex = newIndex
                        recordWordAdvance(to: newIndex)
                        debugLog(message: "Strict: matched '\(spoken)' at \(i)")
                    }
                    break
                }
            }
        }
    }

    private func advanceSmart(spokenWords: [String]) {
        // Phrase-level fuzzy matching with tolerance for fillers and paraphrasing
        let recentSpoken = Array(spokenWords.suffix(5))
        let fillerWords: Set<String> = ["um", "uh", "like", "you know", "so", "well", "basically", "actually"]

        let filteredSpoken = recentSpoken.filter { !fillerWords.contains($0) }
        guard !filteredSpoken.isEmpty else { return }

        // Look ahead in script for best match
        let searchStart = currentWordIndex
        let searchEnd = min(currentWordIndex + maxJumpDistance * 2, scriptWords.count)

        var bestMatchIndex = currentWordIndex
        var bestMatchScore = 0

        for i in searchStart..<searchEnd {
            var score = 0
            for spoken in filteredSpoken {
                let scriptEnd = min(i + 3, scriptWords.count)
                for j in i..<scriptEnd {
                    if scriptWords[j] == spoken || levenshteinClose(scriptWords[j], spoken) {
                        score += 1
                        break
                    }
                }
            }
            if score > bestMatchScore {
                bestMatchScore = score
                bestMatchIndex = i
            }
        }

        if bestMatchScore >= 2 && bestMatchIndex >= currentWordIndex {
            let newIndex = min(bestMatchIndex + 1, scriptWords.count)
            if newIndex > currentWordIndex {
                currentWordIndex = newIndex
                recordWordAdvance(to: newIndex)
                debugLog(message: "Smart: advanced to word \(currentWordIndex) (score: \(bestMatchScore))")
            }
        }
    }

    private func levenshteinClose(_ a: String, _ b: String) -> Bool {
        // Quick fuzzy check: same first 3 chars and similar length
        guard a.count > 2, b.count > 2 else { return a == b }
        let prefixA = String(a.prefix(3))
        let prefixB = String(b.prefix(3))
        return prefixA == prefixB && abs(a.count - b.count) <= 2
    }

    var progress: Double {
        guard !scriptWords.isEmpty else { return 0 }
        return Double(currentWordIndex) / Double(scriptWords.count)
    }

    // MARK: - Confidence Scroll

    private func recordWordAdvance(to newIndex: Int) {
        let now = Date()
        wordTimestamps.append((index: newIndex, time: now))

        // Keep only recent timestamps
        if wordTimestamps.count > paceWindowSize * 2 {
            wordTimestamps.removeFirst(wordTimestamps.count - paceWindowSize * 2)
        }

        updateAdaptiveSpeed()
    }

    private func updateAdaptiveSpeed() {
        guard isConfidenceScrollEnabled else { return }

        let now = Date()
        // Don't update too frequently
        guard now.timeIntervalSince(lastAdaptiveUpdate) >= 0.25 else { return }
        lastAdaptiveUpdate = now

        // Need at least 2 timestamps to calculate pace
        guard wordTimestamps.count >= 2 else { return }

        let recentStamps = wordTimestamps.suffix(paceWindowSize)
        guard let first = recentStamps.first, let last = recentStamps.last else { return }

        let timeDelta = last.time.timeIntervalSince(first.time)
        guard timeDelta > 0.1 else { return }

        let wordsDelta = Double(last.index - first.index)
        guard wordsDelta > 0 else { return }

        let currentWPM = (wordsDelta / timeDelta) * 60.0
        speakingWPM = currentWPM

        // Convert WPM to scroll speed (pt/s)
        // Average speaking: ~150 WPM maps to ~40 pt/s base speed
        // Scale linearly: speed = (currentWPM / 150) * 40
        let targetSpeed = (currentWPM / 150.0) * 40.0
        let clampedTarget = max(10.0, min(120.0, targetSpeed))

        // Smooth toward target using damping
        adaptiveSpeed += (clampedTarget - adaptiveSpeed) * speedDampingFactor

        debugLog(message: "Pace: \(Int(currentWPM)) wpm → speed: \(Int(adaptiveSpeed)) pt/s")
    }

    func resetPaceTracking(baseSpeed: Double) {
        wordTimestamps = []
        adaptiveSpeed = baseSpeed
        speakingWPM = 0
        lastAdaptiveUpdate = .distantPast
    }

    private func debugLog(message: String) {
        let entry = "[\(Date().formatted(.dateTime.hour().minute().second()))] \(message)"
        debugLog.append(entry)
        if debugLog.count > 50 { debugLog.removeFirst() }
    }
}
