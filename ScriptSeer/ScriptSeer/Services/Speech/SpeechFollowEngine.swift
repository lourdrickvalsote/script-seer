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

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var scriptWords: [String] = []
    private let confidenceThreshold: Float = 0.4
    private let maxJumpDistance = 5 // max words to skip on weak confidence

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
        audioEngine.stop()
        // Only remove tap if one was installed (recognition was started)
        if recognitionRequest != nil {
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
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

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let result {
                    self.processResult(result)
                }
                if error != nil || (result?.isFinal ?? false) {
                    self.audioEngine.stop()
                    inputNode.removeTap(onBus: 0)
                    self.recognitionRequest = nil
                    self.recognitionTask = nil
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

    private func debugLog(message: String) {
        let entry = "[\(Date().formatted(.dateTime.hour().minute().second()))] \(message)"
        debugLog.append(entry)
        if debugLog.count > 50 { debugLog.removeFirst() }
    }
}
