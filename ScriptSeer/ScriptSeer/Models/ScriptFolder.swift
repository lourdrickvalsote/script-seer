import Foundation
import SwiftData

@Model
final class ScriptFolder {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date()

    @Relationship(deleteRule: .nullify, inverse: \Script.folder)
    var scripts: [Script] = []

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.scripts = []
    }
}
