import AVFoundation
import Observation

enum AudioFormat: String, CaseIterable, Identifiable {
    case aac
    case wav
    case alac

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .aac: "AAC (Compressed)"
        case .wav: "WAV (Uncompressed)"
        case .alac: "ALAC (Lossless)"
        }
    }

    var shortName: String {
        switch self {
        case .aac: "AAC"
        case .wav: "WAV"
        case .alac: "ALAC"
        }
    }

    var fileExtension: String {
        switch self {
        case .aac: "m4a"
        case .wav: "wav"
        case .alac: "m4a"
        }
    }

    var formatID: AudioFormatID {
        switch self {
        case .aac: kAudioFormatMPEG4AAC
        case .wav: kAudioFormatLinearPCM
        case .alac: kAudioFormatAppleLossless
        }
    }
}

enum AudioSampleRate: Double, CaseIterable, Identifiable {
    case rate44_1 = 44100
    case rate48 = 48000
    case rate96 = 96000

    var id: Double { rawValue }

    var displayName: String {
        switch self {
        case .rate44_1: "44.1 kHz"
        case .rate48: "48 kHz"
        case .rate96: "96 kHz"
        }
    }

    // Estimated bytes per second for file size estimation (mono)
    func estimatedBytesPerSecond(format: AudioFormat) -> Int {
        let rate = Int(rawValue)
        switch format {
        case .aac: return rate * 2 / 8 // ~64kbps compressed
        case .wav: return rate * 2 // 16-bit mono
        case .alac: return rate * 2 / 2 // ~50% of PCM
        }
    }
}

enum AudioRecordingState: Equatable {
    case idle
    case recording
    case paused
    case stopped
    case failed(String)
}

@Observable
final class AudioRecordingService: NSObject {
    var recordingState: AudioRecordingState = .idle
    var audioLevel: Float = 0
    var currentDuration: TimeInterval = 0

    var selectedFormat: AudioFormat {
        get { AudioFormat(rawValue: UserDefaults.standard.string(forKey: "audioFormat") ?? "aac") ?? .aac }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "audioFormat") }
    }

    var selectedSampleRate: AudioSampleRate {
        get { AudioSampleRate(rawValue: UserDefaults.standard.double(forKey: "audioSampleRate").nonZero ?? 44100) ?? .rate44_1 }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "audioSampleRate") }
    }

    private var recorder: AVAudioRecorder?
    private var levelTimer: Timer?
    private var durationTimer: Timer?
    private var currentFileURL: URL?

    func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try? session.setActive(true)
    }

    func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func startRecording() -> URL? {
        AudioFileManager.ensureDirectory()

        let fileName = "\(UUID().uuidString).\(selectedFormat.fileExtension)"
        let fileURL = AudioFileManager.audioFileURL(for: fileName)
        currentFileURL = fileURL

        var settings: [String: Any] = [
            AVSampleRateKey: selectedSampleRate.rawValue,
            AVNumberOfChannelsKey: 1
        ]

        switch selectedFormat {
        case .aac:
            settings[AVFormatIDKey] = kAudioFormatMPEG4AAC
            settings[AVEncoderAudioQualityKey] = AVAudioQuality.high.rawValue
        case .wav:
            settings[AVFormatIDKey] = kAudioFormatLinearPCM
            settings[AVLinearPCMBitDepthKey] = 16
            settings[AVLinearPCMIsFloatKey] = false
            settings[AVLinearPCMIsBigEndianKey] = false
        case .alac:
            settings[AVFormatIDKey] = kAudioFormatAppleLossless
            settings[AVEncoderBitDepthHintKey] = 16
        }

        do {
            configureSession()
            recorder = try AVAudioRecorder(url: fileURL, settings: settings)
            recorder?.isMeteringEnabled = true
            recorder?.delegate = self
            recorder?.record()

            recordingState = .recording
            currentDuration = 0
            startTimers()
            return fileURL
        } catch {
            recordingState = .failed(error.localizedDescription)
            return nil
        }
    }

    func pauseRecording() {
        recorder?.pause()
        recordingState = .paused
        stopTimers()
    }

    func resumeRecording() {
        recorder?.record()
        recordingState = .recording
        startTimers()
    }

    func stopRecording() -> URL? {
        recorder?.stop()
        stopTimers()
        recordingState = .stopped
        let url = currentFileURL
        currentFileURL = nil
        return url
    }

    func discardRecording() {
        recorder?.stop()
        stopTimers()
        if let url = currentFileURL {
            try? FileManager.default.removeItem(at: url)
        }
        currentFileURL = nil
        recordingState = .idle
        audioLevel = 0
        currentDuration = 0
    }

    func reset() {
        recordingState = .idle
        audioLevel = 0
        currentDuration = 0
    }

    func persistTake(url: URL) -> (fileName: String, fileSize: Int64)? {
        let fileName = url.lastPathComponent
        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = (attrs?[.size] as? Int64) ?? 0
        return (fileName, fileSize)
    }

    // MARK: - Timers

    private func startTimers() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.updateLevel()
        }
        durationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self, let recorder = self.recorder, recorder.isRecording else { return }
            self.currentDuration = recorder.currentTime
        }
    }

    private func stopTimers() {
        levelTimer?.invalidate()
        levelTimer = nil
        durationTimer?.invalidate()
        durationTimer = nil
    }

    private func updateLevel() {
        recorder?.updateMeters()
        let db = recorder?.averagePower(forChannel: 0) ?? -160
        // Normalize from dB (-160...0) to 0...1
        let linear = max(0, min(1, (db + 50) / 50))
        audioLevel = linear
    }
}

extension AudioRecordingService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            recordingState = .failed("Recording failed")
        }
    }
}

private extension Double {
    var nonZero: Double? {
        self == 0 ? nil : self
    }
}
