import Foundation
import SwiftData

@Model
final class Script {
    var id: UUID = UUID()
    var title: String = "Untitled Script"
    var content: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var estimatedDuration: TimeInterval = 0
    var tags: [String] = []
    var isMirrorDefault: Bool = false
    var deletedAt: Date?
    var lastPromptedAt: Date?
    var lastPracticedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \ScriptVariant.parentScript)
    var variants: [ScriptVariant] = []

    var folder: ScriptFolder?

    @Relationship(deleteRule: .cascade, inverse: \ScriptRevision.script)
    var revisions: [ScriptRevision] = []

    @Relationship(deleteRule: .cascade, inverse: \PracticeRecord.script)
    var practiceRecords: [PracticeRecord] = []

    @Relationship(deleteRule: .cascade, inverse: \AudioTake.script)
    var audioTakes: [AudioTake] = []

    init(
        title: String = "Untitled Script",
        content: String = "",
        tags: [String] = [],
        isMirrorDefault: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
        self.estimatedDuration = Script.estimateDuration(for: content)
        self.tags = tags
        self.isMirrorDefault = isMirrorDefault
        self.deletedAt = nil
        self.lastPromptedAt = nil
        self.lastPracticedAt = nil
        self.variants = []
        self.revisions = []
        self.practiceRecords = []
        self.audioTakes = []
    }

    func softDelete() {
        deletedAt = Date()
        folder = nil
    }

    func restore() {
        deletedAt = nil
    }

    var isInTrash: Bool {
        deletedAt != nil
    }

    var daysUntilPermanentDeletion: Int? {
        guard let deletedAt else { return nil }
        let daysSinceDeletion = Calendar.current.dateComponents([.day], from: deletedAt, to: Date()).day ?? 0
        return max(0, 30 - daysSinceDeletion)
    }

    func duplicate() -> Script {
        let copy = Script(
            title: "\(title) (Copy)",
            content: content,
            tags: tags,
            isMirrorDefault: isMirrorDefault
        )
        return copy
    }

    func updateContent(_ newContent: String) {
        content = newContent
        updatedAt = Date()
        estimatedDuration = Script.estimateDuration(for: newContent)
    }

    func updateTitle(_ newTitle: String) {
        title = newTitle
        updatedAt = Date()
    }

    static func estimateDuration(for text: String) -> TimeInterval {
        let words = text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
        // Average speaking pace: ~150 words per minute
        return Double(words) / 150.0 * 60.0
    }

    var formattedDuration: String {
        let minutes = Int(estimatedDuration) / 60
        let seconds = Int(estimatedDuration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }

    var wordCount: Int {
        content.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }

    static var sampleScripts: [Script] {
        [
            {
                let s = Script(
                    title: "Product Launch Keynote",
                    content: """
                    Good morning everyone, and welcome to our annual product launch event.

                    Today, I'm thrilled to share something we've been working on for the past two years. Something that will fundamentally change how you interact with technology every single day.

                    Before I reveal what we've built, let me take you back to where this journey started. Two years ago, our team sat in a room and asked a simple question: What if technology could truly understand what you need, before you even ask?

                    That question led us down a path of innovation that has resulted in three breakthrough products that I'm going to show you today.

                    Let's start with the first one. I think you're going to love this.
                    """,
                    tags: ["keynote", "presentation"]
                )
                return s
            }(),
            {
                let s = Script(
                    title: "YouTube Channel Intro",
                    content: """
                    Hey everyone, welcome back to the channel! If you're new here, I'm so glad you found us.

                    In today's video, we're diving deep into something I've been wanting to talk about for weeks. Trust me, you don't want to miss this one.

                    Before we get started, if you haven't already, hit that subscribe button and turn on notifications so you never miss an upload. We post new content every Tuesday and Friday.

                    Alright, let's jump right in.
                    """,
                    tags: ["youtube", "intro"]
                )
                return s
            }(),
            {
                let s = Script(
                    title: "Wedding Toast",
                    content: """
                    For those of you who don't know me, I'm the best man, and I've had the privilege of knowing the groom for over fifteen years.

                    When he first told me about meeting someone special, I could hear it in his voice. There was something different this time. And when I finally met her, I understood why.

                    Together, they are the kind of couple that makes you believe in love stories. The kind that reminds you what really matters in life.

                    So please, raise your glasses. To love, to laughter, and to a lifetime of happiness together. Cheers!
                    """
                )
                return s
            }()
        ]
    }
}
