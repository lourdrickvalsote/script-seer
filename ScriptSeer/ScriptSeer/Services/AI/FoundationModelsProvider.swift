import Foundation
import FoundationModels

/// On-device AI provider using Apple Intelligence.
/// Only instantiated when SystemLanguageModel.default.availability == .available.
final class FoundationModelsProvider: AIProvider {

    func process(action: AIAction, content: String) async throws -> String {
        let session = LanguageModelSession(instructions: systemInstructions(for: action))
        do {
            let response = try await session.respond(to: content)
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { throw AIProviderError.invalidResponse }
            return text
        } catch let error as AIProviderError {
            throw error
        } catch {
            throw AIProviderError.notSupported(reason: error.localizedDescription)
        }
    }

    // MARK: - Prompt Construction

    private func systemInstructions(for action: AIAction) -> String {
        let base = "You are a script editor for a teleprompter app. Return only the transformed text — no preamble, no labels, no explanation."

        switch action {
        case .makePromptable:
            return base + " Reformat the script for teleprompter reading. Add [PAUSE] markers at natural breath points. Break long paragraphs into shorter ones. Preserve the speaker's voice."

        case .shorten:
            return base + " Shorten the script by about 30%. Keep all key points and the speaker's natural voice."

        case .simplify:
            return base + " Simplify using shorter sentences and common words. Keep the meaning. Make it easy to read aloud."

        case .conversational:
            return base + " Rewrite in a natural, conversational spoken tone as if addressing the audience directly. Remove formal language."

        case .alternateTake:
            return base + " Generate an alternate version with the same meaning and key points but different phrasing and structure."

        case .splitChunks:
            return base + " Break the script into teleprompter-sized chunks of 4–6 words per line. End each chunk at a natural pause: after commas, conjunctions, or phrase boundaries. Separate chunks with line breaks."
        }
    }
}
