import SwiftUI

struct CameraRecordView: View {
    @Environment(\.dismiss) private var dismiss
    let script: Script
    @State private var cameraService = CameraService()
    @State private var promptSession: PromptSession
    @State private var countdownValue = 3
    @State private var showCountdown = false
    @State private var timer: Timer?

    init(script: Script) {
        self.script = script
        self._promptSession = State(initialValue: PromptSession(script: script))
    }

    var body: some View {
        ZStack {
            // Camera preview
            CameraPreviewView(session: cameraService.captureSession)
                .ignoresSafeArea()

            // Script overlay near top (near lens area for eye contact)
            scriptOverlay

            // Framing guide
            framingGuide

            // Countdown
            if showCountdown {
                countdownOverlay
            }

            // Controls
            VStack {
                Spacer()
                controlBar
            }
        }
        .onAppear {
            cameraService.configure()
            cameraService.startSession()
        }
        .onDisappear {
            if case .recording = cameraService.recordingState {
                cameraService.stopRecording()
            }
            cameraService.stopSession()
            stopTimer()
        }
        .navigationBarBackButtonHidden(true)
        .statusBarHidden(true)
    }

    // MARK: - Script Overlay

    private var scriptOverlay: some View {
        VStack {
            // Positioned near top for front camera eye contact
            Text(currentText)
                .font(SSTypography.promptText(size: 22))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 2)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .padding(.horizontal, SSSpacing.lg)
                .padding(.vertical, SSSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: SSRadius.md)
                        .fill(.black.opacity(0.5))
                )
                .padding(.top, 60)
                .padding(.horizontal, SSSpacing.md)

            Spacer()
        }
    }

    private var currentText: String {
        let lines = script.content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        let totalOffset = promptSession.scrollOffset
        let lineIndex = min(Int(totalOffset / 60), max(lines.count - 1, 0))
        let endIndex = min(lineIndex + 3, lines.count)
        guard lineIndex < lines.count else { return "" }
        return lines[lineIndex..<endIndex].joined(separator: "\n")
    }

    // MARK: - Framing Guide

    private var framingGuide: some View {
        GeometryReader { geometry in
            let guideWidth = geometry.size.width * 0.7
            let guideHeight = guideWidth * 1.2
            RoundedRectangle(cornerRadius: SSRadius.xl)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                .frame(width: guideWidth, height: guideHeight)
                .position(x: geometry.size.width / 2, y: geometry.size.height * 0.45)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Countdown

    private var countdownOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            Text("\(countdownValue)")
                .font(.system(size: 96, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
        }
    }

    // MARK: - Controls

    private var controlBar: some View {
        HStack(spacing: SSSpacing.xl) {
            // Exit
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }

            // Record button
            Button(action: toggleRecording) {
                ZStack {
                    Circle()
                        .stroke(.white, lineWidth: 3)
                        .frame(width: 72, height: 72)

                    if case .recording = cameraService.recordingState {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(SSColors.recordingRed)
                            .frame(width: 28, height: 28)
                    } else {
                        Circle()
                            .fill(SSColors.recordingRed)
                            .frame(width: 60, height: 60)
                    }
                }
            }

            // Switch camera
            Button(action: {
                cameraService.switchCamera()
                SSHaptics.light()
            }) {
                Image(systemName: "camera.rotate")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
        .padding(.bottom, SSSpacing.xl)
    }

    // MARK: - Actions

    private func toggleRecording() {
        switch cameraService.recordingState {
        case .recording:
            cameraService.stopRecording()
            promptSession.pause()
            stopTimer()
            SSHaptics.medium()
        default:
            startCountdown()
        }
    }

    private func startCountdown() {
        countdownValue = 3
        showCountdown = true
        SSHaptics.medium()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if countdownValue > 1 {
                countdownValue -= 1
                SSHaptics.light()
            } else {
                stopTimer()
                showCountdown = false
                cameraService.startRecording()
                promptSession.play()
                startScrollTimer()
            }
        }
    }

    private func startScrollTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            guard promptSession.state == .prompting else { return }
            promptSession.scrollOffset += promptSession.scrollSpeed / 60.0
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
