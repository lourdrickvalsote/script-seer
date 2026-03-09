import Foundation
import SwiftData

@Model
final class AudioTake {
    var id: UUID = UUID()
    var title: String = ""
    var date: Date = Date()
    var duration: TimeInterval = 0
    var fileName: String = ""
    var audioFormat: String = "aac"
    var sampleRate: Double = 44100
    var fileSize: Int64 = 0
    var script: Script?

    var fileURL: URL? {
        let url = AudioFileManager.audioFileURL(for: fileName)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    var formatDisplayName: String {
        switch audioFormat {
        case "aac": "AAC"
        case "wav": "WAV"
        case "alac": "ALAC"
        default: audioFormat.uppercased()
        }
    }

    init(
        title: String = "",
        duration: TimeInterval = 0,
        fileName: String = "",
        audioFormat: String = "aac",
        sampleRate: Double = 44100,
        fileSize: Int64 = 0,
        script: Script? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.date = Date()
        self.duration = duration
        self.fileName = fileName
        self.audioFormat = audioFormat
        self.sampleRate = sampleRate
        self.fileSize = fileSize
        self.script = script
    }
}
