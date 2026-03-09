import Foundation
import SwiftData

@Model
final class ScriptRevision {
    var id: UUID = UUID()
    var content: String = ""
    var title: String = ""
    var createdAt: Date = Date()
    var wordCount: Int = 0
    var changeDescription: String = ""

    var script: Script?

    init(script: Script, changeDescription: String = "Manual save") {
        self.id = UUID()
        self.content = script.content
        self.title = script.title
        self.createdAt = Date()
        self.wordCount = script.wordCount
        self.changeDescription = changeDescription
        self.script = script
    }
}
