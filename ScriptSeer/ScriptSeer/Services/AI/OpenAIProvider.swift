import Foundation

/// AI provider that works with OpenAI-compatible APIs (OpenAI, local models, etc.)
final class OpenAIProvider: AIProvider {
    private let apiKey: String
    private let baseURL: String
    private let model: String

    init(
        apiKey: String,
        baseURL: String = "https://api.openai.com/v1",
        model: String = "gpt-4o-mini"
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.model = model
    }

    func process(action: AIAction, content: String) async throws -> String {
        let systemPrompt = buildSystemPrompt(for: action)
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw AIProviderError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": content]
            ],
            "temperature": 0.7,
            "max_tokens": 4096
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIProviderError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIProviderError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let responseContent = message["content"] as? String else {
            throw AIProviderError.invalidResponse
        }

        return responseContent.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func buildSystemPrompt(for action: AIAction) -> String {
        let base = "You are a professional script editor for a teleprompter app. "

        switch action {
        case .makePromptable:
            return base + "Reformat the following script for teleprompter reading. Add natural pauses using [PAUSE] markers. Break long paragraphs into shorter ones. Ensure the text flows naturally when read aloud. Return only the reformatted text."
        case .shorten:
            return base + "Shorten this script while preserving all key points and the speaker's voice. Aim to reduce length by about 30%. Return only the shortened text."
        case .simplify:
            return base + "Simplify this script using shorter sentences and simpler vocabulary. Keep the meaning intact but make it easier to read aloud naturally. Return only the simplified text."
        case .conversational:
            return base + "Rewrite this script in a natural, conversational tone as if the speaker is talking directly to the audience. Remove formal language and add natural speech patterns. Return only the rewritten text."
        case .alternateTake:
            return base + "Generate an alternate version of this script with the same key points and meaning, but with different phrasing and structure. Return only the alternate version."
        case .splitChunks:
            return base + "Break this script into natural teleprompter-sized chunks of 4-6 words per line. Each chunk should end at a natural pause point (after commas, conjunctions, or phrase boundaries). Separate chunks with line breaks. Return only the chunked text."
        }
    }
}

enum AIProviderError: LocalizedError {
    case invalidResponse
    case apiError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from AI service."
        case .apiError(let statusCode, let message):
            return "API error (\(statusCode)): \(message)"
        }
    }
}
