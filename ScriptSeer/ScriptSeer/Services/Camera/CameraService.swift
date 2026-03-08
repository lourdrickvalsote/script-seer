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

@Observable
final class CameraService: NSObject {
    let captureSession = AVCaptureSession()
    var recordingState: RecordingState = .idle
    var currentPosition: CameraPosition = .front
    var isSessionRunning = false
    var resolution: VideoResolution = .hd1080
    var takeCount: Int = 0
    var lastSavedURL: URL?

    private var videoOutput: AVCaptureMovieFileOutput?
    private var currentDevice: AVCaptureDevice?
    private var outputURL: URL?
    private var onRecordingFinished: ((URL?) -> Void)?

    func configure() {
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

    func switchCamera() {
        // Don't switch camera during active recording
        if case .recording = recordingState { return }

        currentPosition = currentPosition == .front ? .back : .front

        captureSession.beginConfiguration()
        // Remove existing inputs
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }

        guard let device = bestDevice(for: currentPosition),
              let input = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(input) else {
            captureSession.commitConfiguration()
            return
        }
        captureSession.addInput(input)
        currentDevice = device

        // Re-add audio
        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           captureSession.canAddInput(audioInput) {
            captureSession.addInput(audioInput)
        }

        captureSession.commitConfiguration()
    }

    func startRecording() {
        guard let output = videoOutput, !output.isRecording else { return }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        outputURL = url
        recordingState = .recording
        output.startRecording(to: url, recordingDelegate: self)
    }

    func pauseRecording() {
        guard let output = videoOutput, output.isRecording else { return }
        output.pauseRecording()
        recordingState = .paused
    }

    func resumeRecording() {
        guard let output = videoOutput, output.isRecordingPaused else { return }
        output.resumeRecording()
        recordingState = .recording
    }

    func stopRecording() {
        guard let output = videoOutput, output.isRecording else { return }
        recordingState = .finishing
        output.stopRecording()
    }

    func setResolution(_ newResolution: VideoResolution) {
        guard recordingState == .idle || recordingState == .saved else { return }
        resolution = newResolution
        captureSession.beginConfiguration()
        if captureSession.canSetSessionPreset(newResolution.sessionPreset) {
            captureSession.sessionPreset = newResolution.sessionPreset
        }
        captureSession.commitConfiguration()
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
            if error != nil {
                self?.recordingState = .failed("Recording failed. Please try again.")
            } else {
                self?.takeCount += 1
                self?.lastSavedURL = outputFileURL
                self?.recordingState = .saved
                self?.saveToPhotos(url: outputFileURL) { _ in }
            }
        }
    }
}
