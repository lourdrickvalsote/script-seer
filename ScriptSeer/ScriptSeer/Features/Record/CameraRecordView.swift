import SwiftUI

struct CameraRecordView: View {
    @Environment(\.dismiss) private var dismiss
    let script: Script
    @State private var cameraService = CameraService()
    @State private var promptSession: PromptSession
    @State private var countdownValue = 3
    @State private var showCountdown = false
    @State private var timer: Timer?
    @State private var recordingDuration: TimeInterval = 0
    @State private var showExitConfirmation = false
    @State private var showSettings = false

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

            // Take saved banner
            if cameraService.recordingState == .saved {
                takeSavedOverlay
            }

            // Controls
            VStack {
                // Top bar: timer + take counter
                if cameraService.recordingState == .recording || cameraService.recordingState == .paused {
                    topRecordingBar
                }

                Spacer()
                controlBar
            }

            // Settings panel
            if showSettings {
                settingsPanel
            }
        }
        .onAppear {
            cameraService.configure()
            cameraService.startSession()
        }
        .onDisappear {
            if cameraService.recordingState == .recording || cameraService.recordingState == .paused {
                cameraService.stopRecording()
            }
            cameraService.stopSession()
            stopTimer()
        }
        .navigationBarBackButtonHidden(true)
        .statusBarHidden(true)
        .confirmationDialog("Exit Recording?", isPresented: $showExitConfirmation) {
            Button("Exit", role: .destructive) {
                stopTimer()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Top Recording Bar

    private var topRecordingBar: some View {
        HStack {
            // Recording indicator
            HStack(spacing: SSSpacing.xs) {
                Circle()
                    .fill(cameraService.recordingState == .paused ? SSColors.slate : SSColors.recordingRed)
                    .frame(width: 10, height: 10)

                Text(formattedDuration)
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, SSSpacing.sm)
            .padding(.vertical, SSSpacing.xxs)
            .background(.black.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: SSRadius.sm))

            Spacer()

            // Take counter
            if cameraService.takeCount > 0 {
                Text("Take \(cameraService.takeCount + 1)")
                    .font(SSTypography.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, SSSpacing.sm)
                    .padding(.vertical, SSSpacing.xxs)
                    .background(.black.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: SSRadius.sm))
            }
        }
        .padding(.horizontal, SSSpacing.md)
        .padding(.top, 60)
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
                .padding(.top, cameraService.recordingState == .recording || cameraService.recordingState == .paused ? 100 : 60)
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

    // MARK: - Take Saved

    private var takeSavedOverlay: some View {
        VStack {
            Spacer()

            VStack(spacing: SSSpacing.md) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)

                Text("Take \(cameraService.takeCount) Saved")
                    .font(SSTypography.headline)
                    .foregroundStyle(.white)

                HStack(spacing: SSSpacing.md) {
                    Button(action: {
                        cameraService.resetForNewTake()
                        promptSession.scrollOffset = 0
                    }) {
                        Label("New Take", systemImage: "arrow.counterclockwise")
                            .font(SSTypography.subheadline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, SSSpacing.md)
                            .padding(.vertical, SSSpacing.sm)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: SSRadius.md))
                    }

                    Button(action: { dismiss() }) {
                        Label("Done", systemImage: "checkmark")
                            .font(SSTypography.subheadline)
                            .foregroundStyle(SSColors.lavenderMist)
                            .padding(.horizontal, SSSpacing.md)
                            .padding(.vertical, SSSpacing.sm)
                            .background(SSColors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: SSRadius.md))
                    }
                }
            }
            .padding(SSSpacing.lg)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: SSRadius.xl))
            .padding(.horizontal, SSSpacing.lg)

            Spacer()
        }
    }

    // MARK: - Controls

    private var controlBar: some View {
        HStack(spacing: SSSpacing.xl) {
            // Exit
            Button(action: {
                if cameraService.recordingState == .recording || cameraService.recordingState == .paused {
                    showExitConfirmation = true
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }

            // Pause / Resume (only while recording)
            if cameraService.recordingState == .recording || cameraService.recordingState == .paused {
                Button(action: togglePauseResume) {
                    Image(systemName: cameraService.recordingState == .paused ? "play.fill" : "pause.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }

            // Record / Stop button
            Button(action: toggleRecording) {
                ZStack {
                    Circle()
                        .stroke(.white, lineWidth: 3)
                        .frame(width: 72, height: 72)

                    if cameraService.recordingState == .recording || cameraService.recordingState == .paused {
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

            // Switch camera (not during recording)
            if cameraService.recordingState != .recording && cameraService.recordingState != .paused {
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

            // Settings (not during recording)
            if cameraService.recordingState == .idle {
                Button(action: {
                    withAnimation(SSAnimation.standard) {
                        showSettings.toggle()
                    }
                }) {
                    Image(systemName: "gear")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.bottom, SSSpacing.xl)
    }

    // MARK: - Settings Panel

    private var settingsPanel: some View {
        VStack {
            Spacer()

            VStack(spacing: SSSpacing.md) {
                Text("Recording Settings")
                    .font(SSTypography.headline)
                    .foregroundStyle(.white)

                // Resolution picker
                VStack(alignment: .leading, spacing: SSSpacing.xs) {
                    Text("Resolution")
                        .font(SSTypography.caption)
                        .foregroundStyle(.white.opacity(0.7))

                    Picker("Resolution", selection: Binding(
                        get: { cameraService.resolution },
                        set: { cameraService.setResolution($0) }
                    )) {
                        ForEach(VideoResolution.allCases, id: \.self) { res in
                            Text(res.rawValue).tag(res)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Camera position
                VStack(alignment: .leading, spacing: SSSpacing.xs) {
                    Text("Camera")
                        .font(SSTypography.caption)
                        .foregroundStyle(.white.opacity(0.7))

                    Picker("Camera", selection: Binding(
                        get: { cameraService.currentPosition == .front },
                        set: { _ in cameraService.switchCamera() }
                    )) {
                        Text("Front").tag(true)
                        Text("Back").tag(false)
                    }
                    .pickerStyle(.segmented)
                }

                Button("Done") {
                    withAnimation(SSAnimation.standard) {
                        showSettings = false
                    }
                }
                .foregroundStyle(SSColors.accent)
            }
            .padding(SSSpacing.lg)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: SSRadius.xl))
            .padding(.horizontal, SSSpacing.md)
            .padding(.bottom, 120)
        }
    }

    // MARK: - Actions

    private func toggleRecording() {
        switch cameraService.recordingState {
        case .recording, .paused:
            cameraService.stopRecording()
            promptSession.pause()
            stopScrollTimer()
            SSHaptics.medium()
        case .idle:
            startCountdown()
        case .saved:
            // Start new take
            cameraService.resetForNewTake()
            promptSession.scrollOffset = 0
            startCountdown()
        default:
            break
        }
    }

    private func togglePauseResume() {
        if cameraService.recordingState == .recording {
            cameraService.pauseRecording()
            promptSession.pause()
            SSHaptics.light()
        } else if cameraService.recordingState == .paused {
            cameraService.resumeRecording()
            promptSession.play()
            SSHaptics.light()
        }
    }

    private func startCountdown() {
        countdownValue = 3
        showCountdown = true
        recordingDuration = 0
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
                startDurationTimer()
            }
        }
    }

    private func startScrollTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            guard promptSession.state == .prompting else { return }
            promptSession.scrollOffset += promptSession.scrollSpeed / 60.0
        }
    }

    private func startDurationTimer() {
        // Duration tracked via recordingDuration, updated in scroll timer
    }

    private func stopScrollTimer() {
        stopTimer()
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private var formattedDuration: String {
        // Calculate from actual recording time based on scroll offset and speed
        let duration = promptSession.scrollOffset / max(promptSession.scrollSpeed, 1)
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
