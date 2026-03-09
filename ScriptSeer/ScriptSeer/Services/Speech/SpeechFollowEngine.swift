import Foundation
import NaturalLanguage
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

@MainActor
@Observable
final class SpeechFollowEngine {
    var state: SpeechFollowState = .idle
    var mode: SpeechFollowMode = .smart
    var currentWordIndex: Int = 0
    var confidence: Float = 1.0
    var isAvailable: Bool = false
    var debugLog: [String] = []
    var showDebugOverlay: Bool = false
    private var restartCount: Int = 0
    private let maxRestarts = 3

    // Confidence Scroll — adaptive speed from speaking pace
    var adaptiveSpeed: Double = 40.0 // current smoothed speed in pt/s
    var speakingWPM: Double = 0.0 // current estimated words per minute
    var isConfidenceScrollEnabled: Bool = false

    private(set) var currentLocale: Locale = Locale.current
    private var speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale.current)
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var scriptWords: [String] = []
    private let maxSearchAhead = 15 // max words to search ahead of current position
    private var tapInstalled = false
    private var cachedFillerWords: Set<String> = []
    private var cachedStopWords: Set<String> = []
    private var useExistingAudioSession = false

    // Pace tracking
    private var wordTimestamps: [(index: Int, time: Date)] = []
    private var lastAdaptiveUpdate: Date = .distantPast
    private let paceWindowSize = 10 // words to average over
    private let speedDampingFactor = 0.15 // how quickly speed adjusts (0-1, lower = smoother)

    func setLocale(_ locale: Locale) {
        currentLocale = locale
        speechRecognizer = SFSpeechRecognizer(locale: locale)
        debugLog(message: "Locale set to \(locale.identifier)")
    }

    func applyStoredLanguageSetting() {
        let stored = UserDefaults.standard.string(forKey: "speechLanguage") ?? "auto"
        if stored == "auto" {
            setLocale(Locale.current)
        } else {
            setLocale(Locale(identifier: stored))
        }
    }

    func prepare(scriptContent: String) {
        scriptWords = scriptContent
            .components(separatedBy: .whitespacesAndNewlines)
            .map { $0.lowercased().trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }
        currentWordIndex = 0
        confidence = 1.0
        cachedFillerWords = Self.loadFillerWords(for: currentLocale)
        cachedStopWords = Self.detectStopWords(in: scriptContent, locale: currentLocale)
        debugLog(message: "Prepared with \(scriptWords.count) words, \(cachedStopWords.count) stop words, locale: \(currentLocale.identifier)")
    }

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                let authorized = status == .authorized
                DispatchQueue.main.async {
                    self.isAvailable = authorized
                    continuation.resume(returning: authorized)
                }
            }
        }
    }

    func start(useExistingAudioSession: Bool = false) {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            state = .manualAssist
            debugLog(message: "Speech recognizer not available")
            return
        }

        self.useExistingAudioSession = useExistingAudioSession
        restartCount = 0

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
        // Only deactivate audio session if we own it
        if !useExistingAudioSession {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
        state = .stopped
        debugLog(message: "Stopped")
    }

    private func startRecognition() throws {
        recognitionTask?.cancel()
        recognitionTask = nil

        // Only configure audio session if we're not sharing one with camera
        if !useExistingAudioSession {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = speechRecognizer?.supportsOnDeviceRecognition ?? false
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        // Remove any existing tap to prevent crash on rapid toggle
        if tapInstalled {
            inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        tapInstalled = true

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            // Clean up tap and audio session before rethrowing
            inputNode.removeTap(onBus: 0)
            tapInstalled = false
            if !useExistingAudioSession {
                try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            }
            throw error
        }

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
                        self.debugLog(message: "Recognition ended, attempting restart (\(self.restartCount)/\(self.maxRestarts))")
                        if self.restartCount < self.maxRestarts {
                            self.restartCount += 1
                            self.state = .lowConfidence
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                guard self.state == .lowConfidence else { return }
                                do {
                                    try self.startRecognition()
                                    self.state = .listening
                                    self.debugLog(message: "Recognition restarted successfully")
                                } catch {
                                    self.state = .lowConfidence
                                    self.debugLog(message: "Restart failed: \(error.localizedDescription)")
                                }
                            }
                        } else {
                            self.state = .lowConfidence
                            self.debugLog(message: "Max restarts reached, falling back")
                        }
                    }
                }
            }
        }
    }

    private func processResult(_ result: SFSpeechRecognitionResult) {
        // Use the full transcription every time — Apple revises partial results,
        // so incremental tracking is unreliable. Instead, always use the tail.
        let spokenWords = result.bestTranscription.formattedString
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }

        guard !spokenWords.isEmpty else { return }

        // Update confidence for UI
        if let lastSegment = result.bestTranscription.segments.last {
            confidence = Float(lastSegment.confidence)
        }

        state = .following

        // Always use the recent tail of the transcription for matching.
        // This handles Apple's revisions naturally — we just re-match.
        let tailSize = min(spokenWords.count, 12)
        let recentSpoken = Array(spokenWords.suffix(tailSize))

        switch mode {
        case .strict:
            advanceStrict(spokenWords: recentSpoken)
        case .smart:
            advanceSmart(spokenWords: recentSpoken)
        }
    }

    private func advanceStrict(spokenWords: [String]) {
        // Match each spoken word sequentially against the script from current position
        var scriptPos = currentWordIndex
        let searchEnd = min(currentWordIndex + maxSearchAhead, scriptWords.count)

        for spoken in spokenWords {
            guard !spoken.isEmpty, scriptPos < searchEnd else { break }
            // Look for this word within a small window ahead
            let localEnd = min(scriptPos + 4, searchEnd)
            for j in scriptPos..<localEnd {
                if scriptWords[j] == spoken || levenshteinClose(scriptWords[j], spoken) {
                    scriptPos = j + 1
                    break
                }
            }
        }

        if scriptPos > currentWordIndex {
            currentWordIndex = scriptPos
            recordWordAdvance(to: currentWordIndex)
            debugLog(message: "Strict: advanced to word \(currentWordIndex)")
        }
    }

    private func advanceSmart(spokenWords: [String]) {
        // Filter out filler words but KEEP stop words for sequential matching
        // (stop words help confirm position when they appear in sequence)
        let fillerWords = cachedFillerWords
        let filtered = spokenWords.filter { !$0.isEmpty && !fillerWords.contains($0) }
        guard filtered.count >= 2 else { return }

        let searchEnd = min(currentWordIndex + maxSearchAhead, scriptWords.count)
        guard currentWordIndex < searchEnd else { return }

        // Strategy: find the best sequential alignment of spoken words against the script.
        // Only match on content words (skip stop words for scoring, but use them for alignment).
        // Require at least 2 content word matches to advance — prevents false jumps.

        var bestPos = currentWordIndex
        var bestContentMatches = 0

        // Try each starting position in the search window
        for startPos in currentWordIndex..<searchEnd {
            var scriptIdx = startPos
            var contentMatches = 0
            var totalMatches = 0

            for spoken in filtered {
                guard scriptIdx < searchEnd else { break }
                // Search within a tight window of 3 words for each spoken word
                let windowEnd = min(scriptIdx + 3, searchEnd)
                var matched = false
                for j in scriptIdx..<windowEnd {
                    if scriptWords[j] == spoken || levenshteinClose(scriptWords[j], spoken) {
                        scriptIdx = j + 1
                        totalMatches += 1
                        if !cachedStopWords.contains(spoken) {
                            contentMatches += 1
                        }
                        matched = true
                        break
                    }
                }
                // If a content word didn't match, penalize — this isn't our position
                if !matched && !cachedStopWords.contains(spoken) {
                    break
                }
            }

            // Prefer positions with more content word matches
            if contentMatches > bestContentMatches {
                bestContentMatches = contentMatches
                bestPos = scriptIdx
            }
        }

        // Require at least 2 content word matches to prevent false jumps
        if bestContentMatches >= 2 && bestPos > currentWordIndex {
            currentWordIndex = min(bestPos, scriptWords.count)
            recordWordAdvance(to: currentWordIndex)
            debugLog(message: "Smart: advanced to word \(currentWordIndex) (\(bestContentMatches) content matches)")
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

    func configureForBackground() {
        // Increase max restarts for long PiP sessions
        // On-device recognition is already preferred (line 154)
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

    // MARK: - NLTagger-based Stop Word Detection

    /// Uses NaturalLanguage framework to identify function words (determiners, prepositions,
    /// pronouns, conjunctions, particles) in the script text. Works for 60+ languages automatically.
    private static func detectStopWords(in text: String, locale: Locale) -> Set<String> {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        let language = NLLanguage(rawValue: locale.language.languageCode?.identifier ?? "en")
        tagger.setLanguage(language, range: text.startIndex..<text.endIndex)

        let functionClasses: Set<NLTag> = [
            .determiner, .preposition, .pronoun, .conjunction, .particle
        ]

        var stopWords = Set<String>()
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, tokenRange in
            if let tag, functionClasses.contains(tag) {
                let word = String(text[tokenRange]).lowercased().trimmingCharacters(in: .punctuationCharacters)
                if !word.isEmpty {
                    stopWords.insert(word)
                }
            }
            return true
        }

        return stopWords
    }

    // MARK: - Filler Words (loaded from bundled JSON)

    /// Loads filler words from filler_words.json, falling back to English defaults.
    private static func loadFillerWords(for locale: Locale) -> Set<String> {
        let lang = locale.language.languageCode?.identifier ?? "en"

        guard let url = Bundle.main.url(forResource: "filler_words", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dict = try? JSONDecoder().decode([String: [String]].self, from: data) else {
            return fillerWordsFallback(for: lang)
        }

        if let words = dict[lang] {
            return Set(words)
        } else if let words = dict["en"] {
            return Set(words)
        }
        return fillerWordsFallback(for: lang)
    }

    /// Hardcoded fallback in case the JSON file is missing.
    private static func fillerWordsFallback(for lang: String) -> Set<String> {
        switch lang {
        case "es": return ["eh", "este", "bueno", "pues", "o sea", "como"]
        case "fr": return ["euh", "ben", "donc", "genre", "enfin", "voilà"]
        case "de": return ["äh", "ähm", "also", "halt", "sozusagen", "quasi"]
        case "ja": return ["えーと", "あの", "その", "まあ", "なんか"]
        case "pt": return ["é", "tipo", "assim", "né", "bom"]
        default: return ["um", "uh", "like", "you know", "so", "well", "basically", "actually"]
        }
    }
}
