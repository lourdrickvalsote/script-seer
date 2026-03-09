import Foundation
import SwiftData

@Model
final class PracticeRecord {
    var id: UUID = UUID()
    var date: Date = Date()
    var duration: TimeInterval = 0
    var wordsPerMinute: Double = 0
    var stumbleCount: Int = 0
    var usedSpeechFollow: Bool = false
    var script: Script?

    init(
        date: Date = Date(),
        duration: TimeInterval = 0,
        wordsPerMinute: Double = 0,
        stumbleCount: Int = 0,
        usedSpeechFollow: Bool = false,
        script: Script? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.duration = duration
        self.wordsPerMinute = wordsPerMinute
        self.stumbleCount = stumbleCount
        self.usedSpeechFollow = usedSpeechFollow
        self.script = script
    }
}
