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

        switch action {
        case .makePromptable:
            return addPrompterFormatting(content)
        case .shorten:
            return shortenText(content)
        case .simplify:
            return "[Simplified Version]\n\n" + content
        case .conversational:
            return "So here's the thing — " + content.lowercased().prefix(1).uppercased() + content.dropFirst()
        case .alternateTake:
            return content.components(separatedBy: ". ").reversed().joined(separator: ". ")
        case .splitChunks:
            return splitIntoChunks(content)
        }
    }

    private func addPrompterFormatting(_ text: String) -> String {
        let sentences = text.components(separatedBy: ". ")
        return sentences.enumerated().map { index, sentence in
            if (index + 1) % 3 == 0 {
                return sentence + ".\n\n[PAUSE]\n"
            }
            return sentence + "."
        }.joined(separator: " ")
    }

    private func shortenText(_ text: String) -> String {
        let sentences = text.components(separatedBy: ". ")
        let shortened = sentences.enumerated().compactMap { index, sentence -> String? in
            index % 3 != 2 ? sentence : nil
        }
        return shortened.joined(separator: ". ") + "."
    }

    private func splitIntoChunks(_ text: String) -> String {
        let words = text.split(separator: " ")
        let chunkSize = 15
        return stride(from: 0, to: words.count, by: chunkSize).map { start in
            let end = min(start + chunkSize, words.count)
            return words[start..<end].joined(separator: " ")
        }.joined(separator: "\n\n")
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
