import Foundation
import AVKit
import UIKit
import SwiftUI
import Combine

@MainActor
@Observable
final class PiPTeleprompterService: NSObject {

    // MARK: - Public State

    var isPiPActive: Bool = false
    var isPiPPossible: Bool = false
    var wantsRestore: Bool = false

    // MARK: - Private AVFoundation

    private var pipController: AVPictureInPictureController?
    let displayLayer = AVSampleBufferDisplayLayer()
    private var renderLink: CADisplayLink?
    private var backgroundScrollTimer: Timer?
    private var silentPlayer: AVAudioPlayer?
    private var renderer = PiPTextRenderer()

    // MARK: - References

    private weak var session: PromptSession?
    private weak var speechEngine: SpeechFollowEngine?

    // MARK: - Frame Timing

    private var lastRenderedOffset: CGFloat = -1
    private var lastRenderedWordIndex: Int = -1
    private var frameSize: CGSize = CGSize(width: 480, height: 270) // 16:9 PiP default
    private let _playbackState = PlaybackStateBox()

    // MARK: - Setup

    func prepare(session: PromptSession, speechEngine: SpeechFollowEngine) {
        self.session = session
        self.speechEngine = speechEngine

        displayLayer.videoGravity = .resizeAspect

        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            isPiPPossible = false
            return
        }

        let contentSource = AVPictureInPictureController.ContentSource(
            sampleBufferDisplayLayer: displayLayer,
            playbackDelegate: self
        )
        let controller = AVPictureInPictureController(contentSource: contentSource)
        controller.delegate = self
        controller.canStartPictureInPictureAutomaticallyFromInline = false
        pipController = controller
        isPiPPossible = true

        // Render an initial frame so the display layer has content
        renderFrame()
    }

    // MARK: - Start / Stop

    func startPiP() {
        guard let pipController, isPiPPossible else { return }

        configureAudioSession()
        startSilentAudio()

        // Render a frame first to ensure display layer has content
        renderFrame()

        pipController.startPictureInPicture()
    }

    func stopPiP() {
        pipController?.stopPictureInPicture()
        cleanUp()
    }

    private func cleanUp() {
        stopRenderLoop()
        stopBackgroundScroll()
        stopSilentAudio()
        isPiPActive = false
    }

    // MARK: - Render Loop

    private func startRenderLoop() {
        stopRenderLoop()
        let link = CADisplayLink(target: self, selector: #selector(displayLinkFired))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 15, maximum: 30, preferred: 30)
        link.add(to: .main, forMode: .common)
        renderLink = link
    }

    private func stopRenderLoop() {
        renderLink?.invalidate()
        renderLink = nil
    }

    @objc private func displayLinkFired() {
        guard let session else { return }

        // Update paused state for nonisolated delegate callback
        _playbackState.isPaused = session.state != .prompting

        // Skip rendering if nothing changed (paused optimization)
        let currentOffset = session.scrollOffset
        let currentWordIndex = speechEngine?.currentWordIndex ?? -1
        let offsetDelta = abs(currentOffset - lastRenderedOffset)

        if offsetDelta < 1 && currentWordIndex == lastRenderedWordIndex {
            return
        }

        lastRenderedOffset = currentOffset
        lastRenderedWordIndex = currentWordIndex

        renderFrame()
    }

    private func renderFrame() {
        guard let session else { return }

        let wordIndex: Int? = if let engine = speechEngine,
            engine.state == .following || engine.state == .listening {
            engine.currentWordIndex
        } else {
            nil
        }

        let textColor = UIColor(session.theme.textColor)
        let bgColor = UIColor(session.theme.backgroundColor)

        guard let sampleBuffer = renderer.renderFrame(
            content: session.content,
            scrollOffset: session.scrollOffset,
            frameSize: frameSize,
            textSize: session.textSize,
            lineSpacing: session.lineSpacing,
            horizontalMargin: max(12, session.horizontalMargin),
            textColor: textColor,
            backgroundColor: bgColor,
            isMirrored: session.isMirrored,
            currentWordIndex: wordIndex
        ) else { return }

        displayLayer.sampleBufferRenderer.enqueue(sampleBuffer)
    }

    // MARK: - Background Scroll

    func startBackgroundScroll() {
        stopBackgroundScroll()
        guard session != nil else { return }

        backgroundScrollTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let session = self.session else { return }
                guard session.state == .prompting else { return }

                let speed: Double
                if let engine = self.speechEngine, engine.isConfidenceScrollEnabled {
                    speed = engine.adaptiveSpeed
                } else {
                    speed = session.effectiveScrollSpeed
                }
                session.scrollOffset += speed / 60.0

                // Auto-complete
                if session.measuredContentHeight > 0, session.scrollOffset >= session.measuredContentHeight {
                    session.script.lastPromptedAt = Date()
                    session.complete()
                    self.stopPiP()
                }
            }
        }
    }

    private func stopBackgroundScroll() {
        backgroundScrollTimer?.invalidate()
        backgroundScrollTimer = nil
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        let isSpeechFollow = speechEngine?.state == .following || speechEngine?.state == .listening

        do {
            if isSpeechFollow {
                try audioSession.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers, .defaultToSpeaker])
            } else {
                try audioSession.setCategory(.playback, mode: .default, options: .mixWithOthers)
            }
            try audioSession.setActive(true)
        } catch {
            // Audio session configuration failed — PiP may not stay alive
        }
    }

    private func startSilentAudio() {
        stopSilentAudio()
        // Create a silent audio buffer to keep the audio session active
        let sampleRate: Double = 44100
        let duration: Double = 1.0
        let numSamples = Int(sampleRate * duration)
        let bytesPerSample = 2
        let dataSize = numSamples * bytesPerSample
        var data = Data(count: dataSize + 44) // WAV header + silence

        // WAV header
        let headerBytes: [UInt8] = [
            0x52, 0x49, 0x46, 0x46, // "RIFF"
        ]
        data.replaceSubrange(0..<4, with: headerBytes)
        let fileSize = UInt32(dataSize + 36)
        data.replaceSubrange(4..<8, with: withUnsafeBytes(of: fileSize.littleEndian) { Data($0) })
        let fmtBytes: [UInt8] = [
            0x57, 0x41, 0x56, 0x45, // "WAVE"
            0x66, 0x6D, 0x74, 0x20, // "fmt "
        ]
        data.replaceSubrange(8..<16, with: fmtBytes)
        let fmtChunkSize = UInt32(16)
        data.replaceSubrange(16..<20, with: withUnsafeBytes(of: fmtChunkSize.littleEndian) { Data($0) })
        let audioFormat = UInt16(1) // PCM
        data.replaceSubrange(20..<22, with: withUnsafeBytes(of: audioFormat.littleEndian) { Data($0) })
        let numChannels = UInt16(1)
        data.replaceSubrange(22..<24, with: withUnsafeBytes(of: numChannels.littleEndian) { Data($0) })
        let sampleRateU32 = UInt32(sampleRate)
        data.replaceSubrange(24..<28, with: withUnsafeBytes(of: sampleRateU32.littleEndian) { Data($0) })
        let byteRate = UInt32(sampleRate * Double(bytesPerSample))
        data.replaceSubrange(28..<32, with: withUnsafeBytes(of: byteRate.littleEndian) { Data($0) })
        let blockAlign = UInt16(bytesPerSample)
        data.replaceSubrange(32..<34, with: withUnsafeBytes(of: blockAlign.littleEndian) { Data($0) })
        let bitsPerSample = UInt16(16)
        data.replaceSubrange(34..<36, with: withUnsafeBytes(of: bitsPerSample.littleEndian) { Data($0) })
        let dataHeader: [UInt8] = [0x64, 0x61, 0x74, 0x61] // "data"
        data.replaceSubrange(36..<40, with: dataHeader)
        let dataSizeU32 = UInt32(dataSize)
        data.replaceSubrange(40..<44, with: withUnsafeBytes(of: dataSizeU32.littleEndian) { Data($0) })
        // Rest is zeros (silence)

        do {
            silentPlayer = try AVAudioPlayer(data: data)
            silentPlayer?.numberOfLoops = -1
            silentPlayer?.volume = 0.01
            silentPlayer?.play()
        } catch {
            // Silent audio failed — PiP may not persist in background
        }
    }

    private func stopSilentAudio() {
        silentPlayer?.stop()
        silentPlayer = nil
    }

    // MARK: - Speech Follow Background

    func configureSpeechForBackground() {
        guard let speechEngine else { return }
        // Force on-device recognition for background reliability
        speechEngine.stop()
        speechEngine.start(useExistingAudioSession: true)
    }
}

// MARK: - AVPictureInPictureControllerDelegate

extension PiPTeleprompterService: AVPictureInPictureControllerDelegate {

    nonisolated func pictureInPictureControllerWillStartPictureInPicture(_ controller: AVPictureInPictureController) {
        Task { @MainActor in
            isPiPActive = true
            startRenderLoop()
            startBackgroundScroll()
        }
    }

    nonisolated func pictureInPictureControllerDidStartPictureInPicture(_ controller: AVPictureInPictureController) {
    }

    nonisolated func pictureInPictureControllerWillStopPictureInPicture(_ controller: AVPictureInPictureController) {
    }

    nonisolated func pictureInPictureControllerDidStopPictureInPicture(_ controller: AVPictureInPictureController) {
        Task { @MainActor in
            cleanUp()
        }
    }

    nonisolated func pictureInPictureController(
        _ controller: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {
        Task { @MainActor in
            cleanUp()
        }
    }

    nonisolated func pictureInPictureController(
        _ controller: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        Task { @MainActor in
            wantsRestore = true
            completionHandler(true)
        }
    }
}

// MARK: - AVPictureInPictureSampleBufferPlaybackDelegate

extension PiPTeleprompterService: AVPictureInPictureSampleBufferPlaybackDelegate {

    nonisolated func pictureInPictureController(
        _ controller: AVPictureInPictureController,
        setPlaying playing: Bool
    ) {
        Task { @MainActor in
            guard let session else { return }
            if playing {
                session.play()
            } else {
                session.pause()
            }
        }
    }

    nonisolated func pictureInPictureControllerTimeRangeForPlayback(
        _ controller: AVPictureInPictureController
    ) -> CMTimeRange {
        // Report a long duration so PiP doesn't auto-dismiss
        CMTimeRange(start: .zero, duration: CMTime(seconds: 3600, preferredTimescale: 600))
    }

    nonisolated func pictureInPictureControllerIsPlaybackPaused(
        _ controller: AVPictureInPictureController
    ) -> Bool {
        _playbackState.isPaused
    }

    nonisolated func pictureInPictureController(
        _ controller: AVPictureInPictureController,
        didTransitionToRenderSize newRenderSize: CMVideoDimensions
    ) {
        Task { @MainActor in
            frameSize = CGSize(width: Int(newRenderSize.width), height: Int(newRenderSize.height))
            lastRenderedOffset = -1 // force re-render
        }
    }

    nonisolated func pictureInPictureController(
        _ controller: AVPictureInPictureController,
        skipByInterval skipInterval: CMTime,
        completion completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            guard let session else {
                completionHandler()
                return
            }
            if skipInterval.seconds > 0 {
                session.jumpForward()
            } else {
                session.jumpBack()
            }
            completionHandler()
        }
    }
}

// Thread-safe box for sharing playback state with nonisolated delegate callbacks
private final class PlaybackStateBox: @unchecked Sendable {
    private let lock = NSLock()
    private var _paused: Bool = true
    var isPaused: Bool {
        get { lock.withLock { _paused } }
        set { lock.withLock { _paused = newValue } }
    }
}
