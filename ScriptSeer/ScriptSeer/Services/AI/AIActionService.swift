import Foundation
import FoundationModels

// MARK: - AIAction

enum AIAction: String, CaseIterable, Identifiable {
    case makePromptable = "Make Promptable"
    case shorten = "Shorten"
    case simplify = "Simplify"
    case conversational = "Rewrite Conversationally"
    case alternateTake = "Generate Alternate Take"
    case splitChunks = "Split into Chunks"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .makePromptable: "wand.and.stars"
        case .shorten: "scissors"
        case .simplify: "text.badge.minus"
        case .conversational: "bubble.left.and.bubble.right"
        case .alternateTake: "arrow.triangle.2.circlepath"
        case .splitChunks: "rectangle.split.3x1"
        }
    }

    var description: String {
        switch self {
        case .makePromptable: "Optimize for teleprompter reading with natural pauses and flow."
        case .shorten: "Reduce length while preserving key points."
        case .simplify: "Use simpler words and shorter sentences."
        case .conversational: "Rewrite in a natural, spoken tone."
        case .alternateTake: "Generate a fresh version with the same meaning."
        case .splitChunks: "Break into readable teleprompter-sized chunks."
        }
    }

    var variantSourceType: VariantSourceType {
        switch self {
        case .makePromptable: .aiCleanup
        case .shorten: .shortened
        case .simplify: .simplified
        case .conversational: .conversational
        case .alternateTake: .alternateTake
        case .splitChunks: .chunked
        }
    }
}

// MARK: - AIActionState

enum AIActionState {
    case idle
    case loading
    case success(String)
    case failed(String)
}

// MARK: - AIProviderError

enum AIProviderError: LocalizedError {
    case invalidResponse
    case notSupported(reason: String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from AI service."
        case .notSupported(let reason):
            return reason
        }
    }
}

// MARK: - AIProvider

protocol AIProvider {
    func process(action: AIAction, content: String) async throws -> String
}

// MARK: - AppleIntelligenceStatus

enum AppleIntelligenceStatus: Equatable {
    case available
    case notEnabled
    case deviceNotEligible
    case modelNotReady
    case simulator

    var isAvailable: Bool { self == .available }

    /// Whether AI actions can be executed (available on device, or mock in Simulator)
    var isFunctional: Bool {
        switch self {
        case .available, .simulator: true
        default: false
        }
    }

    var label: String {
        switch self {
        case .available: "Available"
        case .notEnabled: "Not Enabled"
        case .deviceNotEligible: "Not Supported"
        case .modelNotReady: "Downloading..."
        case .simulator: "Simulator (Mock)"
        }
    }

    var detail: String? {
        switch self {
        case .available: nil
        case .notEnabled: "Enable Apple Intelligence in Settings > Apple Intelligence & Siri."
        case .deviceNotEligible: "Apple Intelligence requires iPhone 15 Pro or later."
        case .modelNotReady: "Apple Intelligence model is still downloading."
        case .simulator: "AI actions use a mock provider in Simulator."
        }
    }

    var systemImage: String {
        switch self {
        case .available: "checkmark.circle.fill"
        case .notEnabled: "exclamationmark.circle"
        case .deviceNotEligible: "xmark.circle"
        case .modelNotReady: "arrow.down.circle"
        case .simulator: "hammer.circle"
        }
    }

    static func current() -> AppleIntelligenceStatus {
        #if targetEnvironment(simulator)
        return .simulator
        #else
        switch SystemLanguageModel.default.availability {
        case .available:
            return .available
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible: return .deviceNotEligible
            case .appleIntelligenceNotEnabled: return .notEnabled
            case .modelNotReady: return .modelNotReady
            @unknown default: return .deviceNotEligible
            }
        }
        #endif
    }
}

// MARK: - Mock Provider (Simulator / Previews only)

final class MockAIProvider: AIProvider {
    func process(action: AIAction, content: String) async throws -> String {
        try await Task.sleep(for: .seconds(1.5))

        let sentences = splitSentences(content)

        switch action {
        case .makePromptable:
            return makePromptable(sentences)
        case .shorten:
            return shorten(sentences)
        case .simplify:
            return simplify(sentences)
        case .conversational:
            return conversational(sentences, original: content)
        case .alternateTake:
            return alternateTake(sentences)
        case .splitChunks:
            return splitChunks(content)
        }
    }

    private func splitSentences(_ text: String) -> [String] {
        text.components(separatedBy: ". ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func makePromptable(_ sentences: [String]) -> String {
        var result = ""
        for (i, sentence) in sentences.enumerated() {
            let clean = sentence.hasSuffix(".") ? sentence : sentence + "."
            result += clean + "\n\n"
            if (i + 1) % 2 == 0 && i < sentences.count - 1 {
                result += "[PAUSE — breathe]\n\n"
            }
        }
        return "— TELEPROMPTER FORMATTED —\n\n" + result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func shorten(_ sentences: [String]) -> String {
        let shortened = sentences.compactMap { sentence -> String? in
            let words = sentence.split(separator: " ")
            guard words.count > 4 else { return sentence }
            let kept = words.prefix(max(words.count * 2 / 3, 3))
            return kept.joined(separator: " ") + "."
        }
        return "— SHORTENED VERSION —\n\n" + shortened.joined(separator: " ")
    }

    private func simplify(_ sentences: [String]) -> String {
        let simplified = sentences.map { sentence -> String in
            var s = sentence
            let replacements: [(String, String)] = [
                ("utilize", "use"), ("implement", "do"), ("approximately", "about"),
                ("demonstrate", "show"), ("facilitate", "help"), ("regarding", "about"),
                ("subsequently", "then"), ("nevertheless", "but"), ("furthermore", "also"),
                ("however", "but"), ("therefore", "so"), ("additional", "more"),
            ]
            for (from, to) in replacements {
                s = s.replacingOccurrences(of: from, with: to, options: .caseInsensitive)
            }
            return s
        }
        return "— SIMPLIFIED VERSION —\n\n" + simplified.joined(separator: ". ")
    }

    private func conversational(_ sentences: [String], original: String) -> String {
        let fillers = ["So, ", "You know, ", "Here's the thing — ", "Basically, ", "Look, ", "Okay so "]
        let converted = sentences.enumerated().map { i, sentence in
            if i == 0 {
                return fillers[0] + sentence.prefix(1).lowercased() + sentence.dropFirst()
            } else if i % 3 == 0 {
                return fillers[min(i / 3, fillers.count - 1)] + sentence.prefix(1).lowercased() + sentence.dropFirst()
            }
            return sentence
        }
        return "— CONVERSATIONAL REWRITE —\n\n" + converted.joined(separator: ". ")
    }

    private func alternateTake(_ sentences: [String]) -> String {
        let synonymStarts = ["In other words, ", "Put differently, ", "To put it another way, ", "What this means is "]
        let rewritten = sentences.enumerated().map { i, sentence in
            let prefix = synonymStarts[i % synonymStarts.count]
            let lower = sentence.prefix(1).lowercased() + sentence.dropFirst()
            return prefix + lower
        }
        return "— ALTERNATE TAKE —\n\n" + rewritten.joined(separator: ".\n\n") + "."
    }

    private func splitChunks(_ text: String) -> String {
        let words = text.split(separator: " ")
        let chunkSize = 8
        let chunks = stride(from: 0, to: words.count, by: chunkSize).enumerated().map { index, start in
            let end = min(start + chunkSize, words.count)
            let chunk = words[start..<end].joined(separator: " ")
            return "[\(index + 1)] \(chunk)"
        }
        return "— CHUNKED FOR TELEPROMPTER —\n\n" + chunks.joined(separator: "\n\n")
    }
}

// MARK: - Service

@MainActor
@Observable
final class AIActionService {
    var state: AIActionState = .idle
    var appleIntelligenceStatus: AppleIntelligenceStatus {
        AppleIntelligenceStatus.current()
    }

    func execute(action: AIAction, content: String) async -> String? {
        state = .loading
        do {
            let result = try await resolvedProvider.process(action: action, content: content)
            state = .success(result)
            return result
        } catch {
            state = .failed("AI processing failed: \(error.localizedDescription)")
            return nil
        }
    }

    func reset() {
        state = .idle
    }

    private var resolvedProvider: AIProvider {
        #if targetEnvironment(simulator)
        return MockAIProvider()
        #else
        guard AppleIntelligenceStatus.current().isAvailable else { return MockAIProvider() }
        return FoundationModelsProvider()
        #endif
    }
}
