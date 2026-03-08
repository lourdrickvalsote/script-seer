import Foundation

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

enum AIActionState {
    case idle
    case loading
    case success(String)
    case failed(String)
}

protocol AIProvider {
    func process(action: AIAction, content: String) async throws -> String
}

// Mock provider for development — simulates AI processing
final class MockAIProvider: AIProvider {
    func process(action: AIAction, content: String) async throws -> String {
        // Simulate network delay
        try await Task.sleep(for: .seconds(1.5))

        switch action {
        case .makePromptable:
            return addPrompterFormatting(content)
        case .shorten:
            return shortenText(content)
        case .simplify:
            return simplifyText(content)
        case .conversational:
            return makeConversational(content)
        case .alternateTake:
            return generateAlternate(content)
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
            // Keep roughly 2/3 of sentences
            index % 3 != 2 ? sentence : nil
        }
        return shortened.joined(separator: ". ") + "."
    }

    private func simplifyText(_ text: String) -> String {
        // Simple mock: just return the text with a note
        return "[Simplified Version]\n\n" + text
    }

    private func makeConversational(_ text: String) -> String {
        return "So here's the thing — " + text.lowercased().prefix(1).uppercased() + text.dropFirst()
    }

    private func generateAlternate(_ text: String) -> String {
        let sentences = text.components(separatedBy: ". ")
        return sentences.reversed().joined(separator: ". ")
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

// Service that manages the current provider
@Observable
final class AIActionService {
    var state: AIActionState = .idle

    private var resolvedProvider: AIProvider {
        let providerType = UserDefaults.standard.string(forKey: "aiProviderType") ?? "mock"
        guard providerType == "openai" else { return MockAIProvider() }

        let apiKey = KeychainHelper.load(forKey: "aiAPIKey") ?? ""
        guard !apiKey.isEmpty else { return MockAIProvider() }

        let baseURL = UserDefaults.standard.string(forKey: "aiBaseURL") ?? "https://api.openai.com/v1"
        let model = UserDefaults.standard.string(forKey: "aiModel") ?? "gpt-4o-mini"
        return OpenAIProvider(apiKey: apiKey, baseURL: baseURL, model: model)
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
}
