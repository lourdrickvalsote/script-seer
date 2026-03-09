import Foundation

enum AudioFileManager {
    private static var audioTakesDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AudioTakes", isDirectory: true)
    }

    static func ensureDirectory() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: audioTakesDirectory.path) {
            try? fm.createDirectory(at: audioTakesDirectory, withIntermediateDirectories: true)
        }
    }

    static func audioFileURL(for fileName: String) -> URL {
        audioTakesDirectory.appendingPathComponent(fileName)
    }

    static func deleteFile(fileName: String) {
        let url = audioFileURL(for: fileName)
        try? FileManager.default.removeItem(at: url)
    }

    static func totalStorageSize() -> Int64 {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: audioTakesDirectory.path) else { return 0 }
        return files.reduce(Int64(0)) { total, file in
            let path = audioTakesDirectory.appendingPathComponent(file).path
            let size = (try? fm.attributesOfItem(atPath: path)[.size] as? Int64) ?? 0
            return total + size
        }
    }
}
