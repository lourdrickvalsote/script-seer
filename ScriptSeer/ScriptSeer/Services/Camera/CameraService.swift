import AVFoundation
import Photos
import UIKit

enum CameraPosition {
    case front, back

    var avPosition: AVCaptureDevice.Position {
        switch self {
        case .front: .front
        case .back: .back
        }
    }
}

enum VideoResolution: String, CaseIterable {
    case hd720 = "720p"
    case hd1080 = "1080p"
    case uhd4K = "4K"

    var sessionPreset: AVCaptureSession.Preset {
        switch self {
        case .hd720: .hd1280x720
        case .hd1080: .hd1920x1080
        case .uhd4K: .hd4K3840x2160
        }
    }
}

enum RecordingState: Equatable {
    case idle
    case preparing
    case countdown
    case recording
    case paused
    case finishing
    case saved
    case failed(String)
}

enum RecordingMode: String, CaseIterable {
    case video = "Video"
    case audioOnly = "Audio Only"
}

@Observable
final class CameraService: NSObject {
    let captureSession = AVCaptureSession()
    var recordingState: RecordingState = .idle
    var currentPosition: CameraPosition = .front
    var isSessionRunning = false
    var resolution: VideoResolution = .hd1080
    var takeCount: Int = 0
    var lastSavedURL: URL?
    var recordingMode: RecordingMode = .video
    private(set) var isSwitchingCamera = false
    var audioLevel: Float = 0.0

    private var videoOutput: AVCaptureMovieFileOutput?
    private var currentDevice: AVCaptureDevice?
    private var outputURL: URL?
    private var onRecordingFinished: ((URL?) -> Void)?
    private var audioRecorder: AVAudioRecorder?
    private var audioOutputURL: URL?
    private var audioLevelTimer: Timer?

    func configure() {
        guard captureSession.inputs.isEmpty else { return }
        captureSession.beginConfiguration()
        captureSession.sessionPreset = resolution.sessionPreset

        // Video input
        guard let device = bestDevice(for: currentPosition),
              let input = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(input) else {
            captureSession.commitConfiguration()
            return
        }
        captureSession.addInput(input)
        currentDevice = device

        // Audio input
        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           captureSession.canAddInput(audioInput) {
            captureSession.addInput(audioInput)
        }

        // Movie output
        let output = AVCaptureMovieFileOutput()
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
            videoOutput = output
        }

        captureSession.commitConfiguration()
    }

    func startSession() {
        guard !isSessionRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = true
            }
        }
    }

    func stopSession() {
        guard isSessionRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.stopRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = false
            }
        }
    }

    func teardownSession() {
        captureSession.stopRunning()
        captureSession.beginConfiguration()
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }
        for output in captureSession.outputs {
            captureSession.removeOutput(output)
        }
        captureSession.commitConfiguration()
        videoOutput = nil
        currentDevice = nil
        isSessionRunning = false
    }

    func switchCamera() {
        // Block during transient states only
        switch recordingState {
        case .preparing, .countdown, .finishing:
            return
        default:
            break
        }
        guard !isSwitchingCamera else { return }
        isSwitchingCamera = true

        let newPosition: CameraPosition = currentPosition == .front ? .back : .front

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            self.captureSession.beginConfiguration()

            // Save existing inputs for rollback
            let existingInputs = self.captureSession.inputs

            // Remove existing inputs
            for input in existingInputs {
                self.captureSession.removeInput(input)
            }

            guard let device = self.bestDevice(for: newPosition),
                  let input = try? AVCaptureDeviceInput(device: device),
                  self.captureSession.canAddInput(input) else {
                // Restore previous inputs on failure
                for input in existingInputs {
                    if self.captureSession.canAddInput(input) {
                        self.captureSession.addInput(input)
                    }
                }
                self.captureSession.commitConfiguration()
                DispatchQueue.main.async { self.isSwitchingCamera = false }
                return
            }
            self.captureSession.addInput(input)

            // Re-add audio
            if let audioDevice = AVCaptureDevice.default(for: .audio),
               let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
               self.captureSession.canAddInput(audioInput) {
                self.captureSession.addInput(audioInput)
            }

            self.captureSession.commitConfiguration()

            DispatchQueue.main.async {
                self.currentDevice = device
                self.currentPosition = newPosition
                self.isSwitchingCamera = false
            }
        }
    }

    func startRecording() {
        switch recordingMode {
        case .video:
            startVideoRecording()
        case .audioOnly:
            startAudioRecording()
        }
    }

    func pauseRecording() {
        switch recordingMode {
        case .video:
            guard let output = videoOutput, output.isRecording else { return }
            output.pauseRecording()
            recordingState = .paused
        case .audioOnly:
            audioRecorder?.pause()
            stopAudioLevelTimer()
            recordingState = .paused
        }
    }

    func resumeRecording() {
        switch recordingMode {
        case .video:
            guard let output = videoOutput, output.isRecordingPaused else { return }
            output.resumeRecording()
            recordingState = .recording
        case .audioOnly:
            audioRecorder?.record()
            startAudioLevelTimer()
            recordingState = .recording
        }
    }

    func stopRecording() {
        switch recordingMode {
        case .video:
            guard let output = videoOutput, output.isRecording else { return }
            recordingState = .finishing
            output.stopRecording()
        case .audioOnly:
            stopAudioRecording()
        }
    }

    // MARK: - Video Recording

    private func startVideoRecording() {
        guard let output = videoOutput, !output.isRecording else { return }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        outputURL = url
        recordingState = .recording
        output.startRecording(to: url, recordingDelegate: self)
    }

    // MARK: - Audio-Only Recording

    func configureAudioOnly() {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func startAudioRecording() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        audioOutputURL = url

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        guard let recorder = try? AVAudioRecorder(url: url, settings: settings) else {
            recordingState = .failed("Could not start audio recording.")
            return
        }
        recorder.isMeteringEnabled = true
        recorder.record()
        audioRecorder = recorder
        recordingState = .recording
        startAudioLevelTimer()
    }

    private func stopAudioRecording() {
        audioRecorder?.stop()
        stopAudioLevelTimer()
        audioRecorder = nil

        if let url = audioOutputURL {
            takeCount += 1
            lastSavedURL = url
            recordingState = .saved
        } else {
            recordingState = .failed("Audio recording failed.")
        }
    }

    private func startAudioLevelTimer() {
        audioLevelTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            guard let self, let recorder = self.audioRecorder, recorder.isRecording else { return }
            recorder.updateMeters()
            let db = recorder.averagePower(forChannel: 0)
            // Normalize dB (-160...0) to 0...1
            let normalized = max(0, min(1, (db + 50) / 50))
            self.audioLevel = normalized
        }
    }

    private func stopAudioLevelTimer() {
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil
        audioLevel = 0
    }

    func setResolution(_ newResolution: VideoResolution) {
        switch recordingState {
        case .idle, .saved, .failed: break
        default: return
        }
        resolution = newResolution
        captureSession.beginConfiguration()
        if captureSession.canSetSessionPreset(newResolution.sessionPreset) {
            captureSession.sessionPreset = newResolution.sessionPreset
        }
        captureSession.commitConfiguration()
    }

    func updateVideoOrientation(_ orientation: UIDeviceOrientation) {
        guard let output = videoOutput,
              let connection = output.connection(with: .video) else { return }
        let angle: CGFloat
        switch orientation {
        case .landscapeLeft: angle = 0    // DI points left → natural landscape
        case .landscapeRight: angle = 180
        case .portrait: angle = 90
        default: return
        }
        if connection.isVideoRotationAngleSupported(angle) {
            connection.videoRotationAngle = angle
        }
    }

    func resetForNewTake() {
        recordingState = .idle
        lastSavedURL = nil
    }

    func saveToPhotos(url: URL, completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            } completionHandler: { success, _ in
                DispatchQueue.main.async { completion(success) }
            }
        }
    }

    func lockExposureAndFocus() {
        guard let device = currentDevice else { return }
        try? device.lockForConfiguration()
        if device.isExposureModeSupported(.locked) {
            device.exposureMode = .locked
        }
        if device.isFocusModeSupported(.locked) {
            device.focusMode = .locked
        }
        device.unlockForConfiguration()
    }

    func unlockExposureAndFocus() {
        guard let device = currentDevice else { return }
        try? device.lockForConfiguration()
        if device.isExposureModeSupported(.continuousAutoExposure) {
            device.exposureMode = .continuousAutoExposure
        }
        if device.isFocusModeSupported(.continuousAutoFocus) {
            device.focusMode = .continuousAutoFocus
        }
        device.unlockForConfiguration()
    }

    private func bestDevice(for position: CameraPosition) -> AVCaptureDevice? {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position.avPosition)
    }
}

extension CameraService: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        DispatchQueue.main.async { [weak self] in
            if let error = error {
                let fileExists = FileManager.default.fileExists(atPath: outputFileURL.path)
                if !fileExists {
                    self?.recordingState = .failed("Recording failed. Please try again.")
                    return
                }
                // File exists despite error (e.g. AVError.recordingSuccessfullyFinished) — fall through
            }

            self?.takeCount += 1
            self?.lastSavedURL = outputFileURL
            self?.saveToPhotos(url: outputFileURL) { [weak self] success in
                if success {
                    self?.recordingState = .saved
                } else {
                    self?.recordingState = .failed("Take recorded but could not be saved to Photos. Check permissions in Settings.")
                }
            }
        }
    }
}
