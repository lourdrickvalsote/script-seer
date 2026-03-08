import Foundation
import SwiftData

enum VariantSourceType: String, Codable, CaseIterable {
    case original
    case aiCleanup = "ai_cleanup"
    case shortened
    case simplified
    case conversational
    case alternateTake = "alternate_take"
    case chunked
    case custom

    var displayName: String {
        switch self {
        case .original: "Original"
        case .aiCleanup: "AI Cleanup"
        case .shortened: "Shortened"
        case .simplified: "Simplified"
        case .conversational: "Conversational"
        case .alternateTake: "Alternate Take"
        case .chunked: "Chunked"
        case .custom: "Custom"
        }
    }
}

@Model
final class ScriptVariant {
    var id: UUID
    var title: String
    var content: String
    var sourceType: VariantSourceType
    var createdAt: Date
    var updatedAt: Date

    var parentScript: Script?

    init(
        title: String,
        content: String,
        sourceType: VariantSourceType = .original,
        parentScript: Script? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.sourceType = sourceType
        self.createdAt = Date()
        self.updatedAt = Date()
        self.parentScript = parentScript
    }
}
